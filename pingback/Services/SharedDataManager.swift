import Foundation
import CoreData

/// Manages shared data between the main app and share extension
class SharedDataManager {
    
    static let shared = SharedDataManager()
    private let appGroupIdentifier = "group.app.pingback.shared"
    private let sharedDataFileName = "shared_followups.json"
    
    // Processing state to prevent concurrent processing
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.pingback.shareddata.processing", qos: .userInitiated)
    
    // Track processed content to prevent duplicates based on content, not just ID
    private var processedContentHashes: Set<String> = []
    
    // Track last processing time to prevent too frequent processing
    private var lastProcessingTime: Date = Date.distantPast
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Process any pending shared follow-ups from the share extension
    func processPendingSharedFollowUps(using store: NewFollowUpStore) async {
        print("🔍 SharedDataManager: Starting to process pending shared follow-ups...")
        print("🔍 SharedDataManager: Current CoreData status - \(await store.followUps.count) follow-ups in store")
        
        // Check if we're already processing to prevent duplicates
        if isProcessing {
            print("🔍 SharedDataManager: Already processing shared data, skipping...")
            return
        }
        
        // Prevent too frequent processing (minimum 5 seconds between processing)
        let now = Date()
        if now.timeIntervalSince(lastProcessingTime) < 5.0 {
            print("🔍 SharedDataManager: Processing too frequent, skipping...")
            return
        }
        
        // Mark as processing
        isProcessing = true
        lastProcessingTime = now
        
        // Check all possible storage locations
        let sharedDataURL = getSharedDataURL()
        let hasFileData = sharedDataURL != nil && FileManager.default.fileExists(atPath: sharedDataURL!.path)
        let userDefaultsData = getSharedDataFromUserDefaults()
        let hasUserDefaultsData = !userDefaultsData.isEmpty
        let standardUserDefaultsData = getSharedDataFromStandardUserDefaults()
        let hasStandardUserDefaultsData = !standardUserDefaultsData.isEmpty
        
        print("🔍 SharedDataManager: Checking for shared data...")
        print("   - App Group file exists: \(hasFileData)")
        print("   - UserDefaults has data: \(hasUserDefaultsData) (\(userDefaultsData.count) items)")
        print("   - Standard UserDefaults has data: \(hasStandardUserDefaultsData) (\(standardUserDefaultsData.count) items)")
        
        // Log the actual data found
        if hasUserDefaultsData {
            print("📊 SharedDataManager: UserDefaults data details:")
            for (index, item) in userDefaultsData.enumerated() {
                print("   - Item \(index + 1): \(item)")
            }
        }
        
        if hasStandardUserDefaultsData {
            print("📊 SharedDataManager: Standard UserDefaults data details:")
            for (index, item) in standardUserDefaultsData.enumerated() {
                print("   - Item \(index + 1): \(item)")
            }
        }
        
        guard hasFileData || hasUserDefaultsData || hasStandardUserDefaultsData else {
            print("📂 SharedDataManager: No shared data found in any location")
            isProcessing = false
            return
        }
        
        do {
            var sharedFollowUps: [[String: Any]] = []
            
            // Try to read from app group file first (most reliable)
            if let sharedDataURL = sharedDataURL, FileManager.default.fileExists(atPath: sharedDataURL.path) {
                let data = try Data(contentsOf: sharedDataURL)
                sharedFollowUps = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                print("📂 SharedDataManager: Found \(sharedFollowUps.count) follow-ups in app group file")
            } else {
                // Only check UserDefaults if no file data
                let userDefaultsData = getSharedDataFromUserDefaults()
                if !userDefaultsData.isEmpty {
                    sharedFollowUps = userDefaultsData
                    print("📂 SharedDataManager: Found \(userDefaultsData.count) follow-ups in UserDefaults")
                } else {
                    // Only check standard UserDefaults as last resort
                    let standardUserDefaultsData = getSharedDataFromStandardUserDefaults()
                    if !standardUserDefaultsData.isEmpty {
                        sharedFollowUps = standardUserDefaultsData
                        print("📂 SharedDataManager: Found \(standardUserDefaultsData.count) follow-ups in standard UserDefaults")
                    }
                }
            }
            
            if sharedFollowUps.isEmpty {
                print("📂 SharedDataManager: No shared follow-ups to process")
                isProcessing = false
                return
            }
            
            print("📥 SharedDataManager: Processing \(sharedFollowUps.count) total shared follow-ups")
            
            // Convert each shared follow-up to a FollowUp object and save
            for (index, sharedData) in sharedFollowUps.enumerated() {
                print("🔄 SharedDataManager: Processing shared data \(index + 1)/\(sharedFollowUps.count)")
                print("   - Raw data: \(sharedData)")
                
                if let (text, type, contact, app, url) = extractDataForStore(sharedData) {
                    // Create content hash for deduplication based on content, not ID
                    let contentHash = createContentHash(text: text, contact: contact, app: app.rawValue)
                    
                    // Check for duplicate content
                    if processedContentHashes.contains(contentHash) {
                        print("🔄 SharedDataManager: Skipping duplicate content: \(String(text.prefix(50)))")
                        continue
                    }
                    
                    // Check if this content already exists in Core Data
                    if await isContentAlreadyInStore(store: store, text: text, contact: contact, app: app) {
                        print("🔄 SharedDataManager: Content already exists in store, skipping: \(String(text.prefix(50)))")
                        processedContentHashes.insert(contentHash)
                        continue
                    }
                    
                    print("🔄 SharedDataManager: About to call store.add() with:")
                    print("   - Text: \(String(text.prefix(100)))")
                    print("   - Type: \(type)")
                    print("   - Contact: \(contact)")
                    print("   - App: \(app)")
                    
                    do {
                        // Pass the URL if it exists and is not empty
                        let urlToPass = url.isEmpty ? nil : url
                        try await store.add(from: text, type: type, contact: contact, app: app, url: urlToPass)
                        processedContentHashes.insert(contentHash)
                        print("✅ SharedDataManager: Successfully called store.add() for: \(String(text.prefix(50)))")
                        if let passedUrl = urlToPass {
                            print("   - URL passed: \(passedUrl)")
                        }
                    } catch {
                        print("❌ SharedDataManager: Error calling store.add(): \(error)")
                        throw error
                    }
                } else {
                    print("❌ SharedDataManager: Failed to extract data from: \(sharedData)")
                }
            }
            
            // Clear all storage locations after successful processing
            clearSharedDataAfterProcessing()
            
            print("🧹 SharedDataManager: Cleared all shared data after processing")
            print("🔍 SharedDataManager: Final CoreData status - \(await store.followUps.count) follow-ups in store")
            
            // Log all current follow-ups for debugging
            print("📊 SharedDataManager: Current follow-ups in store:")
            for (index, followUp) in await store.followUps.enumerated() {
                print("   - FollowUp \(index + 1):")
                print("     - ID: \(followUp.id)")
                print("     - Snippet: \(String(followUp.snippet.prefix(50)))")
                print("     - Contact: \(followUp.contactLabel)")
                print("     - App: \(followUp.app.rawValue)")
                print("     - Type: \(followUp.type.rawValue)")
                print("     - Created: \(followUp.createdAt)")
            }
            
        } catch {
            print("❌ SharedDataManager: Error processing shared data: \(error)")
        }
        
        // Always clear the processing flag
        isProcessing = false
        print("🔍 SharedDataManager: Cleared processing flag")
    }
    
