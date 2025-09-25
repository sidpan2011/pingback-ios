import SwiftUI
import Contacts
import ContactsUI

struct AddFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @ObservedObject var store: NewFollowUpStore
    @StateObject private var featureAccess = FeatureAccessLayer.shared
    
    let existingItem: FollowUp?
    
    @State private var notes: String = ""
    @State private var contactName: String = "" {
        didSet {
            print("🔵 AddFollowUpView: contactName changed from '\(oldValue)' to '\(contactName)'")
        }
    }
    @State private var selectedPerson: Person?
    @State private var isForSelf: Bool = false
    @State private var selectedType: FollowType = .doIt
    @State private var selectedApp: AppKind = .whatsapp
    @State private var url: String = ""
    @State private var suggestedVerb: String? = nil
    @State private var suggestedDue: Date? = nil
    
    // Date/Time toggles and values
    @State private var isDateEnabled: Bool = false
    @State private var isTimeEnabled: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var showDateSheet: Bool = false
    @State private var showTimeSheet: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showUsageLimitAlert: Bool = false
    @State private var showProFeatureAlert: Bool = false
    
    init(store: NewFollowUpStore, existingItem: FollowUp? = nil) {
        self.store = store
        self.existingItem = existingItem
    }
    
    var body: some View {
        NavigationStack {
            List {
                messageSection
                contactSection
                appAndTagSection
                urlSection
                dateTimeSection
                usageSection
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
                        print("🚨 AddFollowUpView: Done button tapped!")
                        saveFollowUp()
                    }
                    .disabled(!isSaveEnabled)
                    .foregroundStyle(!isSaveEnabled ? .secondary : .primary).fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(showDateSheet || showTimeSheet)
        .onAppear {
            print("🟢 AddFollowUpView: Main sheet appeared")
        }
        .onDisappear {
            print("🔴 AddFollowUpView: Main sheet disappeared")
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
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
        }
        .alert("Follow-up Limit Reached", isPresented: $showUsageLimitAlert) {
            Button("Upgrade to Pro") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You've reached your monthly limit of 10 follow-ups. Upgrade to Pro for unlimited follow-ups.")
        }
        .alert("Pro Feature Required", isPresented: $showProFeatureAlert) {
            Button("Upgrade to Pro") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\(selectedApp.label) integration requires Pro. Upgrade to Pro to use this feature.")
        }
    }
    
    
    // MARK: - Sections (split to reduce type-checking complexity)
    @ViewBuilder
    private var messageSection: some View {
        Section {
            TextField("Message", text: $notes)
                .font(.body)
        } header: { EmptyView() } footer: { EmptyView() }
    }

    @ViewBuilder
    private var contactSection: some View {
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
                        print("🟡 AddFollowUpView: Contact picker button tapped")
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        ContactPickerBridge.shared.presentForPerson { pickedPerson in
                            print("🟣 AddFollowUpView: picked person = \(pickedPerson?.displayName ?? "nil")")
                            if let person = pickedPerson {
                                self.selectedPerson = person
                                self.contactName = person.displayName
                                print("🟣 AddFollowUpView: Person has \(person.phoneNumbers.count) phone numbers")
                            }
                        }
                    }
                    .foregroundStyle(.tint)
                    .padding(.horizontal, contactName.isEmpty ? 0 : 12)
                    .padding(.vertical, contactName.isEmpty ? 0 : 6)
                    // .background(contactName.isEmpty ? Color.clear : Color.primary)
                    .background(contactName.isEmpty ? Color.clear : Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(isForSelf)
                }
            }
        } header: { EmptyView() } footer: { EmptyView() }
    }

    @ViewBuilder
    private var appAndTagSection: some View {
        Section {
            HStack {
                Text("App")
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    ForEach(getAvailableApps()) { app in
                        Button {
                            selectedApp = app
                        } label: {
                            HStack {
                                AppLogoView(app, size: 20)
                                Text(app.label)
                                if !featureAccess.isIntegrationAvailable(getIntegrationForApp(app)) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(!featureAccess.isIntegrationAvailable(getIntegrationForApp(app)))
                    }
                } label: {
                    HStack {
                        AppLogoView(selectedApp, size: 20)
                        Text(selectedApp.label)
                        if !featureAccess.isIntegrationAvailable(getIntegrationForApp(selectedApp)) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
        } header: { EmptyView() } footer: { EmptyView() }
    }

    @ViewBuilder
    private var urlSection: some View {
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
        } header: { EmptyView() } footer: { EmptyView() }
    }

    @ViewBuilder
    private var dateTimeSection: some View {
        Section {
            // Show completion date for completed follow-ups, otherwise show date/time pickers
            if let item = existingItem, item.status == .done {
                // COMPLETED ROW
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Completed")
                            .foregroundStyle(.secondary)
                        Text(item.lastNudgedAt?.formatted(date: .abbreviated, time: .shortened) ?? Date().formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
            } else {
                // DATE ROW (for non-completed follow-ups)
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
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isDateEnabled { showDateSheet = true }
                }

                // TIME ROW (for non-completed follow-ups)
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isTimeEnabled { showTimeSheet = true }
            }
            }
        } header: { 
            EmptyView() 
        } footer: {
            Text(defaultTimeFooterText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var usageSection: some View {
        // Only show usage info for new follow-ups (not editing existing ones)
        if existingItem == nil {
            Section {
                if subscriptionManager.isPro {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Pro - Unlimited follow-ups")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free Plan")
                                .foregroundColor(.primary)
                            Text("\(featureAccess.getRemainingReminders()) follow-ups remaining this month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if featureAccess.getRemainingReminders() <= 2 {
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            } header: {
                Text("Usage")
            } footer: {
                if !subscriptionManager.isPro {
                    Text("Upgrade to Pro for unlimited follow-ups and advanced features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Computed Properties
    
    private var isSaveEnabled: Bool {
        let enabled = !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        print("🟠 AddFollowUpView: isSaveEnabled computed = \(enabled) (notes: '\(notes.prefix(20))...')")
        return enabled
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
    
    private func getAvailableApps() -> [AppKind] {
        if subscriptionManager.isPro {
            return AppKind.allCases
        } else {
            // Free users only get basic integrations
            return AppKind.allCases.filter { app in
                switch app {
                case .whatsapp, .sms, .email, .safari:
                    return true // Free
                case .telegram, .slack, .gmail, .outlook, .chrome, .instagram:
                    return false // Pro only
                }
            }
        }
    }
    
    private func getIntegrationForApp(_ app: AppKind) -> Integration {
        switch app {
        case .sms:
            return .messages
        case .email:
            return .mail
        case .safari:
            return .safariShare
        case .whatsapp:
            return .whatsapp
        case .telegram:
            return .telegram
        case .slack:
            return .slack
        case .gmail:
            return .gmail
        case .outlook:
            return .outlook
        case .chrome:
            return .chromeShare
        case .instagram:
            return .whatsapp // Instagram not supported in v1, map to WhatsApp
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
            suggestedVerb = nil
            suggestedDue = nil
            isForSelf = false
            
            // Pre-fill date and time with defaults so user can see the values
            let now = Date()
            let defaultDueDate = defaultDue(now: now)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let dueDay = calendar.startOfDay(for: defaultDueDate)
            
            // Always set the date and time values first
            selectedDate = defaultDueDate
            selectedTime = defaultDueDate
            
            if calendar.isDate(dueDay, inSameDayAs: today) {
                // Same day - enable time only, but show today's date
                isTimeEnabled = true
                isDateEnabled = true  // Enable date so user can see it's set to today
            } else {
                // Different day - enable both date and time
                isDateEnabled = true
                isTimeEnabled = true
            }
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
        print("🚨 AddFollowUpView: saveFollowUp() called!")
        print("🚨 AddFollowUpView: isSaveEnabled = \(isSaveEnabled)")
        guard isSaveEnabled else { 
            print("🚨 AddFollowUpView: Save blocked - isSaveEnabled is false")
            return 
        }
        
        // Check follow-up limit for new follow-ups only
        if existingItem == nil && !featureAccess.canCreateReminder() {
            print("🚨 AddFollowUpView: Follow-up limit reached - showing alert")
            showUsageLimitAlert = true
            return
        }
        
        let finalContact = isForSelf ? "Self" : contactName
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingItem = existingItem {
            // Update existing item - create a new FollowUp with updated values
            let updatedPerson = Person(
                id: existingItem.person.id,
                firstName: isForSelf ? "Self" : finalContact,
                lastName: "",
                phoneNumbers: existingItem.person.phoneNumbers,
                telegramUsername: existingItem.person.telegramUsername,
                slackLink: existingItem.person.slackLink
            )
            
            let updatedItem = FollowUp(
                id: existingItem.id,
                type: selectedType,
                person: updatedPerson,
                appType: selectedApp,
                note: notes,
                url: trimmedURL.isEmpty ? nil : trimmedURL,
                dueAt: composedDue ?? existingItem.dueAt,
                createdAt: existingItem.createdAt,
                status: existingItem.status,
                lastNudgedAt: existingItem.lastNudgedAt,
                cadence: existingItem.cadence,
                templateId: existingItem.templateId
            )
            
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
            
            // Use selectedPerson if available (contains phone numbers), otherwise create from name
            let person = selectedPerson ?? Person(
                firstName: isForSelf ? "Self" : (finalContact.isEmpty ? "Unknown" : finalContact),
                lastName: ""
            )
            
            let followUp = FollowUp(
                id: UUID(),
                type: finalType,
                person: person,
                appType: selectedApp,
                note: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                url: trimmedURL.isEmpty ? nil : trimmedURL,
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
            
            // Check if selected app is a pro feature and user is not pro
            if !subscriptionManager.isPro && !isFreeApp(selectedApp) {
                print("🔴 AddFollowUpView: Pro feature selected but user is not pro")
                showProFeatureAlert = true
                return
            }
            
            Task {
                do {
                    try await store.create(followUp)
                    print("✅ AddFollowUpView: Successfully created follow-up")
                    
                    // Update count from Core Data instead of manual decrementing
                    await subscriptionManager.updateFollowUpCountFromCoreData()
                    print("📊 AddFollowUpView: Updated count from Core Data. Remaining: \(subscriptionManager.followUpsRemaining)")
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
    
    /// Default due date calculation - matches ShareExtensionViewModel logic
    private func defaultDue(now: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Match ShareExtensionViewModel logic: if before 6pm -> today 6pm, else -> tomorrow 9am
        // Also respect quiet hours (no schedule 22:00–07:00; roll to next morning 09:00)
        if hour >= 22 || hour < 7 {
            // After 10pm or before 7am -> Tomorrow 9am
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            return tomorrow9am
        } else if hour < 18 {
            // Before 6pm -> Today 6pm (matches ShareExtensionViewModel logic)
            let today6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            return today6pm
        } else {
            // After 6pm -> Tomorrow 9am
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            return tomorrow9am
        }
    }
    
    /// Footer text for date/time section - matches ShareExtensionViewModel
    private var defaultTimeFooterText: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 9 && hour < 18 {
            return "By default we create the follow-up for today at 6:00 PM"
        } else {
            return "By default we create the follow-up for tomorrow at 9:00 AM"
        }
    }
}


#Preview("New Follow-up") {
    AddFollowUpView(store: NewFollowUpStore())
        .environmentObject(SubscriptionManager.shared)
}

#Preview("Edit Follow-up") {
    AddFollowUpView(store: NewFollowUpStore(), existingItem: FollowUp(
        id: UUID(),
        type: .doIt,
        person: Person(firstName: "John", lastName: "Doe", phoneNumbers: ["+1234567890"]),
        appType: .whatsapp,
        note: "Can you share the deck tomorrow 10?",
        dueAt: Date().addingTimeInterval(24 * 3600),
        createdAt: Date(),
        status: .open,
        lastNudgedAt: nil
    ))
    .environmentObject(SubscriptionManager.shared)
}
