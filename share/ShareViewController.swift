//
//  ShareViewController.swift
//  share
//
//  Created by Sidhanth Pandey on 15/09/25.
//

import UIKit
import Social
import Foundation
import MobileCoreServices

class ShareViewController: UIViewController {
    
    private var sharedText: String?
    private var sourceAppName: String = "Unknown App"
    private var sourceBundleId: String = "unknown"
    private var contactName: String?
    private var extractedURL: String?
    private var extractedTime: Date?
    private var isProcessing = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("🚀🚀🚀 SHARE EXTENSION INIT! ShareViewController created! 🚀🚀🚀")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("🚀🚀🚀 SHARE EXTENSION INIT! ShareViewController created from storyboard! 🚀🚀🚀")
        print("🚀 ShareExtension: Bundle ID: \(Bundle.main.bundleIdentifier ?? "UNKNOWN")")
        print("🚀 ShareExtension: Extension context available: \(extensionContext != nil)")
    }
    
    // UI Elements
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let successImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CRITICAL: Add immediate logging to see if extension loads
        print("🚀🚀🚀 SHARE EXTENSION LOADED! viewDidLoad called! 🚀🚀🚀")
        print("🚀 ShareExtension: Extension context: \(extensionContext != nil ? "EXISTS" : "NIL")")
        print("🚀 ShareExtension: Input items count: \(extensionContext?.inputItems.count ?? 0)")
        
        // Test if extension loads by checking logs
        
        setupUI()
        
        // Test UserDefaults access immediately
        testUserDefaultsAccess()
        
        // Add emergency fallback timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            if self.isProcessing {
                self.showError("Share extension took too long to respond. Please try again.")
            }
        }
        
        // Start processing immediately on background queue
        Task {
            do {
                try await self.processSharedContent()
            } catch {
                await MainActor.run {
                    self.showError(error)
                }
            }
        }
    }
    
    private func testUserDefaultsAccess() {
        #if DEBUG
        print("🧪 ShareExtension: Testing UserDefaults access...")
        
        // Test app detection patterns
        ShareExtensionHelpers.testAppDetection()
        
        // Test app group UserDefaults
        if let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") {
            print("✅ ShareExtension: App group UserDefaults accessible")
            
            // Write a test value
            let testKey = "share_extension_test"
            let testValue = "test_\(Date().timeIntervalSince1970)"
            appGroupDefaults.set(testValue, forKey: testKey)
            let syncResult = appGroupDefaults.synchronize()
            
            print("🧪 ShareExtension: Test write - sync result: \(syncResult)")
            
            // Try to read it back
            if let readValue = appGroupDefaults.string(forKey: testKey) {
                print("✅ ShareExtension: Test read successful: \(readValue)")
            } else {
                print("❌ ShareExtension: Test read failed")
            }
            
            // Clean up test value
            appGroupDefaults.removeObject(forKey: testKey)
            appGroupDefaults.synchronize()
        } else {
            print("❌ ShareExtension: App group UserDefaults NOT accessible")
        }
        
        // Test standard UserDefaults as fallback
        UserDefaults.standard.set("test", forKey: "share_extension_standard_test")
        if UserDefaults.standard.string(forKey: "share_extension_standard_test") != nil {
            print("✅ ShareExtension: Standard UserDefaults accessible")
            UserDefaults.standard.removeObject(forKey: "share_extension_standard_test")
        } else {
            print("❌ ShareExtension: Standard UserDefaults NOT accessible")
        }
        #endif
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Adding to Pingback..."
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = UIColor.label
        view.addSubview(statusLabel)
        
        // Success image
        successImageView.translatesAutoresizingMaskIntoConstraints = false
        successImageView.image = UIImage(systemName: "checkmark.circle.fill")
        successImageView.tintColor = UIColor.systemGreen
        successImageView.contentMode = .scaleAspectFit
        successImageView.alpha = 0
        view.addSubview(successImageView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            successImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            successImageView.widthAnchor.constraint(equalToConstant: 60),
            successImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func processSharedContent() async throws {
        #if DEBUG
        print("🚀 ShareExtension: Starting processSharedContent()")
        #endif
        
        // Set processing flag
        isProcessing = true
        
        // Update UI on main thread
        await MainActor.run {
            self.statusLabel.text = "Extracting content..."
        }
        
        // Extract text content on background thread
        sharedText = await ShareExtensionHelpers.extractText(from: extensionContext)
        
        #if DEBUG
        print("🔍 ShareExtension: Text extraction result:")
        if let text = sharedText {
            print("   - Extracted text length: \(text.count)")
            print("   - First 200 chars: \(String(text.prefix(200)))")
        } else {
            print("   - No text extracted")
        }
        #endif
        
        // Update UI
        await MainActor.run {
            self.statusLabel.text = "Analyzing content..."
        }
        
        // Extract URL and time from text
        if let text = sharedText {
            extractedURL = ShareExtensionHelpers.extractURL(from: text)
            extractedTime = ShareExtensionHelpers.extractTimeFromText(text)
        }
        
        // Update UI
        await MainActor.run {
            self.statusLabel.text = "Detecting source app..."
        }
        
        // Get source app info using modern smartAppDetection
        #if DEBUG
        print("🔍 ShareExtension: === STARTING APP DETECTION ===")
        #endif
        
        // Extract contact info first (needed for detection)
        contactName = ShareExtensionHelpers.extractContact(from: extensionContext)
        
        // If no contact found from context, try to extract from text content
        if contactName == nil, let text = sharedText {
            contactName = ShareExtensionHelpers.extractContactFromText(text)
        }
        
        // Use smartAppDetection for all app detection
        let detection = ShareExtensionHelpers.smartAppDetection(text: sharedText, url: extractedURL, extensionContext: extensionContext)
        sourceAppName = detection.appName
        sourceBundleId = detection.bundleId
        
        #if DEBUG
        print("✅ ShareExtension: Smart detection result:")
        print("   - App Name: \(sourceAppName)")
        print("   - Bundle ID: \(sourceBundleId)")
        #endif
        
        // Extract contact info if not already done
        if contactName == nil {
            contactName = ShareExtensionHelpers.extractContact(from: extensionContext)
            
            // If no contact found from context, try to extract from text content
            if contactName == nil, let text = sharedText {
                contactName = ShareExtensionHelpers.extractContactFromText(text)
            }
        }
        
        // If no contact found and we detected WhatsApp, try WhatsApp-specific extraction
        if contactName == nil && sourceAppName.lowercased().contains("whatsapp") {
            contactName = ShareExtensionHelpers.extractWhatsAppContact(from: extensionContext)
            #if DEBUG
            print("🔍 ShareExtension: WhatsApp-specific contact extraction result: '\(contactName ?? "nil")'")
            #endif
        }
        
        // If still no contact found, use a default based on the source app
        if contactName == nil {
            contactName = getDefaultContactName(for: sourceAppName)
            #if DEBUG
            print("🔍 ShareExtension: Using default contact name: '\(contactName ?? "nil")'")
            #endif
        }
        
        // Clean the message text by removing contact names and other metadata
        if let text = sharedText {
            sharedText = ShareExtensionHelpers.cleanMessageText(text, contactName: contactName)
        }
        
        #if DEBUG
        print("📥 ShareExtension: Loaded content")
        print("   - Text length: \(sharedText?.count ?? 0)")
        print("   - Source: \(sourceAppName)")
        print("   - Source Bundle ID: \(sourceBundleId)")
        print("   - Contact: \(contactName ?? "None")")
        print("   - URL: \(extractedURL ?? "None")")
        print("   - Time: \(extractedTime?.description ?? "None")")
        print("")
        print("🔍 ShareExtension: Final app detection result:")
        print("   - sourceAppName: '\(sourceAppName)'")
        print("   - sourceBundleId: '\(sourceBundleId)'")
        #endif
        
        // Update UI
        await MainActor.run {
            self.statusLabel.text = "Validating content..."
        }
        
        // Validate content
        #if DEBUG
        print("🔍 ShareExtension: About to validate content...")
        if let text = sharedText {
            print("   - Text to validate: '\(text)'")
            print("   - Text length: \(text.count)")
            print("   - Trimmed length: \(text.trimmingCharacters(in: .whitespacesAndNewlines).count)")
            print("   - Validation result: \(ShareExtensionHelpers.validateContent(text))")
        } else {
            print("   - No text to validate (sharedText is nil)")
        }
        #endif
        
        guard let text = sharedText, ShareExtensionHelpers.validateContent(text) else {
            #if DEBUG
            print("❌ ShareExtension: Content validation failed")
            #endif
            await MainActor.run {
                self.showError("No valid content found to share")
            }
            return
        }
        
        #if DEBUG
        print("✅ ShareExtension: Content validation passed, proceeding to create follow-up")
        #endif
        
        // Update UI before saving
        await MainActor.run {
            self.statusLabel.text = "Saving to Pingback..."
        }
        
        // Create the follow-up
        try await createFollowUp(text: text)
        
        // Clear processing flag
        isProcessing = false
        
        await MainActor.run {
            self.showSuccessAndDismiss()
        }
    }
    
    // MARK: - Private Methods
    
    /// Get default contact name based on source app
    private func getDefaultContactName(for appName: String) -> String {
        switch appName.lowercased() {
        case "whatsapp":
            return "WhatsApp Chat"
        case "telegram":
            return "Telegram Chat"
        case "messages", "sms":
            return "SMS Chat"
        case "mail", "gmail", "outlook":
            return "Email Thread"
        case "instagram":
            return "Instagram DM"
        case "facebook", "messenger":
            return "Messenger Chat"
        case "twitter":
            return "Twitter DM"
        case "linkedin":
            return "LinkedIn Message"
        case "slack":
            return "Slack Channel"
        case "discord":
            return "Discord Chat"
        default:
            return "Chat"
        }
    }
    
    
    private func createFollowUp(text: String) async throws {
        #if DEBUG
        print("🔍 ShareExtension: === CREATING FOLLOW-UP DATA ===")
        print("   - Final App Name: \(sourceAppName)")
        print("   - Final Bundle ID: \(sourceBundleId)")
        print("   - Final Contact: \(contactName ?? "nil")")
        print("   - Final URL: \(extractedURL ?? "nil")")
        print("   - Text snippet: \(String(text.prefix(100)))")
        #endif
        
        // Create follow-up data structure with content-based identifier for better deduplication
        let contentHash = createContentHash(text: text, contact: contactName ?? "", app: sourceAppName)
        
        // Use extracted time if available, otherwise default to 1 day from now
        let dueDate = extractedTime ?? Date().addingTimeInterval(24 * 60 * 60)
        
        let followUpData: [String: Any] = [
            "id": contentHash, // Use content hash as ID for better deduplication
            "sharedId": contentHash, // Use content hash for shared data identification
            "title": String(text.prefix(100)),
            "notes": text,
            "sourceApp": sourceAppName,
            "sourceBundleId": sourceBundleId,
            "contact": contactName ?? "",
            "url": extractedURL ?? "",
            "createdAt": Date().timeIntervalSince1970,
            "dueAt": dueDate.timeIntervalSince1970,
            "type": "DO",
            "status": "open",
            "isCompleted": false
        ]
        
        // Structured logging for SharePersist event
        let snippet = String(text.prefix(40))
        let contactString = contactName ?? "none"
        let urlString = extractedURL ?? "none"
        print("event=SharePersist id=\(contentHash) snippet=\(snippet) app=\(sourceAppName) bundle=\(sourceBundleId) url=\(urlString) contact=\(contactString)")
        
        #if DEBUG
        print("📦 ShareExtension: Saving follow-up data to shared defaults:")
        print("   - sourceApp: \(sourceAppName)")
        print("   - sourceBundleId: \(sourceBundleId)")
        #endif
        
        // Always try UserDefaults first as it's more reliable for share extensions
        var savedSuccessfully = false
        
        // Try UserDefaults with app group suite (async to avoid blocking)
        let userDefaults = UserDefaults(suiteName: "group.app.pingback.shared") ?? UserDefaults.standard
        
        #if DEBUG
        print("🔍 ShareExtension: Attempting to save to UserDefaults...")
        print("   - App group suite name: group.app.pingback.shared")
        print("   - UserDefaults instance: \(userDefaults)")
        print("   - Follow-up data to save: \(followUpData)")
        #endif
        
        do {
            // Load existing data
            var existingData: [[String: Any]] = []
            if let data = userDefaults.data(forKey: "shared_followups") {
                #if DEBUG
                print("🔍 ShareExtension: Found existing data in UserDefaults (\(data.count) bytes)")
                #endif
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    existingData = json
                    #if DEBUG
                    print("🔍 ShareExtension: Parsed \(existingData.count) existing follow-ups")
                    #endif
                } else {
                    #if DEBUG
                    print("❌ ShareExtension: Failed to parse existing JSON data")
                    #endif
                }
            } else {
                #if DEBUG
                print("🔍 ShareExtension: No existing data found in UserDefaults")
                #endif
            }
            
            // Add new follow-up
            existingData.append(followUpData)
            #if DEBUG
            print("🔍 ShareExtension: Added new follow-up, total count: \(existingData.count)")
            #endif
            
            // Save back to UserDefaults
            let jsonData = try JSONSerialization.data(withJSONObject: existingData, options: .prettyPrinted)
            #if DEBUG
            print("🔍 ShareExtension: Serialized data size: \(jsonData.count) bytes")
            #endif
            
            userDefaults.set(jsonData, forKey: "shared_followups")
            // Synchronous synchronize - share extensions need immediate persistence
            let syncResult = userDefaults.synchronize()
            
            #if DEBUG
            print("🔍 ShareExtension: UserDefaults.synchronize() result: \(syncResult)")
            
            // Verify the data was saved
            if let verifyData = userDefaults.data(forKey: "shared_followups") {
                print("✅ ShareExtension: Verified data exists after save (\(verifyData.count) bytes)")
                if let verifyJson = try? JSONSerialization.jsonObject(with: verifyData) as? [[String: Any]] {
                    print("✅ ShareExtension: Verified \(verifyJson.count) follow-ups in saved data")
                }
            } else {
                print("❌ ShareExtension: Data verification failed - no data found after save")
            }
            #endif
            
            savedSuccessfully = true
            
            #if DEBUG
            print("✅ ShareExtension: Follow-up saved to UserDefaults")
            print("   - Total follow-ups: \(existingData.count)")
            print("   - Sync result: \(syncResult)")
            #endif
        } catch {
            #if DEBUG
            print("❌ ShareExtension: UserDefaults save failed: \(error)")
            print("   - Error details: \(error.localizedDescription)")
            #endif
        }
        
        // Try app group container as secondary option
        if !savedSuccessfully {
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.pingback.shared") {
                do {
                    // Ensure the directory exists
                    try FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true, attributes: nil)
                    
                    let sharedDataURL = appGroupURL.appendingPathComponent("shared_followups.json")
                    
                    // Load existing data
                    var existingData: [[String: Any]] = []
                    if FileManager.default.fileExists(atPath: sharedDataURL.path),
                       let data = try? Data(contentsOf: sharedDataURL),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        existingData = json
                    }
                    
                    // Add new follow-up
                    existingData.append(followUpData)
                    
                    // Save back to file
                    let jsonData = try JSONSerialization.data(withJSONObject: existingData, options: .prettyPrinted)
                    try jsonData.write(to: sharedDataURL)
                    
                    savedSuccessfully = true
                    
                    #if DEBUG
                    print("✅ ShareExtension: Follow-up saved to app group container")
                    print("   - File: \(sharedDataURL)")
                    print("   - Total follow-ups: \(existingData.count)")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ ShareExtension: App group container save failed: \(error)")
                    #endif
                }
            } else {
                #if DEBUG
                print("❌ ShareExtension: App group container not accessible")
                #endif
            }
        }
        
        // Final fallback to standard UserDefaults
        if !savedSuccessfully {
            do {
                var existingData: [[String: Any]] = []
                if let data = UserDefaults.standard.data(forKey: "pingback_shared_followups"),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    existingData = json
                }
                
                existingData.append(followUpData)
                
                let jsonData = try JSONSerialization.data(withJSONObject: existingData, options: .prettyPrinted)
                UserDefaults.standard.set(jsonData, forKey: "pingback_shared_followups")
                // Synchronous synchronize - share extensions need immediate persistence
                UserDefaults.standard.synchronize()
                
                #if DEBUG
                print("✅ ShareExtension: Follow-up saved to standard UserDefaults fallback")
                print("   - Total follow-ups: \(existingData.count)")
                #endif
            } catch {
                #if DEBUG
                print("❌ ShareExtension: All save methods failed: \(error)")
                #endif
                throw error
            }
        }
        
        // If we reach here but didn't save successfully, throw an error
        if !savedSuccessfully {
            let error = NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save follow-up to any storage location"])
            #if DEBUG
            print("❌ ShareExtension: No storage method succeeded")
            #endif
            throw error
        }
    }
    
    private func showSuccessAndDismiss() {
        // Hide activity indicator and show success
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        
        statusLabel.text = "Added to Pingback!"
        statusLabel.textColor = UIColor.systemGreen
        
        // Show success image with animation
        UIView.animate(withDuration: 0.3) {
            self.successImageView.alpha = 1
            self.successImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.successImageView.transform = CGAffineTransform.identity
            }
        }
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func showError(_ error: Any) {
        isProcessing = false
        
        #if DEBUG
        print("❌ ShareExtension: Error creating follow-up: \(error)")
        #endif
        
        // Hide activity indicator
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        
        // Show specific error message
        let errorMessage: String
        if let localizedError = error as? LocalizedError {
            errorMessage = localizedError.localizedDescription
        } else {
            errorMessage = "Failed to add to Pingback"
        }
        
        statusLabel.text = errorMessage
        statusLabel.textColor = UIColor.systemRed
        
        // Show error image
        successImageView.image = UIImage(systemName: "xmark.circle.fill")
        successImageView.tintColor = UIColor.systemRed
        UIView.animate(withDuration: 0.3) {
            self.successImageView.alpha = 1
        }
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    /// Create a content hash for deduplication
    private func createContentHash(text: String, contact: String, app: String) -> String {
        let content = "\(text)|\(contact)|\(app)"
        return content.data(using: .utf8)?.base64EncodedString() ?? content
    }
    
}

// MARK: - Debug Support

#if DEBUG
extension ShareViewController {
    
    /// Add test content for debugging (can be called from debugger)
    func loadTestContent() {
        let testData = ShareExtensionHelpers.generateTestContent()
        
        sharedText = testData.text
        sourceAppName = testData.sourceApp
        sourceBundleId = testData.bundleId
        contactName = testData.contact
        extractedURL = testData.url
        
        // Update UI with test content
        statusLabel.text = "Test content loaded..."
        
        print("🧪 ShareExtension: Test content loaded")
    }
    
    /// Test the complete sharing flow with sample data
    func testSharingFlow() {
        print("🧪 ShareExtension: Starting test sharing flow...")
        
        // Load test content
        loadTestContent()
        
        // Process the test content
        Task {
            do {
                if let text = sharedText {
                    try await createFollowUp(text: text)
                    print("✅ ShareExtension: Test sharing flow completed successfully")
                } else {
                    print("❌ ShareExtension: No test text available")
                }
            } catch {
                print("❌ ShareExtension: Test sharing flow failed: \(error)")
            }
        }
    }
}
#endif
