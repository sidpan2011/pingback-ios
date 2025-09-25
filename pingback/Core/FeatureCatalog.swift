import Foundation

/// Centralized feature catalog for Pingback v1
/// This is the single source of truth for all Free vs Pro features
struct FeatureCatalog {
    
    // MARK: - Free Tier Features
    static let freeFeatures: [Feature] = [
        .reminders(limit: 10, period: .monthly),
        .basicIntegrations([.messages, .mail, .safariShare, .whatsapp]),
        .defaultReminderType,
        .standardNotifications,
        .singleDeviceUse
    ]
    
    // MARK: - Pro Tier Features
    static let proFeatures: [Feature] = [
        .unlimitedReminders,
        .allIntegrations([.whatsapp, .telegram, .slack, .gmail, .outlook, .chromeShare]),
        .smartScheduling,
        .richNotifications,
        .themesAndCustomization,
        .prioritySupport,
        .earlyAccess
    ]
    
    // MARK: - All Features (for display purposes)
    static var allFeatures: [Feature] {
        return freeFeatures + proFeatures
    }
    
    // MARK: - Feature Descriptions for Paywall
    static let proFeatureDescriptions: [ProFeatureDescription] = [
        ProFeatureDescription(
            icon: "infinity.circle.fill",
            title: "Unlimited Reminders",
            description: "Create as many follow-up reminders as you need"
        ),
        ProFeatureDescription(
            icon: "app.connected.to.app.below.fill",
            title: "All Integrations",
            description: "WhatsApp, Telegram, Slack, Gmail, Outlook, Chrome share"
        ),
        ProFeatureDescription(
            icon: "clock.badge.checkmark.fill",
            title: "Smart Scheduling",
            description: "Custom snooze times and recurring reminders"
        ),
        ProFeatureDescription(
            icon: "bell.badge.fill",
            title: "Rich Notifications",
            description: "Actionable buttons, quick reply, and custom tones"
        ),
        ProFeatureDescription(
            icon: "paintbrush.fill",
            title: "Themes & Customization",
            description: "Personalize your Pingback experience"
        ),
        ProFeatureDescription(
            icon: "headphones.circle.fill",
            title: "Priority Support",
            description: "Get help faster when you need it most"
        ),
        ProFeatureDescription(
            icon: "star.circle.fill",
            title: "Early Access",
            description: "Be the first to try new integrations"
        )
    ]
    
    // MARK: - Compliance Text
    static let complianceText = "Auto-renewing. Cancel anytime in Settings."
    
    // MARK: - App Store Metadata
    static let appStoreProDescription = """
    • Unlimited reminders
    • All integrations: WhatsApp, Telegram, Slack, Gmail, Outlook, Chrome share
    • Smart scheduling: custom snooze times + recurring reminders
    • Rich notifications: actionable buttons / quick reply / custom tones
    • Themes & customization
    • Priority support + early access to new integrations
    """
}

// MARK: - Feature Definitions

enum Feature {
    // Free features
    case reminders(limit: Int, period: TimePeriod)
    case basicIntegrations([Integration])
    case defaultReminderType
    case standardNotifications
    case singleDeviceUse
    
    // Pro features
    case unlimitedReminders
    case allIntegrations([Integration])
    case smartScheduling
    case richNotifications
    case themesAndCustomization
    case prioritySupport
    case earlyAccess
}

enum TimePeriod {
    case monthly
    case yearly
    case daily
}

enum Integration: String, CaseIterable {
    case messages = "Messages"
    case mail = "Mail"
    case safariShare = "Safari Share"
    case whatsapp = "WhatsApp"
    case telegram = "Telegram"
    case slack = "Slack"
    case gmail = "Gmail"
    case outlook = "Outlook"
    case chromeShare = "Chrome Share"
}

struct ProFeatureDescription {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Feature Access Layer

/// Centralized feature access layer that checks entitlements against the feature catalog
@MainActor
class FeatureAccessLayer: ObservableObject {
    static let shared = FeatureAccessLayer()
    
    private let subscriptionManager: SubscriptionManager
    
    private init() {
        self.subscriptionManager = SubscriptionManager.shared
    }
    
    /// Check if a specific feature is available to the current user
    func isAvailable(_ feature: Feature) -> Bool {
        let isPro = subscriptionManager.isPro
        
        switch feature {
        // Free features - always available
        case .reminders, .basicIntegrations, .defaultReminderType, .standardNotifications, .singleDeviceUse:
            return true
            
        // Pro features - only available if user is Pro
        case .unlimitedReminders, .allIntegrations, .smartScheduling, .richNotifications, 
             .themesAndCustomization, .prioritySupport, .earlyAccess:
            return isPro
        }
    }
    
    /// Check if user can create a reminder (respects free tier limits)
    func canCreateReminder() -> Bool {
        if subscriptionManager.isPro {
            return true // Pro users have unlimited
        }
        
        // Free users are limited to 10 per month
        return subscriptionManager.followUpsRemaining > 0
    }
    
    /// Check if a specific integration is available
    func isIntegrationAvailable(_ integration: Integration) -> Bool {
        if subscriptionManager.isPro {
            return true // Pro users have all integrations
        }
        
        // Free users only have basic integrations
        switch integration {
        case .messages, .mail, .safariShare, .whatsapp:
            return true
        case .telegram, .slack, .gmail, .outlook, .chromeShare:
            return false
        }
    }
    
    /// Get available integrations for current user
    func getAvailableIntegrations() -> [Integration] {
        if subscriptionManager.isPro {
            return Integration.allCases
        } else {
            return [.messages, .mail, .safariShare, .whatsapp]
        }
    }
    
    /// Check if smart scheduling is available
    func isSmartSchedulingAvailable() -> Bool {
        return isAvailable(.smartScheduling)
    }
    
    /// Check if rich notifications are available
    func isRichNotificationsAvailable() -> Bool {
        return isAvailable(.richNotifications)
    }
    
    /// Check if themes and customization are available
    func isThemesAvailable() -> Bool {
        return isAvailable(.themesAndCustomization)
    }
    
    /// Get remaining reminders for free users
    func getRemainingReminders() -> Int {
        if subscriptionManager.isPro {
            return Int.max // Unlimited for Pro
        }
        return subscriptionManager.followUpsRemaining
    }
    
    /// Record a reminder creation (decrements free tier count)
    func recordReminderCreation() throws {
        if subscriptionManager.isPro {
            return // Pro users have unlimited
        }
        
        try subscriptionManager.decrementFollowUpCount()
    }
    
    /// Get feature usage info for display
    func getUsageInfo() -> FeatureUsageInfo? {
        if subscriptionManager.isPro {
            return nil // No limits for Pro
        }
        
        return FeatureUsageInfo(
            remindersUsed: 10 - subscriptionManager.followUpsRemaining,
            remindersLimit: 10,
            remainingReminders: subscriptionManager.followUpsRemaining
        )
    }
}

struct FeatureUsageInfo {
    let remindersUsed: Int
    let remindersLimit: Int
    let remainingReminders: Int
}
