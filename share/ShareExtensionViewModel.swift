import SwiftUI
import Contacts
import Foundation

struct ShareQuickTimeOption {
    let title: String
    let subtitle: String?
    let date: Date
    let isDefault: Bool
}

@MainActor
class ShareExtensionViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var selectedApp: AppKind = .whatsapp
    @Published var selectedPerson: Person?
    @Published var selectedType: FollowType = .doIt
    @Published var messagePreview = ""
    @Published var editedMessage = ""
    @Published var isEditingMessage = false
    @Published var selectedQuickTime: String?
    @Published var customDateTime = Date().addingTimeInterval(24 * 60 * 60)
    @Published var contactSearchQuery = ""
    @Published var showContactPicker = false
    @Published var showDateTimePicker = false
    @Published var showDateSheet = false
    @Published var showTimeSheet = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    @Published var recentContacts: [Person] = []
    @Published var contactName = "" {
        didSet {
            print("🔵 ViewModel contactName changed from '\(oldValue)' to '\(contactName)'")
            print("🔵 ViewModel selectedPerson is: \(selectedPerson?.displayName ?? "nil")")
            if let person = selectedPerson {
                print("🔵 ViewModel selectedPerson phone numbers: \(person.phoneNumbers)")
            }
        }
    }
    @Published var isDateEnabled = false
    @Published var isTimeEnabled = false
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    
    private var extensionContext: NSExtensionContext?
    private var extractedText: String?
    private var extractedURL: String?
    private var smartDefaults = SmartDefaults()
    @Published var isInitializing = false
    
    // Using existing quickTimeOptions from smartDefaults
    
    var showSaveButton: Bool {
        isEditingMessage || selectedQuickTime == "Pick…"
    }
    
    var canSave: Bool {
        let hasContact = !contactName.isEmpty
        let hasMessage = !editedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasContact && hasMessage
    }
    
    var finalMessage: String {
        editedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var quickTimeOptions: [ShareQuickTimeOption] {
        smartDefaults.getQuickTimeOptions()
    }
    
    var defaultTimeFooterText: String {
        return "Respects quiet hours (10 PM - 7 AM)"
    }
    
    var isProUser: Bool {
        // Check subscription status from shared UserDefaults
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            return false
        }
        return appGroupDefaults.bool(forKey: "isProUser")
    }
    
    func getAvailableApps() -> [AppKind] {
        if isProUser {
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
    
    private func isFreeApp(_ app: AppKind) -> Bool {
        switch app {
        case .whatsapp, .sms, .email, .safari:
            return true
        case .telegram, .slack, .gmail, .outlook, .chrome, .instagram:
            return false
        }
    }
    
    var selectedDueDate: Date {
        // If user has manually enabled date/time pickers, use their selections
        if isDateEnabled || isTimeEnabled {
            let calendar = Calendar.current
            
            if isDateEnabled && isTimeEnabled {
                // Both date and time are enabled - combine them
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                var combinedComponents = dateComponents
                combinedComponents.hour = timeComponents.hour
                combinedComponents.minute = timeComponents.minute
                combinedComponents.second = 0
                return calendar.date(from: combinedComponents) ?? selectedDate
            } else if isDateEnabled {
                // Only date is enabled - use selected date with current time
                let timeComponents = calendar.dateComponents([.hour, .minute], from: Date())
                return calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: selectedDate) ?? selectedDate
            } else if isTimeEnabled {
                // Only time is enabled - use today's date with selected time
                let today = calendar.startOfDay(for: Date())
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                return calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: today) ?? selectedTime
            }
        }
        
        // Fallback to quick time options or custom date
        if selectedQuickTime == "Custom" {
            return customDateTime
        } else if let option = quickTimeOptions.first(where: { $0.title == selectedQuickTime }) {
            return option.date
        } else {
            return smartDefaults.getSmartDefault()
        }
    }
    
    func initialize(with extensionContext: NSExtensionContext? = nil) async {
        isInitializing = true
        self.extensionContext = extensionContext
        
        // Extract content from share extension
        if let context = extensionContext {
            extractedText = await ShareExtensionHelpers.extractText(from: context)
            if let text = extractedText {
                extractedURL = ShareExtensionHelpers.extractURL(from: text)
                messagePreview = smartDefaults.formatMessagePreview(text: text, url: extractedURL)
                editedMessage = messagePreview
            }
        }
        
        // Load recent contacts
        await loadRecentContacts()
        
        // Set smart default time
        selectedQuickTime = quickTimeOptions.first { $0.isDefault }?.title
        
        // Pre-fill date and time with defaults so user can see the values
        let defaultDate = smartDefaults.getSmartDefault()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaultDay = calendar.startOfDay(for: defaultDate)
        
        // Set the date/time values first
        selectedDate = defaultDate
        selectedTime = defaultDate
        
        // Set the toggles directly - no onChange handlers to worry about
        if calendar.isDate(defaultDay, inSameDayAs: today) {
            // Same day - enable time only
            isTimeEnabled = true
        } else {
            // Different day - enable both date and time
            isDateEnabled = true
            isTimeEnabled = true
        }
        
        isInitializing = false
        isLoading = false
    }
    
    func toggleMessageEdit() {
        isEditingMessage.toggle()
        if isEditingMessage {
            editedMessage = messagePreview
        }
    }
    
    func selectQuickTime(_ title: String) {
        selectedQuickTime = title
    }
    
    func handleContactLongPress(_ person: Person) {
        // TODO: Implement phone number disambiguation for contacts with multiple numbers
        // For now, just use quick save
        Task {
            await quickSave(with: person)
        }
    }
    
    func quickSave(with person: Person) async {
        selectedPerson = person
        contactName = person.firstName + (person.lastName.isEmpty ? "" : " " + person.lastName)
        
        // WhatsApp-only mode - app is always WhatsApp
        
        // Use smart default time if none selected
        if selectedQuickTime == nil {
            selectedQuickTime = quickTimeOptions.first { $0.isDefault }?.title
        }
        
        await save()
    }
    
    func saveWithCurrentSelections() async {
        print("🔵 saveWithCurrentSelections called")
        print("🔵 Current state - contactName: '\(contactName)', canSave: \(canSave)")
        
        guard !contactName.isEmpty else {
            print("🔴 Save failed: contactName is empty in saveWithCurrentSelections")
            errorMessage = "Please select a contact"
            showError = true
            return
        }
        
        print("🔵 Proceeding to save()")
        await save()
    }
    
    func selectContact(_ person: Person) {
        selectedPerson = person
        contactName = person.displayName
        // Auto-select default time if none selected
        if selectedQuickTime == nil {
            selectedQuickTime = quickTimeOptions.first { $0.isDefault }?.title
        }
    }
    
    func searchContacts() {
        // TODO: Implement contact search functionality
        print("🔍 Searching contacts for: \(contactSearchQuery)")
    }
    
    private func save() async {
        print("🔵 Starting save() - contactName: '\(contactName)'")
        
        guard !contactName.isEmpty else {
            print("🔴 Save failed: contactName is empty")
            errorMessage = "Please select a contact"
            showError = true
            return
        }
        
        print("🔵 Using selectedPerson or creating from contactName: '\(contactName)'")
        
        // Use the selectedPerson if available (contains phone numbers), otherwise create from name
        let person = selectedPerson ?? Person(
            firstName: contactName,
            lastName: ""
        )
        
        print("🔵 Person details: firstName='\(person.firstName)', phoneNumbers=\(person.phoneNumbers)")
        
        // Check if selected app is a pro feature and user is not pro
        if !isProUser && !isFreeApp(selectedApp) {
            print("🔴 Save failed: Pro feature selected but user is not pro")
            errorMessage = "WhatsApp integration requires Pro. Upgrade to Pro to use this feature."
            showError = true
            return
        }
        
        do {
            let finalDueDate = selectedDueDate
            print("🔵 ShareExtension: Creating follow-up with due date:")
            print("   - isDateEnabled: \(isDateEnabled)")
            print("   - isTimeEnabled: \(isTimeEnabled)")
            print("   - selectedDate: \(selectedDate)")
            print("   - selectedTime: \(selectedTime)")
            print("   - selectedQuickTime: \(selectedQuickTime ?? "nil")")
            print("   - finalDueDate: \(finalDueDate)")
            
            let followUp = FollowUp(
                type: .doIt, // Auto-set to "do" as specified
                person: person,
                appType: selectedApp,
                note: finalMessage,
                url: extractedURL,
                dueAt: finalDueDate,
                cadence: .none // Default cadence
            )
            
            try await saveToSharedStorage(followUp)
            
            // Schedule notification
            try await scheduleNotification(for: followUp)
            
            // Remember sticky preferences
            smartDefaults.rememberStickyApp(selectedApp, for: person)
            smartDefaults.updateRecentContacts(person)
            
            // Show success and dismiss
            showSuccess = true
            
            // Log analytics
            logAnalytics(event: "share_extension_save", followUp: followUp)
            
            // Complete request quickly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.cancel()
            }
            
        } catch {
            errorMessage = "Failed to save follow-up: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func cancel() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    // MARK: - Private Methods
    
    private func loadRecentContacts() async {
        // Load recent contacts from UserDefaults or Core Data
        // For now, return empty array - this would be implemented to load actual recent contacts
        recentContacts = smartDefaults.getRecentContacts()
    }
    
    private func saveToSharedStorage(_ followUp: FollowUp) async throws {
        // Save to app group UserDefaults in the format expected by SharedDataManager
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            throw ShareExtensionError.storageNotAvailable
        }
        
        // Create data in the format expected by SharedDataManager
        // Serialize the full Person object to preserve phone numbers
        var personData: [String: Any] = [:]
        if let personJsonData = try? JSONEncoder().encode(followUp.person),
           let personDict = try? JSONSerialization.jsonObject(with: personJsonData) as? [String: Any] {
            personData = personDict
        }
        
        let sharedData: [String: Any] = [
            "notes": followUp.note,
            "type": followUp.type.rawValue,
            "sourceApp": followUp.appType.label,
            "sourceBundleId": getBundleIdForApp(followUp.appType),
            "contact": followUp.person.displayName, // Keep for backward compatibility
            "person": personData, // NEW: Full Person object with phone numbers
            "url": followUp.url ?? "",
            "dueAt": ISO8601DateFormatter().string(from: followUp.dueAt),
            "createdAt": ISO8601DateFormatter().string(from: followUp.createdAt),
            "id": followUp.id.uuidString
        ]
        
        // Load existing shared follow-ups
        var existingSharedFollowUps: [[String: Any]] = []
        if let data = appGroupDefaults.data(forKey: "shared_followups"),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            existingSharedFollowUps = jsonArray
        }
        
        // Add new follow-up
        existingSharedFollowUps.append(sharedData)
        
        // Save back as JSON
        let jsonData = try JSONSerialization.data(withJSONObject: existingSharedFollowUps)
        appGroupDefaults.set(jsonData, forKey: "shared_followups")
        
        // Update follow-up count for free tier users using Core Data
        await updateFollowUpCountFromCoreData()
        
        appGroupDefaults.synchronize()
        
        print("📱 ShareExtension: Saved follow-up to shared storage:")
        print("   - notes: \(followUp.note)")
        print("   - contact: \(followUp.person.displayName)")
        print("   - person phone numbers: \(followUp.person.phoneNumbers)")
        print("   - app: \(followUp.appType.label)")
        print("   - dueAt: \(followUp.dueAt)")
    }
    
    private func updateFollowUpCountFromCoreData() async {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            print("❌ ShareExtension: Failed to access app group UserDefaults")
            return
        }
        
        // Only update count for free users
        guard !isProUser else {
            print("✅ ShareExtension: Pro user - no count update needed")
            return
        }
        
        // For share extension, we'll just decrement the count and let the main app
        // recalculate from Core Data when it becomes active
        let currentCount = appGroupDefaults.integer(forKey: "followUpsRemaining")
        let newCount = max(0, currentCount - 1)
        
        appGroupDefaults.set(newCount, forKey: "followUpsRemaining")
        appGroupDefaults.synchronize()
        
        print("📊 ShareExtension: Updated count: \(currentCount) → \(newCount)")
        print("📊 ShareExtension: Main app will recalculate from Core Data when active")
    }
    
    private func getBundleIdForApp(_ appKind: AppKind) -> String {
        switch appKind {
        case .whatsapp:
            return "net.whatsapp.WhatsApp"
        case .telegram:
            return "ph.telegra.Telegraph"
        case .slack:
            return "com.tinyspeck.chatlyio"
        case .instagram:
            return "com.burbn.instagram"
        case .sms:
            return "com.apple.MobileSMS"
        case .email:
            return "com.apple.mobilemail"
        case .gmail:
            return "com.google.Gmail"
        case .outlook:
            return "com.microsoft.Office.Outlook"
        case .chrome:
            return "com.google.chrome.ios"
        case .safari:
            return "com.apple.mobilesafari"
        }
    }
    
    private func scheduleNotification(for followUp: FollowUp) async throws {
        try await NotificationService.shared.scheduleNotification(for: followUp)
    }
    
    private func logAnalytics(event: String, followUp: FollowUp) {
        switch event {
        case "share_extension_save":
            AnalyticsService.shared.trackFollowUpCreated(
                app: followUp.appType,
                cadence: followUp.cadence,
                hasTemplate: followUp.templateId != nil
            )
        default:
            break
        }
    }
}

