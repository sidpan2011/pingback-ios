import SwiftUI
import Contacts
import ContactsUI

struct ShareContactPickerView: View {
    @Binding var selectedPerson: Person?
    let onQuickSave: (Person) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var contacts: [CNContact] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showingSystemContactPicker = false
    @State private var showingPhoneNumberPicker = false
    @State private var selectedContact: CNContact?
    @State private var availablePhoneNumbers: [String] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return Array(contacts.prefix(20)) // Show only first 20 when no search
        } else {
            return contacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
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
                    .foregroundStyle(.primary)
                }
            }
            .task {
                await loadContacts()
                isSearchFocused = true
            }
            .sheet(isPresented: $showingSystemContactPicker) {
                ShareSystemContactPickerView { contact in
                    handleContactSelection(contact)
                }
            }
            .sheet(isPresented: $showingPhoneNumberPicker) {
                SharePhoneNumberPickerView(
                    contact: selectedContact!,
                    phoneNumbers: availablePhoneNumbers
                ) { phoneNumber in
                    let person = createPersonFromContact(selectedContact!, phoneNumber: phoneNumber)
                    onQuickSave(person)
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
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search contacts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFocused)
                .onSubmit {
                    // If there's exactly one result, select it
                    if filteredContacts.count == 1 {
                        let contact = filteredContacts[0]
                        handleContactSelection(contact)
                    }
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    isSearchFocused = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var contactsList: some View {
        List {
            // Add from system contacts button
            Button(action: {
                showingSystemContactPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    Text("Add from Contacts")
                        .foregroundStyle(.blue)
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Search results
            ForEach(filteredContacts, id: \.identifier) { contact in
                ShareContactRowView(contact: contact) {
                    handleContactSelection(contact)
                }
            }
            
            if !searchText.isEmpty && filteredContacts.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("No contacts found for '\(searchText)'")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadContacts() async {
        do {
            let store = CNContactStore()
            
            // Request access
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else {
                await MainActor.run {
                    errorMessage = "Contact access denied"
                    showError = true
                    isLoading = false
                }
                return
            }
            
            // Fetch contacts
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            var fetchedContacts: [CNContact] = []
            
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with phone numbers
                if !contact.phoneNumbers.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            
            // Sort by first name
            fetchedContacts.sort { contact1, contact2 in
                let name1 = "\(contact1.givenName) \(contact1.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                let name2 = "\(contact2.givenName) \(contact2.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
            
            await MainActor.run {
                contacts = fetchedContacts
                isLoading = false
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
        
        if phoneNumbers.count == 1 {
            // Single phone number - quick save immediately
            let person = createPersonFromContact(contact, phoneNumber: phoneNumbers[0])
            onQuickSave(person)
            dismiss()
        } else if phoneNumbers.count > 1 {
            // Multiple phone numbers - show picker
            selectedContact = contact
            availablePhoneNumbers = phoneNumbers
            showingPhoneNumberPicker = true
        } else {
            errorMessage = "Contact has no phone numbers"
            showError = true
        }
    }
    
    private func createPersonFromContact(_ contact: CNContact, phoneNumber: String) -> Person {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = contact.givenName.isEmpty ? fullName : contact.givenName
        let lastName = contact.familyName
        
        return Person(
            firstName: firstName.isEmpty ? "Unknown" : firstName,
            lastName: lastName,
            phoneNumbers: [phoneNumber]
        )
    }
}

// MARK: - Share Contact Row View
struct ShareContactRowView: View {
    let contact: CNContact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Contact image or initials
                contactImage
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let primaryPhone = contact.phoneNumbers.first?.value.stringValue {
                        Text(primaryPhone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Multiple phone indicator
                if contact.phoneNumbers.count > 1 {
                    Text("\(contact.phoneNumbers.count)")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contactImage: some View {
        Group {
            if let imageData = contact.thumbnailImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
    }
    
    private var displayName: String {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? "Unknown" : fullName
    }
    
    private var initials: String {
        let firstName = contact.givenName.prefix(1).uppercased()
        let lastName = contact.familyName.prefix(1).uppercased()
        return "\(firstName)\(lastName)"
    }
}

// MARK: - Share Phone Number Picker
struct SharePhoneNumberPickerView: View {
    let contact: CNContact
    let phoneNumbers: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(phoneNumbers, id: \.self) { phoneNumber in
                    Button(action: {
                        onSelect(phoneNumber)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phoneNumber)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Text(phoneNumberLabel(phoneNumber))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }
    
    private func phoneNumberLabel(_ phoneNumber: String) -> String {
        // Find the corresponding label from the contact
        for phoneNumberEntry in contact.phoneNumbers {
            if phoneNumberEntry.value.stringValue == phoneNumber {
                return CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phoneNumberEntry.label ?? "")
            }
        }
        return "Phone"
    }
}

// MARK: - Share System Contact Picker
struct ShareSystemContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void
        
        init(onContactSelected: @escaping (CNContact) -> Void) {
            self.onContactSelected = onContactSelected
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onContactSelected(contact)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ShareContactPickerView(
        selectedPerson: .constant(nil),
        onQuickSave: { _ in }
    )
}
