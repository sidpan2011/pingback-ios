import Foundation

enum DeepLinkBuilder {
    static func url(for app: AppKind, text: String) -> URL? {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        switch app {
        case .whatsapp:
            return URL(string: "https://wa.me/?text=\(encoded)")
        case .telegram:
            return URL(string: "tg://msg_url?url=\(encoded)")
        case .sms:
            return URL(string: "sms:&body=\(encoded)")
        case .slack:
            return URL(string: "slack://open")
        case .email:
            return URL(string: "mailto:?subject=Follow-up&body=\(encoded)")
        case .instagram:
            return URL(string: "https://www.instagram.com/direct/inbox/")
        case .gmail, .outlook, .chrome, .safari:
            return URL(string: "https://example.com?text=\(encoded)")
        }
    }
    
    // MARK: - Notification Deep Links
    static func followUpDetailURL(followUpId: UUID) -> URL? {
        return URL(string: "pingback://followup/\(followUpId.uuidString)")
    }
    
    static func homeURL(filter: String? = nil) -> URL? {
        if let filter = filter {
            return URL(string: "pingback://home?filter=\(filter)")
        }
        return URL(string: "pingback://home")
    }
    
    static func handleNotificationURL(_ url: URL) -> NotificationDeepLink? {
        guard url.scheme == "pingback" else { return nil }
        
        switch url.host {
        case "followup":
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2, let followUpId = UUID(uuidString: pathComponents[1]) {
                return .followUpDetail(followUpId)
            }
        case "home":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let filter = components?.queryItems?.first(where: { $0.name == "filter" })?.value
            return .home(filter: filter)
        default:
            break
        }
        
        return nil
    }
}

enum NotificationDeepLink {
    case followUpDetail(UUID)
    case home(filter: String?)
}


