import Foundation

enum FollowType: String, CaseIterable, Identifiable {
    case doIt = "DO"
    case waitingOn = "WAITING_ON"
    var id: String { rawValue }
    var title: String { self == .doIt ? "Do" : "Waiting-On" }
}

enum Status: String {
    case open, done, snoozed
}

enum AppKind: String, CaseIterable, Identifiable {
    case whatsapp, telegram, sms, email, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .sms: return "SMS"
        case .email: return "Email"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .whatsapp: return "message.circle"
        case .telegram: return "paperplane.circle"
        case .sms: return "bubble.left.circle"
        case .email: return "envelope.circle"
        case .other: return "square.grid.2x2"
        }
    }
}

struct FollowUp: Identifiable, Equatable {
    let id: UUID
    var type: FollowType
    var contactLabel: String
    var app: AppKind
    var snippet: String
    /// Optional URL associated with this follow-up (web link, doc, etc.)
    var url: String? = nil
    var verb: String
    var dueAt: Date
    var createdAt: Date
    var status: Status
    var lastNudgedAt: Date?
}
