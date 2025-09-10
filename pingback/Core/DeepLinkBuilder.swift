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
        case .email:
            return URL(string: "mailto:?subject=Follow-up&body=\(encoded)")
        case .other:
            return URL(string: "https://example.com?text=\(encoded)")
        }
    }
}