    /// Check if there are pending shared follow-ups
    func hasPendingSharedFollowUps() -> Bool {
        let sharedDataURL = getSharedDataURL()
        let hasFileData = sharedDataURL != nil && FileManager.default.fileExists(atPath: sharedDataURL!.path)
        let hasUserDefaultsData = !getSharedDataFromUserDefaults().isEmpty
        let hasStandardUserDefaultsData = !getSharedDataFromStandardUserDefaults().isEmpty
        
        return hasFileData || hasUserDefaultsData || hasStandardUserDefaultsData
    }
    
    /// Clear processed content hashes (call this when app starts fresh)
    func clearProcessedContentHashes() {
        processedContentHashes.removeAll()
        print("🔍 SharedDataManager: Cleared processed content hashes")
    }
    
    /// Clear all shared data from all storage locations (emergency cleanup)
    func clearAllSharedData() {
        print("🧹 SharedDataManager: Clearing all shared data from all locations...")
        
        // Clear UserDefaults
        clearSharedDataFromUserDefaults()
        clearSharedDataFromStandardUserDefaults()
        
        // Clear app group file
        do {
            try clearSharedData()
            print("🧹 SharedDataManager: Cleared app group file")
        } catch {
            print("❌ SharedDataManager: Error clearing app group file: \(error)")
        }
        
        // Clear processed hashes
        clearProcessedContentHashes()
        
        print("🧹 SharedDataManager: All shared data cleared")
    }
    
