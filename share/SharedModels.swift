import Foundation
import Contacts

// MARK: - Shared Enums and Types

enum AppKind: String, CaseIterable, Identifiable, Codable {
    case whatsapp, telegram, slack, instagram, sms, email, gmail, outlook, chrome, safari
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .slack: return "Slack"
        case .instagram: return "Instagram"
        case .sms: return "SMS"
        case .email: return "Email"
        case .gmail: return "Gmail"
        case .outlook: return "Outlook"
        case .chrome: return "Chrome"
        case .safari: return "Safari"
        }
    }
    
    var icon: String {
        switch self {
        case .whatsapp: return "message.circle.fill"
        case .telegram: return "paperplane.circle.fill"
        case .slack: return "bubble.left.and.bubble.right.fill"
        case .instagram: return "camera.circle.fill"
        case .sms: return "message.badge.circle.fill"
        case .email: return "envelope.circle.fill"
        case .gmail: return "envelope.circle.fill"
        case .outlook: return "envelope.circle.fill"
        case .chrome: return "globe.circle.fill"
        case .safari: return "safari.fill"
        }
    }
    
    var hasCustomLogo: Bool {
        switch self {
        case .whatsapp, .telegram, .slack, .instagram, .sms, .email, .gmail, .outlook, .chrome, .safari:
            return true
        }
    }
    
    var logoImageName: String {
        switch self {
        case .whatsapp: return "WhatsAppLogo"
        case .telegram: return "TelegramLogo"
        case .slack: return "SlackLogo"
        case .instagram: return "InstagramLogo"
        case .sms: return "SMSLogo"
        case .email: return "EmailLogo"
        case .gmail: return "GmailLogo"
        case .outlook: return "OutlookLogo"
        case .chrome: return "ChromeLogo"
        case .safari: return "SafariLogo"
        }
    }
    
    var supportsDeepLink: Bool {
        switch self {
        case .whatsapp, .telegram, .sms:
            return true
        case .slack, .instagram, .email, .gmail, .outlook, .chrome, .safari:
            return false // Requires universal link or not supported
        }
    }
}

// Legacy AppType for backwards compatibility - will be deprecated
typealias AppType = AppKind

enum Cadence: String, CaseIterable, Identifiable, Codable {
    case none = "NONE"
    case every7Days = "EVERY_7_DAYS"
    case every30Days = "EVERY_30_DAYS"
    case weekly = "WEEKLY"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .none: return "None"
        case .every7Days: return "Every 7 days"
        case .every30Days: return "Every 30 days"
        case .weekly: return "Weekly"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .none: return "Once"
        case .every7Days: return "7d"
        case .every30Days: return "30d"
        case .weekly: return "Weekly"
        }
    }
}

enum FollowType: String, CaseIterable, Identifiable, Codable {
    case doIt = "DO"
    case waitingOn = "WAITING_ON"
    var id: String { rawValue }
    var title: String { self == .doIt ? "Do" : "Waiting-On" }
}

enum Status: String, CaseIterable, Codable {
    case open, done, snoozed
}

// MARK: - Shared Models

struct Person: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var phoneNumbers: [String] // E.164 format
    var telegramUsername: String?
    var slackLink: String? // Universal link for Slack
    
    init(id: UUID = UUID(), firstName: String, lastName: String = "", phoneNumbers: [String] = [], telegramUsername: String? = nil, slackLink: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumbers = phoneNumbers
        self.telegramUsername = telegramUsername
        self.slackLink = slackLink
    }
    
    var fullName: String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return fullName.isEmpty ? "Unknown Contact" : fullName
    }
    
    var primaryPhoneNumber: String? {
        return phoneNumbers.first
    }
    
    var e164PhoneNumber: String? {
        return primaryPhoneNumber
    }
}

struct MessageTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var content: String
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, content: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.content = content
        self.isDefault = isDefault
    }
    
    func resolve(firstName: String, note: String, link: String?, selfName: String) -> String {
        return content
            .replacingOccurrences(of: "{first_name}", with: firstName)
            .replacingOccurrences(of: "{note}", with: note)
            .replacingOccurrences(of: "{link}", with: link ?? "")
            .replacingOccurrences(of: "{self_name}", with: selfName)
    }
}

