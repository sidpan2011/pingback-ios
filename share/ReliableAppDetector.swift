//
// NOTE: iOS does not officially expose the source app to share extensions for privacy.
// We use best-effort signals (host bundle id via KVC, domains, UTIs, content hints). KVC may stop working or be disallowed;
// ensure this is not used to gate functionality. Logs are for QA only and should be disabled in production builds.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class ReliableAppDetector {
    
    /// Known bundle IDs and display names for popular source apps.
    private static let knownApps: [(ids: [String], name: String)] = [
        (ids: ["net.whatsapp.WhatsApp"], name: "WhatsApp"),
        (ids: ["com.burbn.instagram", "com.instagram.ios"], name: "Instagram"),
        (ids: ["ph.telegra.Telegraph", "org.telegram.Telegram", "ru.keepcoder.Telegram"], name: "Telegram"),
        (ids: ["com.apple.mobilesafari"], name: "Safari")
    ]

    /// Map a bundle identifier (exact/prefix-insensitive) to a known (name, id) pair if possible.
    private static func mapBundleToKnown(_ bundleId: String) -> (String, String)? {
        let lower = bundleId.lowercased()
        for entry in knownApps {
            for id in entry.ids {
                if lower == id.lowercased() || lower.hasPrefix(id.lowercased()) {
                    return (entry.name, id)
                }
            }
        }
        return nil
    }

    /// Attempt to read the host app's bundle identifier from the extension context using safe KVC.
    /// NOTE: This relies on private key paths that may stop working or be rejected if used to gate behavior.
    /// We only use this for best-effort attribution and never to alter functionality.
    private static func hostBundleID(from context: NSExtensionContext?) -> String? {
        guard let ctx = context else { return nil }
        
        // Use responds(to:) to safely check if the key exists before accessing it
        // This prevents NSUnknownKeyException crashes
        let candidateKeys = ["hostBundleID", "_hostBundleID", "NSExtensionHostBundleID"]
        
        for key in candidateKeys {
            // Check if the object responds to the key selector before trying to access it
            let selector = Selector(key)
            if (ctx as NSObject).responds(to: selector) {
                // Safe to call value(forKey:) since we confirmed it responds
                if let value = (ctx as NSObject).value(forKey: key) as? String, !value.isEmpty {
                    print("🔎 Host bundle id via KVC (\(key)): \(value)")
                    return value
                }
            } else {
                print("🔎 KVC key '\(key)' not available (expected)")
            }
        }
        return nil
    }
    
    static func detectSourceApp(extensionContext: NSExtensionContext?, text: String?, url: String?) -> (appName: String, bundleId: String, confidence: String) {
        
        print("🎯 RELIABLE APP DETECTOR: Starting priority-based detection")
        
        // PRIORITY 0: Try to read the host app bundle id directly (best-effort)
        if let hostId = hostBundleID(from: extensionContext) {
            if let mapped = mapBundleToKnown(hostId) {
                print("✅ DETECTED: \(mapped.0) via host bundle id \(hostId)")
                return (mapped.0, mapped.1, "host.bundleId")
            } else {
                print("ℹ️ Host bundle id present but unknown: \(hostId)")
            }
        } else {
            print("ℹ️ No host bundle id available via KVC.")
        }
        
        // PRIORITY 1: Hard evidence from context (highest confidence)
        print("🔍 Step 1: Scanning for hard evidence in extension context...")
        
        if let items = extensionContext?.inputItems as? [NSExtensionItem] {
            print("🔍 Analyzing \(items.count) extension items for hard evidence")
            
            for (index, item) in items.enumerated() {
                print("🔍 === ITEM \(index) ANALYSIS ===")
                
                // Check userInfo for explicit app tokens
                if let userInfo = item.userInfo {
                    print("🔍 UserInfo keys: \(Array(userInfo.keys))")
                    
                    for (key, value) in userInfo {
                        let keyStr = String(describing: key).lowercased()
                        let valueStr = String(describing: value).lowercased()
                        
                        // Look for explicit app mentions
                        if keyStr.contains("whatsapp") || valueStr.contains("whatsapp") {
                            print("✅ DETECTED: WhatsApp via userInfo explicit mention")
                            return ("WhatsApp", "net.whatsapp.WhatsApp", "userInfo.explicit")
                        }
                        if keyStr.contains("instagram") || valueStr.contains("instagram") {
                            print("✅ DETECTED: Instagram via userInfo explicit mention")
                            return ("Instagram", "com.burbn.instagram", "userInfo.explicit")
                        }
                        if keyStr.contains("telegram") || valueStr.contains("telegram") {
                            print("✅ DETECTED: Telegram via userInfo explicit mention")
                            return ("Telegram", "ph.telegra.Telegraph", "userInfo.explicit")
                        }
                        
                        // Look for bundle identifiers (robust contains/prefix)
                        if valueStr.contains("whatsapp") || valueStr.contains("net.whatsapp") {
                            print("✅ DETECTED: WhatsApp via bundle identifier")
                            return ("WhatsApp", "net.whatsapp.WhatsApp", "userInfo.bundleId")
                        }
                        if valueStr.contains("instagram") || valueStr.contains("com.burbn.instagram") {
                            print("✅ DETECTED: Instagram via bundle identifier")
                            return ("Instagram", "com.burbn.instagram", "userInfo.bundleId")
                        }
                        if valueStr.contains("telegraph") || valueStr.contains("telegram") || valueStr.contains("ph.telegra") {
                            print("✅ DETECTED: Telegram via bundle identifier")
                            return ("Telegram", "ph.telegra.Telegraph", "userInfo.bundleId")
                        }
                    }
                }
                
                // Check attachment type identifiers for app-unique UTIs
                if let attachments = item.attachments {
                    print("🔍 Checking \(attachments.count) attachments for app-specific UTIs")
                    for attachment in attachments {
                        let types = attachment.registeredTypeIdentifiers
                        print("🔍 Attachment types: \(types)")
                        
                        for typeId in types {
                            let lowerTypeId = typeId.lowercased()
                            if lowerTypeId.contains("whatsapp") {
                                print("✅ DETECTED: WhatsApp via attachment UTI")
                                return ("WhatsApp", "net.whatsapp.WhatsApp", "attachment.uti")
                            }
                            if lowerTypeId.contains("instagram") || lowerTypeId.contains("ig") {
                                print("✅ DETECTED: Instagram via attachment UTI")
                                return ("Instagram", "com.burbn.instagram", "attachment.uti")
                            }
                            if lowerTypeId.contains("telegram") || lowerTypeId.contains("telegraph") {
                                print("✅ DETECTED: Telegram via attachment UTI")
                                return ("Telegram", "ph.telegra.Telegraph", "attachment.uti")
                            }
                        }
                        if let name = attachment.suggestedName?.lowercased() {
                            if name.contains("whatsapp") { return ("WhatsApp", "net.whatsapp.WhatsApp", "attachment.name") }
                            if name.contains("instagram") || name.contains("ig") { return ("Instagram", "com.burbn.instagram", "attachment.name") }
                            if name.contains("telegram") || name.contains("telegraph") { return ("Telegram", "ph.telegra.Telegraph", "attachment.name") }
                        }
                    }
                }
            }
        }
        
        // PRIORITY 2: URL/domain evidence (high confidence)
        print("🔍 Step 2: Checking URL/domain evidence...")
        let lowerText = (text ?? "").lowercased()
        let lowerURL = (url ?? "").lowercased()

        // Prefer direct app domains
        if lowerURL.contains("instagram.com") || lowerURL.contains("instagr.am") || lowerText.contains("instagram.com") || lowerText.contains("instagr.am") {
            print("✅ DETECTED: Instagram via domain match")
            return ("Instagram", "com.burbn.instagram", "domain.instagram")
        }
        if lowerURL.contains("wa.me") || lowerURL.contains("whatsapp.com") || lowerText.contains("wa.me/") {
            print("✅ DETECTED: WhatsApp via domain match")
            return ("WhatsApp", "net.whatsapp.WhatsApp", "domain.whatsapp")
        }
        if lowerURL.contains("t.me") || lowerURL.contains("telegram.me") || lowerText.contains("t.me/") || lowerText.contains("telegram.me/") {
            print("✅ DETECTED: Telegram via domain match")
            return ("Telegram", "ph.telegra.Telegraph", "domain.telegram")
        }

        // Generic web link -> likely Safari
        if lowerURL.hasPrefix("http://") || lowerURL.hasPrefix("https://") {
            print("✅ DETECTED: Browser (Safari) via HTTP URL")
            return ("Safari", "com.apple.mobilesafari", "domain.browser")
        }
        
        // PRIORITY 3: Format patterns (medium confidence, very specific only)
        print("🔍 Step 3: Checking specific format patterns...")
        
        // Email pattern detection
        if lowerText.contains("@") && (lowerText.contains(".com") || lowerText.contains(".org") || lowerText.contains(".net")) {
            print("✅ DETECTED: Mail via email pattern")
            return ("Mail", "com.apple.mobilemail", "pattern.email")
        }
        
        // PRIORITY 4: Content keywords (low confidence, last resort)
        print("🔍 Step 4: Checking content keywords (last resort)...")
        
        // Very specific keyword detection only
        if lowerText.contains("via instagram") || lowerText.contains("shared from instagram") {
            print("✅ DETECTED: Instagram via content keyword")
            return ("Instagram", "com.burbn.instagram", "keyword.instagram")
        }
        if lowerText.contains("via whatsapp") || lowerText.contains("shared from whatsapp") {
            print("✅ DETECTED: WhatsApp via content keyword")
            return ("WhatsApp", "net.whatsapp.WhatsApp", "keyword.whatsapp")
        }
        
        // FALLBACK: Unknown
        print("❌ No app detection evidence found - marking as unknown")
        return ("Unknown", "unknown", "fallback")
    }
}