// MARK: - Smart Defaults Helper
class SmartDefaults {
    private let userDefaults = UserDefaults(suiteName: "group.app.pingback.shared") ?? UserDefaults.standard
    
    func getQuickTimeOptions() -> [ShareQuickTimeOption] {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Smart default logic: if now ∈ 09:00–17:00 → Today 18:00; else → Tomorrow 09:00
        let (_, isToday6pm) = getSmartDefaultOption(now: now, hour: hour, calendar: calendar)
        
        // Create options
        let today6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        let validToday6pm = today6pm > now ? today6pm : calendar.date(byAdding: .day, value: 1, to: today6pm) ?? today6pm
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        return [
            ShareQuickTimeOption(
                title: "Today 6pm",
                subtitle: validToday6pm > now ? "in \(timeUntil(validToday6pm, from: now))" : "tomorrow",
                date: validToday6pm,
                isDefault: isToday6pm
            ),
            ShareQuickTimeOption(
                title: "Tomorrow 9am",
                subtitle: "in \(timeUntil(tomorrow9am, from: now))",
                date: tomorrow9am,
                isDefault: !isToday6pm
            )
        ]
    }
    
    func getSmartDefault() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        let (defaultDate, _) = getSmartDefaultOption(now: now, hour: hour, calendar: calendar)
        return defaultDate
    }
    
    private func getSmartDefaultOption(now: Date, hour: Int, calendar: Calendar) -> (Date, Bool) {
        // Match AddFollowUpView logic: if before 6pm -> today 6pm, else -> tomorrow 9am
        // Also respect quiet hours (no schedule 22:00–07:00; roll to next morning 09:00)
        if hour >= 22 || hour < 7 {
            // After 10pm or before 7am -> Tomorrow 9am
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            return (tomorrow9am, false)
        } else if hour < 18 {
            // Before 6pm -> Today 6pm (matches AddFollowUpView logic)
            let today6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            return (today6pm, true)
        } else {
            // After 6pm -> Tomorrow 9am
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            let tomorrow9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            return (tomorrow9am, false)
        }
    }
    
    private func timeUntil(_ date: Date, from now: Date) -> String {
        let interval = date.timeIntervalSince(now)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func formatMessagePreview(text: String, url: String?) -> String {
        var message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Truncate to ~160 chars for preview
        if message.count > 160 {
            let truncated = String(message.prefix(160))
            if let lastSpace = truncated.lastIndex(of: " ") {
                message = String(truncated[..<lastSpace]) + "..."
            } else {
                message = truncated + "..."
            }
        }
        
        // Collapse double spaces
        message = message.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // Strip trailing punctuation if no URL
        if url == nil {
            message = message.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:"))
        }
        
        return message
    }
    
    func getStickyApp(for person: Person) -> AppKind? {
        let key = "sticky_app_\(person.id.uuidString)"
        if let appRawValue = userDefaults.string(forKey: key),
           let app = AppKind(rawValue: appRawValue) {
            return app
        }
        return nil
    }
    
    func rememberStickyApp(_ app: AppKind, for person: Person) {
        let key = "sticky_app_\(person.id.uuidString)"
        userDefaults.set(app.rawValue, forKey: key)
    }
    
    func getRecentContacts() -> [Person] {
        // Load recent contacts from UserDefaults
        // For now, return empty array - this would be implemented to load actual recent contacts
        // In a real implementation, this would load from Core Data or UserDefaults
        return []
    }
    
    func updateRecentContacts(_ person: Person) {
        // Update recent contacts list
        // This would be implemented to maintain a list of recently used contacts
    }
}

enum ShareExtensionError: LocalizedError {
    case storageNotAvailable
    case invalidContact
    case extractionFailed
    
    var errorDescription: String? {
        switch self {
        case .storageNotAvailable:
            return "Unable to access shared storage"
        case .invalidContact:
            return "Selected contact is missing required information"
        case .extractionFailed:
            return "Failed to extract content from share"
        }
    }
}
