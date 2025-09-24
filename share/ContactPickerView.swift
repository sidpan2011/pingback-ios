import SwiftUI
import Contacts
import ContactsUI

struct ContactPickerView: View {
    @Binding var selectedPerson: Person?
    let requiredAppType: AppKind
    @Environment(\.dismiss) private var dismiss
    
    @State private var contacts: [CNContact] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showingContactPicker = false
    @State private var showingPhoneNumberPicker = false
    @State private var selectedContact: CNContact?
    @State private var availablePhoneNumbers: [String] = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contactsList
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .task {
                await loadContacts()
            }
            .sheet(isPresented: $showingContactPicker) {
                SystemContactPickerView { contact in
                    handleContactSelection(contact)
                }
            }
            .sheet(isPresented: $showingPhoneNumberPicker) {
                PhoneNumberPickerView(
                    contact: selectedContact!,
                    phoneNumbers: availablePhoneNumbers,
                    requiredAppType: requiredAppType
                ) { phoneNumber in
                    createPersonFromContact(selectedContact!, phoneNumber: phoneNumber)
                    showingPhoneNumberPicker = false
                    dismiss()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var contactsList: some View {
        List {
            // Add contact button
            Button(action: {
                showingContactPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Add from Contacts")
                        .foregroundColor(.blue)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
            
            // Existing contacts
            ForEach(filteredContacts, id: \.identifier) { contact in
                ContactRowView(
                    contact: contact,
                    requiredAppType: requiredAppType
                ) {
                    handleContactSelection(contact)
                }
            }
        }
    }
    
    private func loadContacts() async {
        do {
            let store = CNContactStore()
            
            // Check current authorization status
            let authStatus = CNContactStore.authorizationStatus(for: .contacts)
            
            let hasAccess: Bool
            switch authStatus {
            case .authorized:
                hasAccess = true
            case .notDetermined:
                // Request access if not determined
                hasAccess = try await store.requestAccess(for: .contacts)
            case .denied, .restricted:
                hasAccess = false
            @unknown default:
                hasAccess = false
            }
            
            guard hasAccess else {
                await MainActor.run {
                    errorMessage = "Contact access denied. Please enable in Settings > Privacy & Security > Contacts."
                    showError = true
                    isLoading = false
                }
                return
            }
            
            // Fetch contacts
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var fetchedContacts: [CNContact] = []
            
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts that have phone numbers (required for WhatsApp/SMS)
                if !contact.phoneNumbers.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            
            await MainActor.run {
                self.contacts = fetchedContacts.sorted { contact1, contact2 in
                    let name1 = "\(contact1.givenName) \(contact1.familyName)"
                    let name2 = "\(contact2.givenName) \(contact2.familyName)"
                    return name1 < name2
                }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load contacts: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func handleContactSelection(_ contact: CNContact) {
        let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
        
        if phoneNumbers.isEmpty {
            errorMessage = "This contact has no phone numbers"
            showError = true
            return
        }
        
        if phoneNumbers.count == 1 {
            // Only one phone number, use it directly
            createPersonFromContact(contact, phoneNumber: phoneNumbers[0])
            dismiss()
        } else {
            // Multiple phone numbers, let user choose
            selectedContact = contact
            availablePhoneNumbers = phoneNumbers
            showingPhoneNumberPicker = true
        }
    }
    
    private func createPersonFromContact(_ contact: CNContact, phoneNumber: String) {
        let person = Person(
            firstName: contact.givenName,
            lastName: contact.familyName,
            phoneNumbers: [formatPhoneNumber(phoneNumber)]
        )
        selectedPerson = person
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Use SharedPhoneNumberService for proper region-aware E.164 formatting
        return SharedPhoneNumberService.normalizeToE164(phoneNumber, contact: selectedContact) ?? phoneNumber
    }
}

struct ContactRowView: View {
    let contact: CNContact
    let requiredAppType: AppKind
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Contact initials
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(contact.givenName) \(contact.familyName)")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let firstPhone = contact.phoneNumbers.first {
                        Text(firstPhone.value.stringValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if contact.phoneNumbers.count > 1 {
                        Text("\(contact.phoneNumbers.count) phone numbers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var initials: String {
        let first = String(contact.givenName.prefix(1))
        let last = String(contact.familyName.prefix(1))
        return (first + last).uppercased()
    }
}

struct PhoneNumberPickerView: View {
    let contact: CNContact
    let phoneNumbers: [String]
    let requiredAppType: AppKind
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(phoneNumbers, id: \.self) { phoneNumber in
                    Button(action: {
                        onSelect(phoneNumber)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phoneNumber)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(phoneNumberType(for: phoneNumber))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func phoneNumberType(for phoneNumber: String) -> String {
        // In a real app, you'd get the label from CNPhoneNumber
        if phoneNumber.contains("mobile") || phoneNumber.contains("cell") {
            return "Mobile"
        } else if phoneNumber.contains("home") {
            return "Home"
        } else if phoneNumber.contains("work") {
            return "Work"
        } else {
            return "Phone"
        }
    }
}

struct SystemContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: SystemContactPickerView
        
        init(_ parent: SystemContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onContactSelected(contact)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

#if DEBUG
struct ContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ContactPickerView(
            selectedPerson: .constant(nil),
            requiredAppType: .whatsapp
        )
    }
}
#endif