struct FollowUp: Identifiable, Equatable, Codable {
    let id: UUID
    var type: FollowType
    var person: Person
    var appType: AppKind
    var note: String
    var url: String?
    var dueAt: Date
    var createdAt: Date
    var status: Status
    var lastNudgedAt: Date?
    var cadence: Cadence
    var templateId: UUID?
    
    init(
        id: UUID = UUID(),
        type: FollowType = .doIt,
        person: Person,
        appType: AppKind,
        note: String,
        url: String? = nil,
        dueAt: Date,
        createdAt: Date = Date(),
        status: Status = .open,
        lastNudgedAt: Date? = nil,
        cadence: Cadence = .none,
        templateId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.person = person
        self.appType = appType
        self.note = note
        self.url = url
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.status = status
        self.lastNudgedAt = lastNudgedAt
        self.cadence = cadence
        self.templateId = templateId
    }
    
    // Legacy compatibility
    var contactLabel: String {
        return person.displayName
    }
    
    var app: AppKind {
        return appType
    }
    
    var snippet: String {
        return note
    }
    
    var verb: String {
        return type == .doIt ? "Follow up with" : "Waiting on"
    }
    
    var isOverdue: Bool {
        return status == .open && dueAt < Date()
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(dueAt)
    }
    
    var isUpcoming: Bool {
        return status == .open && dueAt > Calendar.current.startOfDay(for: Date().addingTimeInterval(24*60*60))
    }
}

// MARK: - Deep Link Helper

struct DeepLinkHelper {
    
    /// Open a chat for the given follow-up with the specified message
    /// - Parameters:
    ///   - followUp: The follow-up containing person and app information
    ///   - person: The person to message (can override followUp.person)
    ///   - message: The message to prefill
    /// - Returns: True if the deep link was attempted, false if not supported
    @discardableResult
    static func openChat(for followUp: FollowUp, person: Person? = nil, message: String) -> Bool {
        let targetPerson = person ?? followUp.person
        return openChat(appType: followUp.appType, person: targetPerson, message: message)
    }
    
    /// Open a chat for the specified app type, person, and message
    /// - Parameters:
    ///   - appType: The messaging app to use
    ///   - person: The person to message
    ///   - message: The message to prefill
    /// - Returns: True if the deep link was attempted, false if not supported
    @discardableResult
    static func openChat(appType: AppKind, person: Person, message: String) -> Bool {
        // For share extension, we can't actually open URLs
        // This is a placeholder that would be used by the main app
        print("📱 Would open \(appType.label) chat with \(person.displayName): \(message)")
        return true
    }
    
    /// Validate that a person has the required information for the app type
    static func validatePerson(_ person: Person, for appType: AppKind) -> Bool {
        switch appType {
        case .whatsapp, .sms:
            return person.e164PhoneNumber != nil
        case .telegram:
            return person.telegramUsername != nil
        case .slack:
            return person.slackLink != nil
        case .instagram, .email, .gmail, .outlook, .chrome, .safari:
            return false // Not supported for messaging
        }
    }
    
    /// Get the required information for a person based on the app type
    static func getRequiredPersonInfo(for appType: AppKind) -> String {
        switch appType {
        case .whatsapp, .sms:
            return "Phone number required"
        case .telegram:
            return "Telegram username required"
        case .slack:
            return "Slack universal link required"
        case .instagram, .email, .gmail, .outlook, .chrome, .safari:
            return "Not supported for messaging"
        }
    }
}

// MARK: - Notification Service (Stub for Share Extension)

struct NotificationService {
    static let shared = NotificationService()
    
    func scheduleNotification(for followUp: FollowUp) async throws {
        // This is a stub for the share extension
        // The actual scheduling will happen when the main app processes shared data
        print("📅 Would schedule notification for follow-up: \(followUp.id)")
    }
}

// MARK: - Analytics Service (Stub for Share Extension)

struct AnalyticsService {
    static let shared = AnalyticsService()
    
    func trackFollowUpCreated(app: AppKind, cadence: Cadence, hasTemplate: Bool) {
        print("📊 Analytics: follow_up_created - app=\(app.rawValue) cadence=\(cadence.rawValue) hasTemplate=\(hasTemplate)")
    }
}
