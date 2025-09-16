import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

/// Helper utilities for the share extension
struct ShareExtensionHelpers {
    
    // MARK: - Text Parsing

    // MARK: - Constants
    /// Single source of truth for known app <-> bundleId mapping
    private static let knownApps: [String: String] = [
    // Messaging
    "net.whatsapp.WhatsApp": "WhatsApp",         // ✅ canonical WhatsApp
    "com.facebook.Messenger": "Messenger",
    "com.apple.MobileSMS": "Messages",
    "ph.telegra.Telegraph": "Telegram",          // ✅ canonical Telegram
    "com.discord": "Discord",
    "com.skype.skype": "Skype",
    "com.microsoft.teams": "Microsoft Teams",
    "com.tinyspeck.chatlyio": "Slack",

    // Mail
    "com.apple.mobilemail": "Mail",
    "com.google.Gmail": "Gmail",
    "com.microsoft.Office.Outlook": "Outlook",

    // Browsers
    "com.apple.mobilesafari": "Safari",
    "com.google.chrome.ios": "Chrome",
    "org.mozilla.ios.Firefox": "Firefox",

    // Notes / Productivity
    "com.apple.mobilenotes": "Notes",
    "com.evernote.iPhone.Evernote": "Evernote",
    "com.notion.iOS": "Notion",

    // Social
    "com.burbn.instagram": "Instagram",          // ✅ canonical Instagram
    "com.twitter.twitter": "Twitter",
    "com.facebook.Facebook": "Facebook",
    "com.linkedin.LinkedIn": "LinkedIn",
    "com.reddit.Reddit": "Reddit"
]

/// Map variant/legacy bundle IDs to canonical IDs we use in the app.
private static func normalize(bundleId: String, appNameHint: String?) -> (appName: String, bundleId: String) {
    let lower = bundleId.lowercased()

    // Aliases we’ve seen in the wild
    if lower.contains("whatsapp") {
        return ("WhatsApp", "net.whatsapp.WhatsApp")
    }
    if lower.contains("instagram") || lower.contains("burbn.instagram") {
        return ("Instagram", "com.burbn.instagram")
    }
    if lower.contains("telegram") || lower.contains("ph.telegra") {
        return ("Telegram", "ph.telegra.Telegraph")
    }
    if lower.contains("mobilesafari") || lower == "safari" {
        return ("Safari", "com.apple.mobilesafari")
    }

    // If we already know this exact bundle ID, use its pretty name
    if let name = knownApps[bundleId] {
        return (name, bundleId)
    }

    // Fallback to the passed app name if present, else derive from bundle tail
    let pretty = appNameHint?.isEmpty == false ? appNameHint! : (bundleId.components(separatedBy: ".").last?.capitalized ?? "Unknown App")
    return (pretty, bundleId)
}
    
