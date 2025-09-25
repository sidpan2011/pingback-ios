import SwiftUI
import Contacts
import ContactsUI

struct ShareExtensionView: View {
    @StateObject private var viewModel = ShareExtensionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Message Section
                messageSection
                
                // Contact Section
                contactSection
                
                // App and Tag Section
                appTagSection
                
                // Date and Time Section
                dateTimeSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add to Pingback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .foregroundStyle(.tint)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await viewModel.saveWithCurrentSelections()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(!viewModel.canSave ? .secondary : .primary)
                    .fontWeight(.medium)
                }
            }
        }
        .task {
            await viewModel.initialize(with: ExtensionContext.shared)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                viewModel.cancel()
            }
        } message: {
            Text("Added follow-up to Pingback")
        }
        .sheet(isPresented: $viewModel.showContactPicker) {
            ContactPickerHost(
                selectedContact: $viewModel.contactName, 
                isPresented: $viewModel.showContactPicker,
                onPersonSelected: { person in
                    viewModel.selectedPerson = person
                }
            )
        }
        // DATE PICKER SHEET
        .sheet(isPresented: $viewModel.showDateSheet) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.primary)
                    .labelsHidden()
                    .padding()
                    Spacer()
                }
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { viewModel.showDateSheet = false }
                            .foregroundStyle(.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { 
                            print("🔵 ShareExtension: Date picker done, selectedDate: \(viewModel.selectedDate)")
                            viewModel.showDateSheet = false 
                        }
                            .foregroundStyle(.primary).fontWeight(.medium)
                    }
                }
            }
        }

        // TIME PICKER SHEET
        .sheet(isPresented: $viewModel.showTimeSheet) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: $viewModel.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .accentColor(.primary)
                    .labelsHidden()
                    .padding(.top, 12)
                    Spacer()
                }
                .navigationTitle("Select Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { viewModel.showTimeSheet = false }
                            .foregroundStyle(.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { 
                            print("🔵 ShareExtension: Time picker done, selectedTime: \(viewModel.selectedTime)")
                            viewModel.showTimeSheet = false 
                        }
                            .foregroundStyle(.primary).fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        Section {
            TextField("Message", text: $viewModel.editedMessage)
                .font(.body)
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        Section {
            HStack {
                Text("Contact")
                    .foregroundStyle(.secondary)
                Spacer()
                Button(viewModel.contactName.isEmpty ? "Choose…" : viewModel.contactName) {
                    viewModel.showContactPicker = true
                }
                .foregroundStyle(.tint)
                .padding(.horizontal, viewModel.contactName.isEmpty ? 0 : 12)
                .padding(.vertical, viewModel.contactName.isEmpty ? 0 : 6)
                .background(viewModel.contactName.isEmpty ? Color.clear : Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - App Section
    private var appTagSection: some View {
        Section {
            HStack {
                Text("App")
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    ForEach(viewModel.getAvailableApps()) { app in
                        Button {
                            viewModel.selectedApp = app
                        } label: {
                            HStack {
                                Text(app.label)
                                if !viewModel.isProUser && !isFreeApp(app) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(!viewModel.isProUser && !isFreeApp(app))
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedApp.label)
                        if !viewModel.isProUser && !isFreeApp(viewModel.selectedApp) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }
    
    private func isFreeApp(_ app: AppKind) -> Bool {
        switch app {
        case .whatsapp, .sms, .email, .safari:
            return true
        case .telegram, .slack, .gmail, .outlook, .chrome, .instagram:
            return false
        }
    }
    
    // MARK: - Date and Time Section
    private var dateTimeSection: some View {
        Section {
            // DATE ROW
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(.primary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date")
                        .foregroundStyle(.secondary)
                    if viewModel.isDateEnabled {
                        Text(viewModel.selectedDate.formatted(date: .complete, time: .omitted))
                            .font(.footnote)
                            .foregroundStyle(.tint)
                            .onTapGesture { viewModel.showDateSheet = true }
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.isDateEnabled },
                    set: { newValue in
                        print("🔵 ShareExtension: Date toggle changed to \(newValue)")
                        viewModel.isDateEnabled = newValue
                        if newValue {
                            print("🔵 ShareExtension: Date enabled, selectedDate: \(viewModel.selectedDate)")
                        }
                    }
                ))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.isDateEnabled { viewModel.showDateSheet = true }
            }

            // TIME ROW
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "clock")
                    .foregroundStyle(.primary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time")
                        .foregroundStyle(.secondary)
                    if viewModel.isTimeEnabled {
                        Text(viewModel.selectedTime.formatted(date: .omitted, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.tint)
                            .onTapGesture { viewModel.showTimeSheet = true }
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.isTimeEnabled },
                    set: { newValue in
                        print("🔵 ShareExtension: Time toggle changed to \(newValue)")
                        viewModel.isTimeEnabled = newValue
                        if newValue {
                            print("🔵 ShareExtension: Time enabled, selectedTime: \(viewModel.selectedTime)")
                        }
                    }
                ))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.isTimeEnabled { viewModel.showTimeSheet = true }
            }
        } footer: {
            Text(viewModel.defaultTimeFooterText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Contact Chip Component
struct ContactChip: View {
    let person: Person
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(person.firstName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let phoneNumber = person.primaryPhoneNumber {
                    Text(phoneNumber.suffix(4))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Share Quick Time Chip Component
struct ShareQuickTimeChip: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isDefault: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    if isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .green)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date/Time Picker Sheet
struct DateTimePickerSheet: View {
    @Binding var selectedDate: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date & Time",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Pick Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                    }
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Contact Picker Host
struct ContactPickerHost: UIViewControllerRepresentable {
    @Binding var selectedContact: String
    @Binding var isPresented: Bool
    let onPersonSelected: (Person?) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        // No need to update - the picker is directly presented
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerHost

        init(_ parent: ContactPickerHost) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let full = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let org = contact.organizationName
            let name = full.isEmpty ? (org.isEmpty ? "Unknown" : org) : full
            
            // DETAILED LOGGING FOR DEBUGGING
            print("📱 ===== CONTACT PICKER DEBUG =====")
            print("📱 Contact selected: \(name)")
            print("📱 Given Name: '\(contact.givenName)'")
            print("📱 Family Name: '\(contact.familyName)'")
            print("📱 Organization: '\(contact.organizationName)'")
            print("📱 Phone Numbers Count: \(contact.phoneNumbers.count)")
            
            for (index, phoneNumber) in contact.phoneNumbers.enumerated() {
                let label = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phoneNumber.label ?? "")
                let number = phoneNumber.value.stringValue
                print("📱 Phone \(index + 1): \(label) = '\(number)'")
            }
            
            print("📱 Email Count: \(contact.emailAddresses.count)")
            for (index, email) in contact.emailAddresses.enumerated() {
                let label = CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? "")
                let address = email.value as String
                print("📱 Email \(index + 1): \(label) = '\(address)'")
            }
            
            print("📱 Before update - parent.selectedContact: '\(parent.selectedContact)'")
            print("📱 ===== END CONTACT DEBUG =====")
            
            // Create Person object with phone numbers
            let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
            let person: Person?
            
            if !phoneNumbers.isEmpty {
                // Use first phone number and normalize it
                let phoneNumber = phoneNumbers[0]
                let e164PhoneNumber = SharedPhoneNumberService.normalizeToE164(phoneNumber, contact: contact) ?? phoneNumber
                
                person = Person(
                    firstName: contact.givenName.isEmpty ? name : contact.givenName,
                    lastName: contact.familyName,
                    phoneNumbers: [e164PhoneNumber]
                )
                print("📱 Created Person with phone: \(e164PhoneNumber)")
            } else {
                person = nil
                print("📱 No phone numbers found - Person is nil")
            }
            
            // Update immediately on main thread
            DispatchQueue.main.async {
                print("🔵 Updating selectedContact to: '\(name)'")
                self.parent.selectedContact = name
                print("🔵 After update - parent.selectedContact: '\(self.parent.selectedContact)'")
                
                // Set the Person object with phone numbers
                self.parent.onPersonSelected(person)
                print("🔵 Called onPersonSelected with person: \(person?.displayName ?? "nil")")
                
                self.parent.isPresented = false
                print("🔵 ContactPicker dismissed")
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    ShareExtensionView()
}
