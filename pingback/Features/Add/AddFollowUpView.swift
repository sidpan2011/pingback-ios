import SwiftUI
import Contacts
import ContactsUI

struct AddFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: NewFollowUpStore
    
    let existingItem: FollowUp?
    
    @State private var notes: String = ""
    @State private var contactName: String = ""
    @State private var isForSelf: Bool = false
    @State private var selectedType: FollowType = .doIt
    @State private var selectedApp: AppKind = .whatsapp
    @State private var url: String = ""
    @State private var showContactPicker: Bool = false
    @State private var suggestedVerb: String? = nil
    @State private var suggestedDue: Date? = nil
    
    // Date/Time toggles and values
    @State private var isDateEnabled: Bool = false
    @State private var isTimeEnabled: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var showDateSheet: Bool = false
    @State private var showTimeSheet: Bool = false
    
    init(store: NewFollowUpStore, existingItem: FollowUp? = nil) {
        self.store = store
        self.existingItem = existingItem
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Message Group
                Section {
                    TextField("Message", text: $notes)
                        .font(.body)
                }
                
                // Contact Group
                Section {
                    HStack {
                        Text("Self")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: $isForSelf)
                    }
                    
                    if isForSelf {
                        HStack {
                            Text("Self")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    } else {
                        HStack {
                            Text("Contact")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(contactName.isEmpty ? "Choose…" : contactName) {
                                showContactPicker = true
                            }
                            .foregroundStyle(.primary)
                            .disabled(isForSelf)
                        }
                    }
                }
                
                // App and Tag Group
                Section {
                    HStack {
                        Text("App")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(AppKind.allCases) { app in
                                Button {
                                    selectedApp = app
                                } label: {
                                    HStack {
                                        AppLogoView(app, size: 20)
                                        Text(app.label)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                AppLogoView(selectedApp, size: 20)
                                Text(selectedApp.label)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    
                    HStack {
                        Text("Tag")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            Button("Do") { selectedType = .doIt }
                            Button("Waiting-On") { selectedType = .waitingOn }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "number")
                                    .font(.system(size: 14))
                                Text(selectedType.title)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                
                // URL Group
                Section {
                    HStack {
                        Text("URL")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Optional", text: $url)
                            .keyboardType(.URL)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.primary)
                    }
                }
                
                // Date and Time Group
                Section {
                    // DATE ROW
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.primary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date")
                                .foregroundStyle(.secondary)
                            if isDateEnabled {
                                Text(selectedDate.formatted(date: .complete, time: .omitted))
                                    .font(.footnote)
                                    .foregroundStyle(.tint)
                                    .onTapGesture { showDateSheet = true }
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $isDateEnabled)
                            .onChange(of: isDateEnabled) { _, on in
                                if on { showDateSheet = true }
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isDateEnabled { showDateSheet = true }
                    }

                    // TIME ROW
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundStyle(.primary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .foregroundStyle(.secondary)
                            if isTimeEnabled {
                                Text(selectedTime.formatted(date: .omitted, time: .shortened))
                                    .font(.footnote)
                                    .foregroundStyle(.tint)
                                    .onTapGesture { showTimeSheet = true }
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $isTimeEnabled)
                            .onChange(of: isTimeEnabled) { _, on in
                                if on { showTimeSheet = true }
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isTimeEnabled { showTimeSheet = true }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(existingItem == nil ? "New Follow-up" : "Edit Follow-up")
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
                        saveFollowUp()
                    }
                    .disabled(!isSaveEnabled)
                    .foregroundStyle(!isSaveEnabled ? .secondary : .primary).fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(showContactPicker || showDateSheet || showTimeSheet)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerHost(selectedContact: $contactName, isPresented: $showContactPicker)
        }
        // DATE PICKER SHEET
        .sheet(isPresented: $showDateSheet) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: $selectedDate,
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
                        Button("Cancel") { showDateSheet = false }
                            .foregroundStyle(.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showDateSheet = false }
                            .foregroundStyle(.primary).fontWeight(.medium)
                    }
                }
            }
        }

        // TIME PICKER SHEET
        .sheet(isPresented: $showTimeSheet) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: $selectedTime,
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
                        Button("Cancel") { showTimeSheet = false }
                            .foregroundStyle(.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showTimeSheet = false }
                            .foregroundStyle(.primary).fontWeight(.medium)
                    }
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: notes) { _, _ in
            parseText()
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var isSaveEnabled: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var composedDue: Date? {
        let calendar = Calendar.current
        
        switch (isDateEnabled, isTimeEnabled) {
        case (false, false):
            return nil
        case (true, false):
            // Date only - set to morning hour
            return calendar.date(bySettingHour: store.settings.morningHour, minute: 0, second: 0, of: selectedDate)
        case (false, true):
            // Time only - assume today
            let today = calendar.startOfDay(for: Date())
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: today)
        case (true, true):
            // Both - combine date and time
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            var combinedComponents = dateComponents
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            combinedComponents.second = 0
            return calendar.date(from: combinedComponents)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dateDay = calendar.startOfDay(for: date)
        
        if calendar.isDate(dateDay, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(dateDay, inSameDayAs: yesterday) {
            return "Yesterday"
        } else if calendar.isDate(dateDay, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private func setupInitialState() {
        if let item = existingItem {
            // Populate fields for editing
            notes = item.snippet
            contactName = item.contactLabel
            isForSelf = (item.contactLabel == "Self")
            selectedType = item.type
            selectedApp = item.app
            url = item.url ?? ""
            
            // Set up date/time based on dueAt
            let calendar = Calendar.current
            let dueDate = item.dueAt
            let today = calendar.startOfDay(for: Date())
            let dueDay = calendar.startOfDay(for: dueDate)
            
            if calendar.isDate(dueDay, inSameDayAs: today) {
                // Same day - enable time only
                isTimeEnabled = true
                selectedTime = dueDate
            } else {
                // Different day - enable both date and time
                isDateEnabled = true
                selectedDate = dueDate
                isTimeEnabled = true
                selectedTime = dueDate
            }
            
            suggestedVerb = item.verb
            suggestedDue = item.dueAt
        } else {
            // Default values for new item
            selectedType = .doIt
            selectedApp = .whatsapp
            selectedDate = Date()
            selectedTime = Date()
            suggestedVerb = nil
            suggestedDue = nil
            isForSelf = false
        }
    }
    
    private func parseText() {
        guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestedVerb = nil
            suggestedDue = nil
            return
        }
        
        // Only parse if user hasn't enabled date/time toggles
        guard !isDateEnabled && !isTimeEnabled else { return }
        
        let parsed = Parser.shared.parse(
            text: notes,
            now: .now,
            eodHour: store.settings.eodHour,
            morningHour: store.settings.morningHour
        )
        
        if let parsed = parsed {
            if suggestedVerb == nil {
                suggestedVerb = parsed.verb
            }
            if suggestedDue == nil {
                suggestedDue = parsed.dueAt
                // Auto-enable date/time if parser suggests a due date
                let suggestedDate = parsed.dueAt
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let suggestedDay = calendar.startOfDay(for: suggestedDate)
                
                if calendar.isDate(suggestedDay, inSameDayAs: today) {
                    isTimeEnabled = true
                    selectedTime = suggestedDate
                } else {
                    isDateEnabled = true
                    selectedDate = suggestedDate
                    isTimeEnabled = true
                    selectedTime = suggestedDate
                }
            }
        }
    }
    
    private func saveFollowUp() {
        guard isSaveEnabled else { return }
        
        let finalContact = isForSelf ? "Self" : contactName
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingItem = existingItem {
            // Update existing item
            var updatedItem = existingItem
            updatedItem.type = selectedType
            updatedItem.contactLabel = finalContact
            updatedItem.app = selectedApp
            updatedItem.snippet = notes
            updatedItem.url = trimmedURL.isEmpty ? nil : trimmedURL
            updatedItem.verb = suggestedVerb ?? "follow up"
            updatedItem.dueAt = composedDue ?? existingItem.dueAt
            
            Task {
                do {
                    try await store.update(updatedItem)
                } catch {
                    print("Failed to update follow-up: \(error)")
                }
            }
        } else {
            // Create new item - add URL to the add method
            print("🎯 AddFollowUpView: Creating new follow-up")
            print("   - Raw notes: '\(notes)'")
            print("   - Final contact: '\(finalContact)'")
            print("   - Selected type: \(selectedType)")
            print("   - Selected app: \(selectedApp)")
            print("   - Trimmed URL: '\(trimmedURL)'")
            
            let parsed = Parser.shared.parse(text: notes, now: Date(), eodHour: store.settings.eodHour, morningHour: store.settings.morningHour)
            let due = composedDue ?? parsed?.dueAt ?? defaultDue(now: Date())
            let verb = parsed?.verb ?? Parser.shared.detectVerb(in: notes) ?? "follow up"
            let finalType = parsed?.type ?? selectedType
            
            print("   - Parsed verb: '\(verb)'")
            print("   - Final type: \(finalType)")
            print("   - Due date: \(due)")
            
            let followUp = FollowUp(
                id: UUID(),
                type: finalType,
                contactLabel: finalContact.isEmpty ? "Unknown" : finalContact,
                app: selectedApp,
                snippet: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                url: trimmedURL.isEmpty ? nil : trimmedURL,
                verb: verb,
                dueAt: due,
                createdAt: Date(),
                status: .open,
                lastNudgedAt: nil
            )
            
            print("📝 AddFollowUpView: Final FollowUp object:")
            print("   - ID: \(followUp.id.uuidString)")
            print("   - Snippet: '\(followUp.snippet)'")
            print("   - ContactLabel: '\(followUp.contactLabel)'")
            print("   - Verb: '\(followUp.verb)'")
            print("   - Type: \(followUp.type.rawValue)")
            print("   - App: \(followUp.app.rawValue)")
            
            Task {
                do {
                    try await store.create(followUp)
                    print("✅ AddFollowUpView: Successfully created follow-up")
                } catch {
                    print("❌ AddFollowUpView: Failed to create follow-up: \(error)")
                }
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
    
    /// Default due date calculation
    private func defaultDue(now: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        if hour < store.settings.eodHour {
            // Before EOD, due today at EOD
            return calendar.date(bySettingHour: store.settings.eodHour, minute: 0, second: 0, of: now) ?? now
        } else {
            // After EOD, due tomorrow at morning hour
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return calendar.date(bySettingHour: store.settings.morningHour, minute: 0, second: 0, of: tomorrow) ?? now
        }
    }
}


struct ContactPickerHost: UIViewControllerRepresentable {
    @Binding var selectedContact: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear
        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present once when the SwiftUI sheet becomes visible.
        if isPresented, context.coordinator.presented == false, uiViewController.presentedViewController == nil {
            let picker = CNContactPickerViewController()
            picker.delegate = context.coordinator
            context.coordinator.presented = true
            uiViewController.present(picker, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerHost
        var presented = false

        init(_ parent: ContactPickerHost) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let full = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let org = contact.organizationName
            let name = full.isEmpty ? (org.isEmpty ? "Unknown" : org) : full
            parent.selectedContact = name
            presented = false
            parent.isPresented = false
            picker.dismiss(animated: true)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            presented = false
            parent.isPresented = false
            picker.dismiss(animated: true)
        }
    }
}

#Preview("New Follow-up") {
    AddFollowUpView(store: NewFollowUpStore())
}

#Preview("Edit Follow-up") {
    AddFollowUpView(store: NewFollowUpStore(), existingItem: FollowUp(
        id: UUID(),
        type: .doIt,
        contactLabel: "John Doe",
        app: .whatsapp,
        snippet: "Can you share the deck tomorrow 10?",
        verb: "share",
        dueAt: Date().addingTimeInterval(24 * 3600),
        createdAt: Date(),
        status: .open,
        lastNudgedAt: nil
    ))
}