    /// Clear shared data only after successful processing (call this after processing is complete)
    func clearSharedDataAfterProcessing() {
        print("🧹 SharedDataManager: Clearing shared data after successful processing...")
        
        // Clear UserDefaults
        clearSharedDataFromUserDefaults()
        clearSharedDataFromStandardUserDefaults()
        
        // Clear app group file
        do {
            try clearSharedData()
            print("🧹 SharedDataManager: Cleared shared data after processing")
        } catch {
            print("❌ SharedDataManager: Error clearing shared data after processing: \(error)")
        }
    }
    
    /// Clean up duplicate follow-ups (call this to remove existing duplicates)
    func cleanupDuplicateFollowUps(using store: NewFollowUpStore) async {
        print("🧹 SharedDataManager: Starting cleanup of duplicate follow-ups...")
        
        let followUps = await store.followUps
        var seenContentHashes: Set<String> = []
        var duplicatesToRemove: [UUID] = []
        
        for followUp in followUps {
            let contentHash = createContentHash(text: followUp.snippet, contact: followUp.contactLabel, app: followUp.app.rawValue)
            if seenContentHashes.contains(contentHash) {
                duplicatesToRemove.append(followUp.id)
                print("🧹 SharedDataManager: Found duplicate follow-up: \(String(followUp.snippet.prefix(50)))")
            } else {
                seenContentHashes.insert(contentHash)
            }
        }
        
        print("🧹 SharedDataManager: Found \(duplicatesToRemove.count) duplicate follow-ups to remove")
        
        // Remove duplicates
        for duplicateId in duplicatesToRemove {
            do {
                // Find the follow-up by ID and delete it
                if let followUpToDelete = followUps.first(where: { $0.id == duplicateId }) {
                    try await store.delete(followUpToDelete)
                    print("🧹 SharedDataManager: Removed duplicate follow-up: \(duplicateId)")
                }
            } catch {
                print("❌ SharedDataManager: Error removing duplicate follow-up: \(error)")
            }
        }
        
        print("🧹 SharedDataManager: Cleanup completed")
    }
    
    // MARK: - Private Methods
    
