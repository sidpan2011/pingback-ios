import Foundation
import UIKit

/// Deep-linking helper for opening chats in different messaging apps
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
        switch appType {
        case .whatsapp:
            return openWhatsAppChat(person: person, message: message)
        case .telegram:
            return openTelegramChat(person: person, message: message)
        case .sms:
            return openSMSChat(person: person, message: message)
        case .slack:
            return openSlackChat(person: person, message: message)
        case .instagram, .email, .gmail, .outlook, .chrome, .safari:
            print("❌ DeepLink: \(appType.label) not supported for deep linking")
            return false
        }
    }
    
    // MARK: - WhatsApp Deep Linking
    
    private static func openWhatsAppChat(person: Person, message: String) -> Bool {
        guard let phoneNumber = person.e164PhoneNumber else {
            print("❌ DeepLink: No phone number available for WhatsApp")
            return false
        }
        
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Primary WhatsApp deep link
        let primaryURL = "whatsapp://send?phone=\(digitsOnly)&text=\(encodedMessage)"
        
        if let url = URL(string: primaryURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened WhatsApp chat successfully")
                } else {
                    print("❌ DeepLink: Failed to open WhatsApp chat")
                }
            }
            return true
        }
        
        // Fallback to WhatsApp web
        let fallbackURL = "https://wa.me/\(digitsOnly)?text=\(encodedMessage)"
        
        if let url = URL(string: fallbackURL) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened WhatsApp web fallback successfully")
                } else {
                    print("❌ DeepLink: Failed to open WhatsApp web fallback")
                }
            }
            return true
        }
        
        print("❌ DeepLink: Unable to construct WhatsApp URL")
        return false
    }
    
    // MARK: - Telegram Deep Linking
    
    private static func openTelegramChat(person: Person, message: String) -> Bool {
        guard let username = person.telegramUsername else {
            print("❌ DeepLink: No Telegram username available")
            return false
        }
        
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let telegramURL = "tg://resolve?domain=\(username)&text=\(encodedMessage)"
        
        if let url = URL(string: telegramURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened Telegram chat successfully")
                } else {
                    print("❌ DeepLink: Failed to open Telegram chat")
                }
            }
            return true
        }
        
        // Show error if Telegram app is not available
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let alert = UIAlertController(
                    title: "Telegram Not Available",
                    message: "Please install Telegram or ensure the username is correct.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                window.rootViewController?.present(alert, animated: true)
            }
        }
        
        print("❌ DeepLink: Telegram app not available")
        return false
    }
    
    // MARK: - SMS Deep Linking
    
    private static func openSMSChat(person: Person, message: String) -> Bool {
        guard let phoneNumber = person.e164PhoneNumber else {
            print("❌ DeepLink: No phone number available for SMS")
            return false
        }
        
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let smsURL = "sms:\(digitsOnly)"
        
        // Note: SMS scheme doesn't reliably support message prefilling
        if let url = URL(string: smsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened SMS chat successfully")
                    print("ℹ️ DeepLink: Message prefill not supported for SMS")
                } else {
                    print("❌ DeepLink: Failed to open SMS chat")
                }
            }
            return true
        }
        
        print("❌ DeepLink: Unable to open SMS")
        return false
    }
    
    // MARK: - Slack Deep Linking
    
    private static func openSlackChat(person: Person, message: String) -> Bool {
        guard let slackLink = person.slackLink else {
            print("❌ DeepLink: No Slack link available")
            return false
        }
        
        // Slack uses universal links, message prefill is not supported
        if let url = URL(string: slackLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened Slack chat successfully")
                    print("ℹ️ DeepLink: Message prefill not supported for Slack")
                } else {
                    print("❌ DeepLink: Failed to open Slack chat")
                }
            }
            return true
        }
        
        print("❌ DeepLink: Invalid Slack link")
        return false
    }
    
    // MARK: - Utility Functions
    
    /// Check if an app is installed and can handle deep links
    static func canOpenApp(_ appType: AppKind) -> Bool {
        switch appType {
        case .whatsapp:
            return UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!)
        case .telegram:
            return UIApplication.shared.canOpenURL(URL(string: "tg://")!)
        case .sms:
            return UIApplication.shared.canOpenURL(URL(string: "sms:")!)
        case .slack:
            // Slack uses universal links, always return true
            return true
        case .instagram, .email, .gmail, .outlook, .chrome, .safari:
            // These apps don't support deep linking for messaging
            return false
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
    
    /// Extract digits only from phone number for messaging apps
    static func digitsOnly(from phoneNumber: String) -> String {
        return phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}

// MARK: - Extensions for URL Encoding

extension String {
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
