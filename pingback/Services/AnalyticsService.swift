import Foundation
import os.log

/// Minimal analytics service for tracking key events
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let logger = Logger(subsystem: "app.pingback", category: "analytics")
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func track(_ event: AnalyticsEvent) {
        let eventData = [
            "event": event.name,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "properties": event.properties
        ] as [String: Any]
        
        // Log to console for debugging
        logger.info("📊 Analytics: \(event.name) - \(event.properties)")
        
        // In a production app, you would send this to your analytics service
        // For now, we'll just store locally for debugging
        storeEventLocally(eventData)
    }
    
    // MARK: - Convenience Methods
    
    func trackFollowUpCreated(app: AppKind, cadence: Cadence, hasTemplate: Bool) {
        track(.followUpCreated(
            app: app.rawValue,
            cadence: cadence.rawValue,
            hasTemplate: hasTemplate
        ))
    }
    
    func trackNotificationFired(followUpId: UUID, app: AppKind) {
        track(.notificationFired(
            followUpId: followUpId.uuidString,
            app: app.rawValue
        ))
    }
    
    func trackChatOpened(app: AppKind, source: String) {
        track(.chatOpened(
            app: app.rawValue,
            source: source
        ))
    }
    
    func trackFollowUpSnoozed(followUpId: UUID, source: String) {
        track(.followUpSnoozed(
            followUpId: followUpId.uuidString,
            source: source
        ))
    }
    
    func trackFollowUpCompleted(followUpId: UUID, hadCadence: Bool, source: String) {
        track(.followUpCompleted(
            followUpId: followUpId.uuidString,
            hadCadence: hadCadence,
            source: source
        ))
    }
    
    func trackShareExtensionUsed(sourceApp: String, contentType: String) {
        track(.shareExtensionUsed(
            sourceApp: sourceApp,
            contentType: contentType
        ))
    }
    
    func trackTemplateUsed(templateId: UUID, templateName: String) {
        track(.templateUsed(
            templateId: templateId.uuidString,
            templateName: templateName
        ))
    }
    
    func trackSettingsChanged(setting: String, value: String) {
        track(.settingsChanged(
            setting: setting,
            value: value
        ))
    }
    
    // MARK: - Local Storage (for debugging)
    
    private func storeEventLocally(_ eventData: [String: Any]) {
        // Store in UserDefaults for debugging
        var events = UserDefaults.standard.array(forKey: "analytics_events") as? [[String: Any]] ?? []
        events.append(eventData)
        
        // Keep only last 100 events
        if events.count > 100 {
            events = Array(events.suffix(100))
        }
        
        UserDefaults.standard.set(events, forKey: "analytics_events")
    }
    
    // MARK: - Debug Methods
    
    func getStoredEvents() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "analytics_events") as? [[String: Any]] ?? []
    }
    
    func clearStoredEvents() {
        UserDefaults.standard.removeObject(forKey: "analytics_events")
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent {
    case followUpCreated(app: String, cadence: String, hasTemplate: Bool)
    case notificationFired(followUpId: String, app: String)
    case chatOpened(app: String, source: String)
    case followUpSnoozed(followUpId: String, source: String)
    case followUpCompleted(followUpId: String, hadCadence: Bool, source: String)
    case shareExtensionUsed(sourceApp: String, contentType: String)
    case templateUsed(templateId: String, templateName: String)
    case settingsChanged(setting: String, value: String)
    
    var name: String {
        switch self {
        case .followUpCreated: return "follow_up_created"
        case .notificationFired: return "notification_fired"
        case .chatOpened: return "chat_opened"
        case .followUpSnoozed: return "follow_up_snoozed"
        case .followUpCompleted: return "follow_up_completed"
        case .shareExtensionUsed: return "share_extension_used"
        case .templateUsed: return "template_used"
        case .settingsChanged: return "settings_changed"
        }
    }
    
    var properties: [String: Any] {
        switch self {
        case .followUpCreated(let app, let cadence, let hasTemplate):
            return [
                "app": app,
                "cadence": cadence,
                "has_template": hasTemplate
            ]
        case .notificationFired(let followUpId, let app):
            return [
                "follow_up_id": followUpId,
                "app": app
            ]
        case .chatOpened(let app, let source):
            return [
                "app": app,
                "source": source
            ]
        case .followUpSnoozed(let followUpId, let source):
            return [
                "follow_up_id": followUpId,
                "source": source
            ]
        case .followUpCompleted(let followUpId, let hadCadence, let source):
            return [
                "follow_up_id": followUpId,
                "had_cadence": hadCadence,
                "source": source
            ]
        case .shareExtensionUsed(let sourceApp, let contentType):
            return [
                "source_app": sourceApp,
                "content_type": contentType
            ]
        case .templateUsed(let templateId, let templateName):
            return [
                "template_id": templateId,
                "template_name": templateName
            ]
        case .settingsChanged(let setting, let value):
            return [
                "setting": setting,
                "value": value
            ]
        }
    }
}
