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
        print("🔗 DeepLinkHelper.openChat(for:person:message:) called!")
        print("   - FollowUp ID: \(followUp.id)")
        print("   - App Type: \(followUp.appType.label)")
        print("   - Person: \(followUp.person.displayName)")
        print("   - Message: '\(message)'")
        
        let targetPerson = person ?? followUp.person
        print("   - Target Person: \(targetPerson.displayName)")
        print("   - Target Phone: \(targetPerson.e164PhoneNumber ?? "nil")")
        
        let result = openChat(appType: followUp.appType, person: targetPerson, message: message)
        print("   - openChat result: \(result)")
        return result
    }
    
    /// Open a chat for the specified app type, person, and message
    /// - Parameters:
    ///   - appType: The messaging app to use
    ///   - person: The person to message
    ///   - message: The message to prefill
    /// - Returns: True if the deep link was attempted, false if not supported
    @discardableResult
    static func openChat(appType: AppKind, person: Person, message: String) -> Bool {
        print("🔗 DeepLinkHelper.openChat(appType:person:message:) called!")
        print("   - App Type: \(appType.label) (\(appType.rawValue))")
        print("   - Person: \(person.displayName)")
        print("   - Phone Numbers: \(person.phoneNumbers)")
        print("   - E164 Phone: \(person.e164PhoneNumber ?? "nil")")
        print("   - Message: '\(message)'")
        
        switch appType {
        case .whatsapp:
            print("🔗 DeepLinkHelper: Routing to WhatsApp...")
            return openWhatsAppChat(person: person, message: message)
        case .telegram:
            print("🔗 DeepLinkHelper: Routing to Telegram...")
            return openTelegramChat(person: person, message: message)
        case .sms:
            print("🔗 DeepLinkHelper: Routing to SMS...")
            return openSMSChat(person: person, message: message)
        case .slack:
            print("🔗 DeepLinkHelper: Routing to Slack...")
            return openSlackChat(person: person, message: message)
        case .instagram, .email, .gmail, .outlook, .chrome, .safari:
            print("❌ DeepLink: \(appType.label) not supported for deep linking")
            return false
        }
    }
    
    // MARK: - WhatsApp Deep Linking
    
    private static func openWhatsAppChat(person: Person, message: String) -> Bool {
        print("📱 DeepLinkHelper.openWhatsAppChat() called!")
        print("   - Person: \(person.displayName)")
        print("   - Phone Numbers Array: \(person.phoneNumbers)")
        print("   - E164 Phone Number: \(person.e164PhoneNumber ?? "nil")")
        print("   - Message: '\(message)'")
        
        guard let phoneNumber = person.e164PhoneNumber else {
            print("❌ DeepLink: No phone number available for WhatsApp")
            return false
        }
        
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        print("📱 DeepLink: Extracted digits from phone: '\(phoneNumber)' → '\(digitsOnly)'")
        print("📱 DeepLink: Message for context: '\(message)' (not pre-filling)")
        
        // Primary WhatsApp deep link - open chat directly without pre-filling text
        let primaryURL = "whatsapp://send?phone=\(digitsOnly)"
        print("📱 DeepLink: Constructed primary URL: '\(primaryURL)'")
        
        if let url = URL(string: primaryURL) {
            print("📱 DeepLink: URL object created successfully")
            let canOpen = UIApplication.shared.canOpenURL(url)
            print("📱 DeepLink: canOpenURL(\(primaryURL)) = \(canOpen)")
            
            if canOpen {
                print("📱 DeepLink: Attempting to open WhatsApp...")
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("✅ DeepLink: Opened WhatsApp chat successfully to \(digitsOnly)")
                        print("💬 DeepLink: Landed user directly in chat (no text pre-filled)")
                    } else {
                        print("❌ DeepLink: Failed to open WhatsApp chat")
                    }
                }
                return true
            } else {
                print("⚠️ DeepLink: Cannot open WhatsApp URL, trying fallback...")
            }
        } else {
            print("❌ DeepLink: Failed to create URL object from: '\(primaryURL)'")
        }
        
        // Fallback to WhatsApp web - open chat directly without pre-filling text
        let fallbackURL = "https://wa.me/\(digitsOnly)"
        print("📱 DeepLink: Constructed fallback URL: '\(fallbackURL)'")
        
        if let url = URL(string: fallbackURL) {
            print("📱 DeepLink: Fallback URL object created successfully")
            print("📱 DeepLink: Attempting to open WhatsApp web fallback...")
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ DeepLink: Opened WhatsApp web fallback successfully to \(digitsOnly)")
                    print("💬 DeepLink: Landed user directly in web chat (no text pre-filled)")
                } else {
                    print("❌ DeepLink: Failed to open WhatsApp web fallback")
                }
            }
            return true
        } else {
            print("❌ DeepLink: Failed to create fallback URL object from: '\(fallbackURL)'")
        }
        
        print("❌ DeepLink: Unable to construct any WhatsApp URL")
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