    private func getSharedDataURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(sharedDataFileName)
    }
    
    private func getSharedDataFromUserDefaults() -> [[String: Any]] {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
        
        guard let data = userDefaults.data(forKey: "shared_followups"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("📂 SharedDataManager: No UserDefaults data found for key 'shared_followups'")
            return []
        }
        
        print("📂 SharedDataManager: Found \(json.count) items in UserDefaults")
        return json
    }
    
    private func getSharedDataFromStandardUserDefaults() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: "pingback_shared_followups"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return json
    }
    
    private func clearSharedDataFromUserDefaults() {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
        userDefaults.removeObject(forKey: "shared_followups")
        userDefaults.synchronize()
    }
    
    private func clearSharedDataFromStandardUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "pingback_shared_followups")
        UserDefaults.standard.synchronize()
    }
    
    private func extractDataForStore(_ data: [String: Any]) -> (text: String, type: FollowType, contact: String, app: AppKind, url: String)? {
        print("🔍 SharedDataManager: Extracting data from: \(data)")
        
        guard let notes = data["notes"] as? String,
              let type = data["type"] as? String else {
            print("❌ SharedDataManager: Invalid shared data format - missing notes or type")
            print("   - notes: \(data["notes"] ?? "nil")")
            print("   - type: \(data["type"] ?? "nil")")
            return nil
        }
        
        // Extract optional fields
        let sourceApp = data["sourceApp"] as? String ?? ""
        let sourceBundleId = data["sourceBundleId"] as? String ?? ""
        let contact = data["contact"] as? String ?? ""
        let url = data["url"] as? String ?? ""
        
        print("🔍 SharedDataManager: === PROCESSING SHARED DATA ===")
        print("   - notes: \(String(notes.prefix(50)))")
        print("   - type: \(type)")
        print("   - sourceApp: \(sourceApp)")
        print("   - sourceBundleId: \(sourceBundleId)")
        print("   - contact: \(contact)")
        print("   - url: \(url)")
        
        // Map source app to AppKind
        print("🔍 SharedDataManager: === MAPPING TO APPKIND ===")
        print("   - Input sourceApp: '\(sourceApp)'")
        print("   - Input bundleId: '\(sourceBundleId)'")
        let appKind = mapSourceAppToAppKind(sourceApp, bundleId: sourceBundleId)
        print("   - Mapped AppKind: \(appKind)")
        print("   - AppKind raw value: \(appKind.rawValue)")
        
        print("🔍 SharedDataManager: App mapping debug:")
        print("   - sourceApp: '\(sourceApp)'")
        print("   - sourceBundleId: '\(sourceBundleId)'")
        print("   - mapped AppKind: \(appKind.rawValue)")
        
        // Use the original notes as the text content (don't add contact info to message)
        let enhancedText = notes
        
        let followType = FollowType(rawValue: type) ?? .doIt
        let finalContact = contact.isEmpty ? "Unknown" : contact
        
        print("🔍 SharedDataManager: Final extracted data:")
        print("   - enhancedText: \(String(enhancedText.prefix(50)))")
        print("   - followType: \(followType)")
        print("   - finalContact: \(finalContact)")
        print("   - appKind: \(appKind)")
        
        return (
            text: enhancedText,
            type: followType,
            contact: finalContact,
            app: appKind,
            url: url
        )
    }
    
    private func mapSourceAppToAppKind(_ sourceApp: String, bundleId: String) -> AppKind {
        print("🔍 SharedDataManager: === PRECISE BUNDLE ID MAPPING ===")
        print("   - sourceApp: '\(sourceApp)'")
        print("   - bundleId: '\(bundleId)'")
        
        // Use exact bundle ID matching first (most reliable)
        switch bundleId {
        case "com.whatsapp.WhatsApp":
            print("✅ SharedDataManager: Exact match - WhatsApp")
            return .whatsapp
        case "com.telegram.Telegram":
            print("✅ SharedDataManager: Exact match - Telegram")
            return .telegram
        case "com.instagram.app":
            print("✅ SharedDataManager: Exact match - Instagram")
            return .instagram
        case "com.apple.MobileSMS":
            print("✅ SharedDataManager: Exact match - SMS")
            return .sms
        case "com.apple.mobilemail", "com.google.Gmail", "com.microsoft.Office.Outlook":
            print("✅ SharedDataManager: Exact match - Email")
            return .email
        default:
            break
        }
        
        // Fallback to app name matching for edge cases
        let lowerSourceApp = sourceApp.lowercased()
        let lowerBundleId = bundleId.lowercased()
        
        if lowerSourceApp.contains("whatsapp") || lowerBundleId.contains("whatsapp") {
            print("✅ SharedDataManager: Fallback match - WhatsApp")
            return .whatsapp
        }
        if lowerSourceApp.contains("telegram") || lowerBundleId.contains("telegram") {
            print("✅ SharedDataManager: Fallback match - Telegram")
            return .telegram
        }
        if lowerSourceApp.contains("instagram") || lowerBundleId.contains("instagram") {
            print("✅ SharedDataManager: Fallback match - Instagram")
            return .instagram
        }
        if lowerSourceApp.contains("message") || lowerSourceApp.contains("sms") || 
           lowerBundleId.contains("mobilesms") {
            print("✅ SharedDataManager: Fallback match - SMS")
            return .sms
        }
        if lowerSourceApp.contains("mail") || lowerSourceApp.contains("email") || 
           lowerBundleId.contains("mail") || lowerBundleId.contains("gmail") || 
           lowerBundleId.contains("outlook") {
            print("✅ SharedDataManager: Fallback match - Email")
            return .email
        }
        
        print("❌ SharedDataManager: No match found for '\(sourceApp)' / '\(bundleId)' - defaulting to 'other'")
        return .other
    }
    
    private func clearSharedData() throws {
        guard let sharedDataURL = getSharedDataURL() else {
            throw NSError(domain: "SharedDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access shared data URL"])
        }
        
        // Remove the file
        try FileManager.default.removeItem(at: sharedDataURL)
    }
    
    /// Create a content hash for deduplication
    private func createContentHash(text: String, contact: String, app: String) -> String {
        let content = "\(text)|\(contact)|\(app)"
        return content.data(using: .utf8)?.base64EncodedString() ?? content
    }
    
    /// Check if content already exists in the store
    private func isContentAlreadyInStore(store: NewFollowUpStore, text: String, contact: String, app: AppKind) async -> Bool {
        let followUps = await store.followUps
        return followUps.contains { followUp in
            followUp.snippet.trimmingCharacters(in: .whitespacesAndNewlines) == text.trimmingCharacters(in: .whitespacesAndNewlines) &&
            followUp.contactLabel == contact &&
            followUp.app == app
        }
    }
}

// MARK: - App Lifecycle Integration

extension SharedDataManager {
    
    /// Call this when the app becomes active to process any pending shared data
    func processOnAppBecomeActive(using store: NewFollowUpStore) {
        Task {
            await processPendingSharedFollowUps(using: store)
        }
    }
    
    /// Call this when the app launches to process any pending shared data
    func processOnAppLaunch(using store: NewFollowUpStore) {
        Task {
            await processPendingSharedFollowUps(using: store)
        }
    }
}