    /// Extract the first URL from text content
    static func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.first?.url?.absoluteString
    }
    
    /// Clean and validate text content
    static func cleanText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit text length to prevent oversized content
        let maxLength = 5000
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength)) + "..."
        }
        
        return trimmed
    }
    
    // MARK: - Source App Detection
    
    /// Get human-readable app name from bundle identifier
   static func getAppName(from bundleId: String) -> String {
    #if DEBUG
    print("📦 ShareExtension: getAppName(from:) => \(bundleId)")
    #endif
    return normalize(bundleId: bundleId, appNameHint: nil).appName
}

    /// DEPRECATED - DO NOT USE for new detection. Use smartAppDetection instead.
    /// This method is kept only for legacy compatibility.
    @available(*, deprecated, message: "Use smartAppDetection instead")
    static func getBundleId(for appName: String) -> String {
        print("⚠️ DEPRECATED: getBundleId called - use smartAppDetection instead")
        if let pair = knownApps.first(where: { $0.value.caseInsensitiveCompare(appName) == .orderedSame }) {
            return pair.key
        }
        return "unknown"
    }

    // MARK: - Single Source App Resolver (ONLY detection method)
    /// SINGLE SOURCE OF TRUTH for app detection. All other detection methods are disabled.
    /// Precedence: (1) hard signals in userInfo/title (2) URL/text heuristics. Note: sourceApplicationBundleIdentifier deprecated.
    static func smartAppDetection(text: String?, url: String?, extensionContext: NSExtensionContext?) -> (appName: String, bundleId: String) {
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        print("🚀 ************* SMART APP DETECTION STARTED ************* 🚀")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        print("🚀 Input text: '\(text ?? "nil")'")
        print("🚀 Input URL: '\(url ?? "nil")'")
        print("🚀 Extension context: \(extensionContext != nil ? "EXISTS" : "NIL")")
        print("🚀 Input items count: \(extensionContext?.inputItems.count ?? 0)")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        
        print("🔄🔄🔄 ***** CALLING RELIABLE DETECTOR ***** 🔄🔄🔄")
        let raw = ReliableAppDetector.detectSourceApp(extensionContext: extensionContext, text: text, url: url)
        print("🔄🔄🔄 ***** RELIABLE DETECTOR COMPLETED ***** 🔄🔄🔄")
        
        print("🚀 RAW DETECTOR RESULT: app='\(raw.appName)', bundle='\(raw.bundleId)', confidence='\(raw.confidence)'")
        
        // NORMALIZE at the single choke point to ensure canonical bundle IDs
        let normalized = normalize(bundleId: raw.bundleId, appNameHint: raw.appName)
        print("🎯 NORMALIZED RESULT: app='\(normalized.appName)', bundle='\(normalized.bundleId)'")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        
        // Simple fallback detection for WhatsApp if detector failed
        var finalResult = normalized
        if normalized.appName == "Unknown" || normalized.appName == "Unknown App" {
            print("🚀 FALLBACK DETECTION: Trying simple patterns...")
            
            // WhatsApp simple detection
            if let text = text, text.count > 0 {
                print("🚀 FALLBACK: Checking text for WhatsApp patterns")
                if text.lowercased().contains("whatsapp") || text.lowercased().contains("wa.me") {
                    finalResult = normalize(bundleId: "net.whatsapp.WhatsApp", appNameHint: "WhatsApp")
                    print("🎯 FALLBACK DETECTED: \(finalResult.appName)")
                }
            }
        }
        
        // Structured logging for ShareResolve event
        let textLength = text?.count ?? 0
        let urlString = url ?? "none"
        let contactString = "none" // Contact detection happens later
        print("event=ShareResolve app=\(finalResult.appName) bundle=\(finalResult.bundleId) confidence=\(raw.confidence) textLen=\(textLength) url=\(urlString) contact=\(contactString)")
        
        return finalResult
    }
    
    /// Internal resolver - DO NOT CALL DIRECTLY, use smartAppDetection instead
    private static func resolveSourceApp(extensionContext: NSExtensionContext?, text: String?, url: String?) -> (appName: String, bundleId: String, confidence: String) {
        print("🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭")
        print("🧭 ************* RESOLVER METHOD STARTED ************* 🧭")
        print("🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭")
        print("🧭 Extension context: \(extensionContext != nil ? "EXISTS" : "NIL")")
        print("🧭 Text: '\(text ?? "NIL")'")
        print("🧭 URL: '\(url ?? "NIL")'")
        print("🧭 Input items count: \(extensionContext?.inputItems.count ?? 0)")
        print("🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭🧭")
        
        // NOTE: sourceApplicationBundleIdentifier is deprecated and causes crashes in iOS 18+
        // Skipping deprecated API and using content-based detection instead

        // 2) Enhanced NSExtensionItem inspection with detailed logging
        if let items = extensionContext?.inputItems as? [NSExtensionItem] {
            print("🔍 Resolver: Analyzing \(items.count) extension items")
            
            for (index, item) in items.enumerated() {
                #if DEBUG
                print("🔍 Resolver: === ITEM \(index) ANALYSIS ===")
                if let title = item.attributedTitle?.string {
                    print("🔍 Resolver: Title: '\(title)'")
                } else {
                    print("🔍 Resolver: Title: nil")
                }
                if let contentText = item.attributedContentText?.string {
                    print("🔍 Resolver: Content: '\(String(contentText.prefix(100)))'")
                } else {
                    print("🔍 Resolver: Content: nil")
                }
                if let userInfo = item.userInfo {
                    print("🔍 Resolver: UserInfo keys: \(Array(userInfo.keys))")
                    for (key, value) in userInfo {
                        let keyStr = String(describing: key)
                        let valueStr = String(describing: value)
                        print("🔍 Resolver: UserInfo[\(keyStr)] = \(String(valueStr.prefix(200)))")
                    }
                } else {
                    print("🔍 Resolver: UserInfo: nil")
                }
                if let attachments = item.attachments {
                    print("🔍 Resolver: Attachments: \(attachments.count)")
                    for (attIndex, attachment) in attachments.enumerated() {
                        print("🔍 Resolver: Attachment \(attIndex) types: \(attachment.registeredTypeIdentifiers)")
                    }
                } else {
                    print("🔍 Resolver: Attachments: nil")
                }
                #endif
                
                // Enhanced title-based detection
                if let title = item.attributedTitle?.string.lowercased() {
                    if title.contains("whatsapp") { return ("WhatsApp", "com.whatsapp.WhatsApp", "title") }
                    if title.contains("instagram") { return ("Instagram", "com.instagram.app", "title") }
                    if title.contains("telegram") { return ("Telegram", "com.telegram.Telegram", "title") }
                    if title.contains("messenger") { return ("Messenger", "com.facebook.Messenger", "title") }
                    if title.contains("gmail") { return ("Gmail", "com.google.Gmail", "title") }
                    if title.contains("chrome") { return ("Chrome", "com.google.chrome.ios", "title") }
                    if title.contains("mail") || title.contains("email") { return ("Mail", "com.apple.mobilemail", "title") }
                    if title.contains("safari") { return ("Safari", "com.apple.mobilesafari", "title") }
                    if title.contains("messages") { return ("Messages", "com.apple.MobileSMS", "title") }
                    if title.contains("twitter") || title.contains("tweetie") { return ("X", "com.atebits.Tweetie2", "title") }
                }
                
                // Enhanced userInfo-based detection with more sophisticated analysis
                if let userInfo = item.userInfo {
                    // Check all keys and values for app hints
                    for (key, value) in userInfo {
                        let keyStr = String(describing: key).lowercased()
                        let valueStr = String(describing: value).lowercased()
                        
                        // App-specific patterns in keys or values
                        if keyStr.contains("whatsapp") || valueStr.contains("whatsapp") {
                            return ("WhatsApp", "com.whatsapp.WhatsApp", "userInfo.key")
                        }
                        if keyStr.contains("instagram") || valueStr.contains("instagram") {
                            return ("Instagram", "com.instagram.app", "userInfo.key")
                        }
                        if keyStr.contains("telegram") || valueStr.contains("telegram") {
                            return ("Telegram", "com.telegram.Telegram", "userInfo.key")
                        }
                        if keyStr.contains("messenger") || valueStr.contains("messenger") {
                            return ("Messenger", "com.facebook.Messenger", "userInfo.key")
                        }
                        if keyStr.contains("gmail") || valueStr.contains("gmail") {
                            return ("Gmail", "com.google.Gmail", "userInfo.key")
                        }
                        if keyStr.contains("chrome") || valueStr.contains("chrome") {
                            return ("Chrome", "com.google.chrome.ios", "userInfo.key")
                        }
                        if keyStr.contains("mail") || keyStr.contains("email") || valueStr.contains("mail") || valueStr.contains("email") {
                            return ("Mail", "com.apple.mobilemail", "userInfo.key")
                        }
                        if keyStr.contains("safari") || valueStr.contains("safari") {
                            return ("Safari", "com.apple.mobilesafari", "userInfo.key")
                        }
                        if keyStr.contains("messages") || valueStr.contains("messages") {
                            return ("Messages", "com.apple.MobileSMS", "userInfo.key")
                        }
                        if keyStr.contains("tweetie") || keyStr.contains("twitter") || valueStr.contains("tweetie") || valueStr.contains("twitter") {
                            return ("X", "com.atebits.Tweetie2", "userInfo.key")
                        }
                        
                        // Check for bundle identifiers in the data
                        if valueStr.contains("com.whatsapp") {
                            return ("WhatsApp", "com.whatsapp.WhatsApp", "userInfo.bundle")
                        }
                        if valueStr.contains("com.instagram") {
                            return ("Instagram", "com.instagram.app", "userInfo.bundle")
                        }
                        if valueStr.contains("com.telegram") || valueStr.contains("ph.telegra") {
                            return ("Telegram", "com.telegram.Telegram", "userInfo.bundle")
                        }
                        if valueStr.contains("com.facebook.messenger") {
                            return ("Messenger", "com.facebook.Messenger", "userInfo.bundle")
                        }
                        if valueStr.contains("com.google.gmail") {
                            return ("Gmail", "com.google.Gmail", "userInfo.bundle")
                        }
                        if valueStr.contains("com.google.chrome.ios") {
                            return ("Chrome", "com.google.chrome.ios", "userInfo.bundle")
                        }
                        if valueStr.contains("com.apple.mobilemail") {
                            return ("Mail", "com.apple.mobilemail", "userInfo.bundle")
                        }
                        if valueStr.contains("com.apple.mobilesafari") {
                            return ("Safari", "com.apple.mobilesafari", "userInfo.bundle")
                        }
                        if valueStr.contains("com.apple.mobilesms") {
                            return ("Messages", "com.apple.MobileSMS", "userInfo.bundle")
                        }
                        if valueStr.contains("com.atebits.tweetie2") {
                            return ("X", "com.atebits.Tweetie2", "userInfo.bundle")
                        }
                    }
                }
                
                // Check attachment type identifiers for app-specific types
                if let attachments = item.attachments {
                    for attachment in attachments {
                        for typeId in attachment.registeredTypeIdentifiers {
                            let lowerTypeId = typeId.lowercased()
                            #if DEBUG
                            print("🔍 Resolver: Checking type identifier: \(typeId)")
                            #endif
                            
                            // App-specific type identifiers
                            if lowerTypeId.contains("whatsapp") {
                                return ("WhatsApp", "com.whatsapp.WhatsApp", "attachment.type")
                            }
                            if lowerTypeId.contains("instagram") {
                                return ("Instagram", "com.instagram.app", "attachment.type")
                            }
                            if lowerTypeId.contains("telegram") {
                                return ("Telegram", "com.telegram.Telegram", "attachment.type")
                            }
                            if lowerTypeId.contains("messenger") {
                                return ("Messenger", "com.facebook.Messenger", "attachment.type")
                            }
                            if lowerTypeId.contains("gmail") {
                                return ("Gmail", "com.google.Gmail", "attachment.type")
                            }
                            if lowerTypeId.contains("chrome") {
                                return ("Chrome", "com.google.chrome.ios", "attachment.type")
                            }
                            if lowerTypeId.contains("mail") || lowerTypeId.contains("email") {
                                return ("Mail", "com.apple.mobilemail", "attachment.type")
                            }
                        }
                    }
                }
            }
        }

        // 3) URL/text heuristics (safer, less aggressive to avoid false positives)
        let lowerText = (text ?? "").lowercased()
        let lowerURL  = (url ?? "").lowercased()

        // Instagram: explicit domain
        if lowerText.contains("instagram.com") || lowerURL.contains("instagram.com") || lowerText.contains("ig.com") {
            return ("Instagram", "com.instagram.app", "heuristic.url")
        }
        // Telegram: explicit domain or phrases
        if lowerText.contains("t.me/") || lowerURL.contains("t.me/") || lowerText.contains("telegram") {
            return ("Telegram", "com.telegram.Telegram", "heuristic.url")
        }
        // WhatsApp: explicit wa.me only (avoid over-detecting)
        if lowerText.contains("wa.me/") || lowerURL.contains("wa.me/") {
            return ("WhatsApp", "com.whatsapp.WhatsApp", "heuristic.url")
        }
        // Email-style signal
        if lowerText.contains("@") && (lowerText.contains(".com") || lowerText.contains(".org") || lowerText.contains(".net")) {
            return ("Mail", "com.apple.mobilemail", "heuristic.text")
        }
        // Generic URL => treat as browser share (Safari)
        if lowerText.contains("http") || lowerURL.contains("http") || lowerText.contains("www.") || lowerText.contains("//www.") {
            return ("Safari", "com.apple.mobilesafari", "heuristic.genericUrl")
        }

        return ("Unknown App", "unknown", "none")
    }
    
    // MARK: - Contact Detection
    
    /// Extract contact information from share metadata (best effort)
    static func extractContact(from extensionContext: NSExtensionContext?) -> String? {
        #if DEBUG
        print("🔍 ShareExtension: Starting contact extraction...")
        #endif
        
        // Try to get contact info from extension context
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            #if DEBUG
            print("❌ ShareExtension: No input items for contact extraction")
            #endif
            return nil
        }
        
        #if DEBUG
        print("🔍 ShareExtension: Found \(inputItems.count) input items for contact extraction")
        #endif
        
        for (itemIndex, item) in inputItems.enumerated() {
            #if DEBUG
            print("🔍 ShareExtension: Processing item \(itemIndex) for contact extraction")
            #endif
            // Check for contact-related attributes
            if let attributedTitle = item.attributedTitle {
                let title = attributedTitle.string.trimmingCharacters(in: .whitespacesAndNewlines)
                #if DEBUG
                print("🔍 ShareExtension: Found attributedTitle: '\(title)'")
                #endif
                if !title.isEmpty && title.count < 100 && !title.contains("http") {
                    #if DEBUG
                    print("✅ ShareExtension: Using attributedTitle as contact: '\(title)'")
                    #endif
                    return title
                }
            }
            
            // Check for userInfo that might contain contact info
            if let userInfo = item.userInfo {
                #if DEBUG
                print("🔍 ShareExtension: Found userInfo: \(userInfo)")
                #endif
                
                // Look for common keys that might contain contact information
                let contactKeys = ["contactName", "senderName", "from", "author", "contact", "name", "sender", "participant", "chat", "conversation"]
                for key in contactKeys {
                    if let contactValue = userInfo[key] as? String,
                       !contactValue.isEmpty && contactValue.count < 100 {
                        #if DEBUG
                        print("✅ ShareExtension: Found contact in userInfo[\(key)]: '\(contactValue)'")
                        #endif
                        return contactValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                // Also check for nested dictionaries that might contain contact info
                for (key, value) in userInfo {
                    if let dict = value as? [String: Any] {
                        for contactKey in contactKeys {
                            if let contactValue = dict[contactKey] as? String,
                               !contactValue.isEmpty && contactValue.count < 100 {
                                #if DEBUG
                                print("✅ ShareExtension: Found nested contact in userInfo[\(key)][\(contactKey)]: '\(contactValue)'")
                                #endif
                                return contactValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                    }
                }
            }
            
            // Check for attributed content that might contain contact info
            if let attributedContentText = item.attributedContentText {
                let content = attributedContentText.string.trimmingCharacters(in: .whitespacesAndNewlines)
                #if DEBUG
                print("🔍 ShareExtension: Analyzing attributed content for contact: '\(String(content.prefix(100)))'")
                #endif
                
                // For WhatsApp and similar apps, look for structured message patterns
                // Don't extract contact from simple single-word messages
                if content.count <= 20 && !content.contains(",") && !content.contains(":") && !content.contains("\n") {
                    #if DEBUG
                    print("🚫 ShareExtension: Skipping simple message as contact: '\(content)'")
                    #endif
                    continue // Skip simple messages that are likely content, not contact info
                }
                
                // Look for patterns that might indicate a contact name
                let lines = content.components(separatedBy: .newlines)
                for (lineIndex, line) in lines.prefix(3).enumerated() { // Check first few lines
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    #if DEBUG
                    print("🔍 ShareExtension: Checking line \(lineIndex): '\(trimmed)'")
                    #endif
                    
                    // Skip if it looks like a message content rather than contact name
                    if trimmed.count > 50 || 
                       trimmed.contains("http") || 
                       trimmed.contains(".") ||
                       trimmed.contains("@") ||
                       trimmed.contains("/") ||
                       trimmed.contains(":") {
                        #if DEBUG
                        print("🚫 ShareExtension: Skipping line (looks like content): '\(trimmed)'")
                        #endif
                        continue
                    }
                    
                    // Look for WhatsApp-style patterns: "ContactName, [timestamp]" or "ContactName:"
                    if trimmed.contains(",") || (trimmed.contains(":") && lineIndex == 0) {
                        // Extract contact name before comma or colon
                        let contactCandidate = trimmed.components(separatedBy: CharacterSet(charactersIn: ",:")).first?.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let candidate = contactCandidate, candidate.count >= 2 && candidate.count <= 30 {
                            #if DEBUG
                            print("✅ ShareExtension: Found contact from structured pattern: '\(candidate)'")
                            #endif
                            return candidate
                        }
                    }
                }
            }
        }
        
        #if DEBUG
        print("❌ ShareExtension: No contact found in extension context")
        #endif
        return nil
    }
    
    /// Extract WhatsApp contact from shared content structure
    /// Note: Due to iOS privacy restrictions, actual contact names are rarely available
    static func extractWhatsAppContact(from extensionContext: NSExtensionContext?) -> String? {
        #if DEBUG
        print("🔍 ShareExtension: Starting WhatsApp-specific contact extraction")
        print("⚠️  ShareExtension: Note - iOS limits contact access for privacy")
        #endif
        
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            #if DEBUG
            print("❌ ShareExtension: No input items for WhatsApp contact extraction")
            #endif
            return nil
        }
        
        for (itemIndex, item) in inputItems.enumerated() {
            #if DEBUG
            print("🔍 ShareExtension: Checking WhatsApp item \(itemIndex)")
            #endif
            
            // Check all possible sources for contact hints
            if let attributedTitle = item.attributedTitle {
                let title = attributedTitle.string.trimmingCharacters(in: .whitespacesAndNewlines)
                #if DEBUG
                print("🔍 ShareExtension: WhatsApp attributedTitle: '\(title)'")
                #endif
                
                // WhatsApp sometimes puts contact info in title, but often it's just "WhatsApp"
                if !title.isEmpty && title.count < 50 && !title.contains("http") && 
                   !title.lowercased().contains("whatsapp") && !title.contains("Share") {
                    #if DEBUG
                    print("✅ ShareExtension: Potential contact from WhatsApp title: '\(title)'")
                    #endif
                    return title
                }
            }
            
            // Check userInfo for any contact hints (though usually empty)
            if let userInfo = item.userInfo {
                #if DEBUG
                print("🔍 ShareExtension: WhatsApp userInfo: \(userInfo)")
                #endif
                
                // Look for any contact-related keys
                let contactKeys = ["contact", "sender", "from", "name", "title", "participant"]
                for key in contactKeys {
                    if let value = userInfo[key] as? String, !value.isEmpty, value.count < 50 {
                        #if DEBUG
                        print("✅ ShareExtension: Found contact in WhatsApp userInfo[\(key)]: '\(value)'")
                        #endif
                        return value
                    }
                }
            }
            
            // As last resort, try to parse content structure (very limited success)
            if let attributedContentText = item.attributedContentText {
                let content = attributedContentText.string
                #if DEBUG
                print("🔍 ShareExtension: WhatsApp content structure: '\(String(content.prefix(200)))'")
                #endif
                
                // Try to find structured patterns that might indicate contact
                let lines = content.components(separatedBy: .newlines)
                if lines.count >= 2 {
                    let firstLine = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Very specific pattern matching for WhatsApp exports
                    if firstLine.count >= 2 && firstLine.count <= 30 && 
                       !firstLine.contains("http") && !firstLine.contains(".") && !firstLine.contains("@") &&
                       lines.count > 1 {
                        #if DEBUG
                        print("🤔 ShareExtension: Potential contact from content structure: '\(firstLine)'")
                        #endif
                        return firstLine
                    }
                }
            }
        }
        
        #if DEBUG
        print("❌ ShareExtension: No WhatsApp contact found - iOS privacy limitations")
        #endif
        return nil
    }
    
    /// Extract contact from text content using patterns (for when context doesn't provide it)
    static func extractContactFromText(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        
        // Look for common messaging patterns
        for line in lines.prefix(3) { // Check first 3 lines
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Pattern: "ContactName, [timestamp] message"
            if let match = extractContactFromMessagingPattern(trimmed) {
                return match
            }
            
            // Pattern: "ContactName: message"
            if let match = extractContactFromColonPattern(trimmed) {
                return match
            }
            
            // Pattern: "ContactName at time message"
            if let match = extractContactFromTimePattern(trimmed) {
                return match
            }
        }
        
        return nil
    }
    
    /// Extract contact from "ContactName, [timestamp] message" pattern
    private static func extractContactFromMessagingPattern(_ text: String) -> String? {
        // Pattern: "Sidhanth, [Sep 15, 2025 at 3:32 PM] Haha"
        let pattern = "^([^,\\[]+),\\s*\\[.*?\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let contactRange = match.range(at: 1)
                if contactRange.location != NSNotFound {
                    let contact = (text as NSString).substring(with: contactRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    if contact.count >= 2 && contact.count <= 50 {
                        return contact
                    }
                }
            }
        }
        return nil
    }
    
    /// Extract contact from "ContactName: message" pattern
    private static func extractContactFromColonPattern(_ text: String) -> String? {
        // Pattern: "John: Hello there"
        let pattern = "^([^:]+):\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let contactRange = match.range(at: 1)
                if contactRange.location != NSNotFound {
                    let contact = (text as NSString).substring(with: contactRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    if contact.count >= 2 && contact.count <= 50 {
                        return contact
                    }
                }
            }
        }
        return nil
    }
    
    /// Extract contact from "ContactName at time message" pattern
    private static func extractContactFromTimePattern(_ text: String) -> String? {
        // Pattern: "Sarah at 2:30 PM: message"
        let pattern = "^([^\\d]+?)\\s+at\\s+\\d"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let contactRange = match.range(at: 1)
                if contactRange.location != NSNotFound {
                    let contact = (text as NSString).substring(with: contactRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    if contact.count >= 2 && contact.count <= 50 {
                        return contact
                    }
                }
            }
        }
        return nil
    }
    
    
    /// Extract time information from text content
    static func extractTimeFromText(_ text: String) -> Date? {
        let timePatterns = [
            // Time patterns like "2 PM", "14:30", "tomorrow at 3", etc.
            "\\b(\\d{1,2}):(\\d{2})\\s*(am|pm|AM|PM)?\\b",
            "\\b(\\d{1,2})\\s*(am|pm|AM|PM)\\b",
            "\\b(tomorrow|today|yesterday)\\s+(at|@)\\s+(\\d{1,2}):?(\\d{2})?\\s*(am|pm|AM|PM)?\\b",
            "\\b(at|@)\\s+(\\d{1,2}):?(\\d{2})?\\s*(am|pm|AM|PM)?\\b",
            "\\b(\\d{1,2})\\s*(o'clock|oclock)\\b"
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // Parse the matched time
                    let matchedText = (text as NSString).substring(with: match.range)
                    if let parsedTime = parseTimeFromString(matchedText) {
                        return parsedTime
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Parse time string to Date
    private static func parseTimeFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different time formats
        let timeFormats = [
            "h:mm a",      // 2:30 PM
            "h:mm",        // 2:30
            "h a",         // 2 PM
            "HH:mm",       // 14:30
            "h:mm a",      // 2:30 PM
        ]
        
        for format in timeFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                // If it's today's time, return it
                let calendar = Calendar.current
                let now = Date()
                let today = calendar.startOfDay(for: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
                
                if let hour = timeComponents.hour, let minute = timeComponents.minute {
                    var targetDate = today
                    targetDate = calendar.date(byAdding: .hour, value: hour, to: targetDate) ?? targetDate
                    targetDate = calendar.date(byAdding: .minute, value: minute, to: targetDate) ?? targetDate
                    
                    // If the time has passed today, schedule for tomorrow
                    if targetDate < now {
                        targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
                    }
                    
                    return targetDate
                }
            }
        }
        
        return nil
    }
    
    /// Clean message text by removing contact names and time references
    static func cleanMessageText(_ text: String, contactName: String?) -> String {
        var cleanedText = text
        
        #if DEBUG
        print("🧹 ShareExtension: Starting text cleaning...")
        print("   - Original text: '\(text)'")
        print("   - Contact name: '\(contactName ?? "nil")'")
        #endif
        
        // Remove common messaging patterns first
        let messagingPatterns = [
            // Pattern: "ContactName, [timestamp] message"
            "^\\s*[^,\\[]+,\\s*\\[.*?\\]\\s*",
            // Pattern: "ContactName: message"
            "^\\s*[^:]+:\\s*",
            // Pattern: "ContactName at time message"
            "^\\s*[^\\d]+?\\s+at\\s+\\d.*?:\\s*",
            // Pattern: "ContactName at time message" (without colon)
            "^\\s*[^\\d]+?\\s+at\\s+\\d.*?\\s+",
            // Pattern: "ContactName [timestamp] message"
            "^\\s*[^\\[]+\\s+\\[.*?\\]\\s*",
            // Pattern: "ContactName (timestamp) message"
            "^\\s*[^(]+\\s+\\(.*?\\)\\s*"
        ]
        
        for pattern in messagingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: cleanedText.utf16.count)
                cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
            }
        }
        
        // Remove contact name if it appears at the beginning (fallback)
        // But only if there's more content after the contact name
        if let contact = contactName {
            let contactPatterns = [
                "^\\s*\(NSRegularExpression.escapedPattern(for: contact))\\s*[,:]\\s*",  // Only if followed by comma/colon
                "^\\s*\(NSRegularExpression.escapedPattern(for: contact))\\s*\\[.*?\\]\\s*",  // Only if followed by timestamp
                "^\\s*\(NSRegularExpression.escapedPattern(for: contact))\\s*\\d{2}:\\d{2}\\s*",  // Only if followed by time
            ]
            
            for pattern in contactPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: cleanedText.utf16.count)
                    let beforeCleaning = cleanedText
                    cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
                    
                    // Safety check: if cleaning removed everything, revert to original
                    let trimmedAfterCleaning = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedAfterCleaning.isEmpty && !beforeCleaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        cleanedText = beforeCleaning
                        break // Don't try other patterns if this one removed everything
                    }
                }
            }
        }
        
        // Remove common greeting patterns that might be contact-related
        // Only remove greetings if they're followed by punctuation or more text
        let greetingPatterns = [
            "^\\s*(hi|hello|hey)\\s*[,:]\\s*",  // Only if followed by comma/colon
            "^\\s*(morning|mrng)\\s*[,:]\\s*",  // Only if followed by comma/colon
            "^\\s*(good morning|good afternoon|good evening)\\s*[,:]\\s*",  // Only complete phrases with punctuation
            "^\\s*(babe|dear|sweetie|honey)\\s*[,:]\\s*"  // Only if followed by comma/colon
        ]
        
        for pattern in greetingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: cleanedText.utf16.count)
                let beforeCleaning = cleanedText
                cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
                
                // Safety check: if cleaning removed everything, revert to original
                let trimmedAfterCleaning = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedAfterCleaning.isEmpty && !beforeCleaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    cleanedText = beforeCleaning
                    break // Don't try other patterns if this one removed everything
                }
            }
        }
        
        // Clean up extra whitespace and newlines
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove multiple consecutive newlines
        cleanedText = cleanedText.replacingOccurrences(of: "\\n\\s*\\n", with: "\\n", options: .regularExpression)
        
        #if DEBUG
        print("🧹 ShareExtension: Text cleaning completed")
        print("   - Final text: '\(cleanedText)'")
        print("   - Length change: \(text.count) → \(cleanedText.count)")
        #endif
        
        return cleanedText
    }
    
    // MARK: - Text Extraction
    
    /// Extract text content from extension context
    static func extractText(from extensionContext: NSExtensionContext?) async -> String? {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            print("❌ ShareExtension: No input items found")
            return nil
        }
        
        print("🔍 ShareExtension: Found \(inputItems.count) input items")
        
        for (itemIndex, item) in inputItems.enumerated() {
            print("🔍 ShareExtension: Processing input item \(itemIndex)")
            
            // Check attributed content first (most reliable for messaging apps)
            if let attributedContentText = item.attributedContentText {
                let text = attributedContentText.string
                print("🔍 ShareExtension: Found attributed content text (length: \(text.count)): \(String(text.prefix(100)))")
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return cleanText(text)
                }
            }
            
            // Check attributed title
            if let attributedTitle = item.attributedTitle {
                let text = attributedTitle.string
                print("🔍 ShareExtension: Found attributed title (length: \(text.count)): \(String(text.prefix(100)))")
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return cleanText(text)
                }
            }
            
            // Check attachments
            guard let attachments = item.attachments else { 
                print("🔍 ShareExtension: No attachments for item \(itemIndex)")
                continue 
            }
            
            print("🔍 ShareExtension: Found \(attachments.count) attachments for item \(itemIndex)")
            
            for (attachmentIndex, attachment) in attachments.enumerated() {
                print("🔍 ShareExtension: Processing attachment \(attachmentIndex)")
                print("🔍 ShareExtension: Available type identifiers: \(attachment.registeredTypeIdentifiers)")
                
                // Try all available type identifiers in order of preference
                let preferredTypes = [
                    UTType.plainText.identifier,
                    "public.plain-text",
                    "public.text",
                    UTType.utf8PlainText.identifier,
                    "public.utf8-plain-text",
                    UTType.rtf.identifier,
                    "public.rtf"
                ]
                
                // First try preferred types
                for typeId in preferredTypes {
                    if attachment.hasItemConformingToTypeIdentifier(typeId) {
                        do {
                            print("🔍 ShareExtension: Loading \(typeId)...")
                            let data = try await attachment.loadItem(forTypeIdentifier: typeId, options: nil)
                            
                            print("🔍 ShareExtension: Loaded data type: \(type(of: data))")
                            
                            var extractedText: String?
                            
                            if let text = data as? String {
                                extractedText = text
                            } else if let nsString = data as? NSString {
                                extractedText = nsString as String
                            } else if let attributedString = data as? NSAttributedString {
                                extractedText = attributedString.string
                            } else if let data = data as? Data {
                                // Try to decode as UTF-8 string
                                extractedText = String(data: data, encoding: .utf8)
                                if extractedText == nil {
                                    // Try other encodings
                                    extractedText = String(data: data, encoding: .utf16)
                                }
                            } else if let url = data as? URL {
                                extractedText = url.absoluteString
                            }
                            
                            if let text = extractedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                print("🔍 ShareExtension: Successfully extracted text (length: \(text.count)): \(String(text.prefix(100)))")
                                return cleanText(text)
                            } else {
                                print("🔍 ShareExtension: Extracted text was empty or nil for \(typeId)")
                            }
                        } catch {
                            print("❌ ShareExtension: Failed to load \(typeId): \(error)")
                        }
                    }
                }
                
                // Then try all other available types
                for typeIdentifier in attachment.registeredTypeIdentifiers {
                    // Skip if we already tried this type
                    if preferredTypes.contains(typeIdentifier) {
                        continue
                    }
                    
                    do {
                        print("🔍 ShareExtension: Trying fallback type \(typeIdentifier)...")
                        let data = try await attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil)
                        
                        print("🔍 ShareExtension: Loaded fallback data type: \(type(of: data))")
                        
                        var extractedText: String?
                        
                        if let text = data as? String {
                            extractedText = text
                        } else if let nsString = data as? NSString {
                            extractedText = nsString as String
                        } else if let attributedString = data as? NSAttributedString {
                            extractedText = attributedString.string
                        } else if let data = data as? Data {
                            // Try to decode as UTF-8 string
                            extractedText = String(data: data, encoding: .utf8)
                            if extractedText == nil {
                                // Try other encodings
                                extractedText = String(data: data, encoding: .utf16)
                            }
                        } else if let url = data as? URL {
                            extractedText = url.absoluteString
                        }
                        
                        if let text = extractedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("🔍 ShareExtension: Successfully extracted text from fallback (length: \(text.count)): \(String(text.prefix(100)))")
                            return cleanText(text)
                        }
                    } catch {
                        print("❌ ShareExtension: Failed to load fallback \(typeIdentifier): \(error)")
                    }
                }
            }
        }
        
        print("❌ ShareExtension: No text content found in any input item")
        return nil
    }
    
    // MARK: - Source Bundle Detection
    
    /// DEPRECATED - DO NOT USE. Use smartAppDetection instead.
    /// This method is disabled to prevent crashes from deprecated API.
    @available(*, deprecated, message: "Use smartAppDetection instead")
    static func getSourceBundleId(from extensionContext: NSExtensionContext?) -> String? {
        print("⚠️ DEPRECATED: getSourceBundleId called - returning nil to prevent crash")
        print("⚠️ Use smartAppDetection instead for app detection")
        
        // Return nil instead of accessing deprecated API to prevent crash
        return nil
    }
    /// DEPRECATED - DO NOT USE. Use smartAppDetection instead.
    /// This method is disabled to ensure single detection path.
    @available(*, deprecated, message: "Use smartAppDetection instead")
    static func detectSourceAppFromContent(_ text: String?, contact: String?) -> (appName: String, bundleId: String) {
        print("⚠️ DEPRECATED: detectSourceAppFromContent called - use smartAppDetection instead")
        return ("Unknown App", "unknown")
    }
    
    /// Test app detection with sample data for debugging
    static func testAppDetection() {
        #if DEBUG
        print("🧪 ShareExtension: Testing app detection patterns...")

        let testCases: [(String, String, String?)] = [
            ("Safari with URL", "Check out this link: https://example.com", nil),
            ("WhatsApp message", "John, [Sep 15, 2025 at 3:32 PM] Hello there", nil),
            ("Instagram post", "instagram.com/user/post", nil),
            ("Email content", "Subject: Meeting tomorrow\nFrom: john@company.com", nil),
            ("Telegram forward", "Forwarded from: Channel Name", nil),
            ("Simple text", "Good", nil)
        ]

        for (testName, text, url) in testCases {
            let smart = smartAppDetection(text: text, url: url, extensionContext: nil)
            let resolved = resolveSourceApp(extensionContext: nil, text: text, url: url)
            print("📱 Test: \(testName)")
            print("   - smartAppDetection: \(smart.appName) [\(smart.bundleId)]")
            print("   - resolveSourceApp:  \(resolved.appName) [\(resolved.bundleId)] confidence=\(resolved.confidence)")
            print("")
        }
        #endif
    }
    
    // MARK: - Validation
    
    /// Validate that the shared content is acceptable
    static func validateContent(_ text: String?) -> Bool {
        guard let text = text, !text.isEmpty else {
            return false
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must have some content and not be too short
        return trimmed.count >= 3 && trimmed.count <= 10000
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension ShareExtensionHelpers {
    
    /// Generate test content for debugging
    static func generateTestContent() -> (text: String, sourceApp: String, bundleId: String, contact: String?, url: String?) {
        let testTexts = [
            "Hey, can you follow up on the project status? https://example.com/project",
            "Meeting scheduled for tomorrow at 2 PM. Don't forget to prepare the presentation.",
            "Check out this article: https://techcrunch.com/article and let me know your thoughts",
            "Reminder: Call the client about the proposal by end of week"
        ]
        
        let testApps = [
            ("WhatsApp", "com.whatsapp.WhatsApp"),
            ("Messages", "com.apple.MobileSMS"),
            ("Slack", "com.tinyspeck.chatlyio"),
            ("Mail", "com.apple.mobilemail")
        ]
        
        let testContacts = ["John Doe", "Sarah Smith", "Mike Johnson", nil]
        
        let selectedText = testTexts.randomElement() ?? testTexts[0]
        let selectedApp = testApps.randomElement() ?? testApps[0]
        let selectedContact = testContacts.randomElement() ?? nil
        
        return (
            text: selectedText,
            sourceApp: selectedApp.0,
            bundleId: selectedApp.1,
            contact: selectedContact,
            url: extractURL(from: selectedText)
        )
    }
}
#endif

// NOTE: Detection is centralized via `resolveSourceApp(...)`. Do not add new ad-hoc detection methods.
