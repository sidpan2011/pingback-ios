import Foundation
import UserNotifications
import UIKit

/// Service for scheduling and managing follow-up notifications
class NotificationService: NSObject {
    static let shared = NotificationService()
    
    // Notification categories and actions
    private let followUpCategoryId = "FOLLOW_UP_REMINDER"
    private let openChatActionId = "OPEN_CHAT"
    private let snoozeDayActionId = "SNOOZE_DAY"
    private let markDoneActionId = "MARK_DONE"
    
    override init() {
        super.init()
        setupNotificationCategories()
    }
    
    // MARK: - Setup
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("📱 Notification permission granted: \(granted)")
            return granted
        } catch {
            print("❌ Failed to request notification permission: \(error)")
            return false
        }
    }
    
    private func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Create actions
        let openChatAction = UNNotificationAction(
            identifier: openChatActionId,
            title: "Open Chat",
            options: [.foreground]
        )
        
        let snoozeDayAction = UNNotificationAction(
            identifier: snoozeDayActionId,
            title: "Snooze 1 Day",
            options: []
        )
        
        let markDoneAction = UNNotificationAction(
            identifier: markDoneActionId,
            title: "Mark Done",
            options: []
        )
        
        // Create category
        let followUpCategory = UNNotificationCategory(
            identifier: followUpCategoryId,
            actions: [openChatAction, snoozeDayAction, markDoneAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([followUpCategory])
    }
    
    // MARK: - Scheduling
    
    func scheduleNotification(for followUp: FollowUp) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Follow up with \(followUp.person.displayName)"
        content.body = followUp.note
        content.sound = .default
        content.categoryIdentifier = followUpCategoryId
        
        // Add follow-up data to userInfo
        content.userInfo = [
            "followUpId": followUp.id.uuidString,
            "personName": followUp.person.displayName,
            "appType": followUp.appType.rawValue,
            "note": followUp.note,
            "hasPhoneNumber": followUp.person.primaryPhoneNumber != nil,
            "hasTelegramUsername": followUp.person.telegramUsername != nil,
            "hasSlackLink": followUp.person.slackLink != nil
        ]
        
        // Create trigger based on cadence
        let trigger: UNNotificationTrigger
        
        if followUp.cadence == .weekly {
            // Use calendar trigger for weekly repeats
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: followUp.dueAt)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        } else {
            // One-time notification
            let timeInterval = max(1, followUp.dueAt.timeIntervalSinceNow)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        }
        
        // Create request
        let request = UNNotificationRequest(
            identifier: followUp.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        try await center.add(request)
        
        print("📅 Scheduled notification for follow-up: \(followUp.id)")
        print("   - Due at: \(followUp.dueAt)")
        print("   - Cadence: \(followUp.cadence.label)")
    }
    
    func cancelNotification(for followUpId: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [followUpId.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [followUpId.uuidString])
        
        print("🗑️ Cancelled notification for follow-up: \(followUpId)")
    }
    
    func rescheduleNotification(for followUp: FollowUp) async throws {
        // Cancel existing notification
        await cancelNotification(for: followUp.id)
        
        // Schedule new notification
        try await scheduleNotification(for: followUp)
    }
    
    // MARK: - Quiet Hours
    
    func isQuietHours() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Default quiet hours: 22:00 - 07:00
        // TODO: Make this configurable in settings
        return hour >= 22 || hour < 7
    }
    
    // MARK: - Badge Management
    
    @MainActor
    func updateBadgeCount() async {
        // Count open follow-ups that are due or overdue
        let followUpStore = FollowUpStore.shared
        let openFollowUps = followUpStore.followUps.filter { $0.status == .open }
        let dueFollowUps = openFollowUps.filter { $0.dueAt <= Date() }
        
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = dueFollowUps.count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        let userInfo = response.notification.request.content.userInfo
        guard let followUpIdString = userInfo["followUpId"] as? String,
              let followUpId = UUID(uuidString: followUpIdString) else {
            print("❌ Invalid follow-up ID in notification")
            completionHandler()
            return
        }
        
        Task {
            await handleNotificationAction(
                actionId: response.actionIdentifier,
                followUpId: followUpId,
                userInfo: userInfo
            )
            completionHandler()
        }
    }
    
    @MainActor
    private func handleNotificationAction(actionId: String, followUpId: UUID, userInfo: [AnyHashable: Any]) async {
        let followUpStore = FollowUpStore.shared
        
        guard let followUp = followUpStore.followUps.first(where: { $0.id == followUpId }) else {
            print("❌ Follow-up not found: \(followUpId)")
            return
        }
        
        switch actionId {
        case openChatActionId:
            await handleOpenChatAction(followUp: followUp)
            
        case snoozeDayActionId:
            await handleSnoozeDayAction(followUp: followUp)
            
        case markDoneActionId:
            await handleMarkDoneAction(followUp: followUp)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself - open the app
            await handleOpenAppAction(followUp: followUp)
            
        default:
            print("❓ Unknown notification action: \(actionId)")
        }
        
        // Update badge count
        await updateBadgeCount()
    }
    
    private func handleOpenChatAction(followUp: FollowUp) async {
        print("💬 Opening chat for follow-up: \(followUp.id)")
        
        // Create message from template if available
        let message = createMessage(for: followUp)
        
        // Open chat using deep link helper
        let success = DeepLinkHelper.openChat(for: followUp, message: message)
        
        if success {
            // Log that chat was opened
            logAnalytics(event: "notification_chat_opened", followUp: followUp)
        }
    }
    
    private func handleSnoozeDayAction(followUp: FollowUp) async {
        print("😴 Snoozing follow-up for 1 day: \(followUp.id)")
        
        var updatedFollowUp = followUp
        updatedFollowUp.dueAt = Date().addingTimeInterval(24 * 60 * 60) // +24 hours
        updatedFollowUp.status = .snoozed
        
        await MainActor.run {
            let followUpStore = FollowUpStore.shared
            followUpStore.updateFollowUp(updatedFollowUp)
        }
        
        // Reschedule notification
        do {
            try await rescheduleNotification(for: updatedFollowUp)
        } catch {
            print("❌ Failed to reschedule notification: \(error)")
        }
        
        logAnalytics(event: "notification_snoozed", followUp: followUp)
    }
    
    private func handleMarkDoneAction(followUp: FollowUp) async {
        print("✅ Marking follow-up as done: \(followUp.id)")
        
        var updatedFollowUp = followUp
        updatedFollowUp.status = .done
        
        await MainActor.run {
            let followUpStore = FollowUpStore.shared
            followUpStore.updateFollowUp(updatedFollowUp)
        }
        
        // Cancel notification
        await cancelNotification(for: followUp.id)
        
        // If has cadence, schedule next occurrence
        if followUp.cadence != .none {
            await scheduleNextOccurrence(for: followUp)
        }
        
        logAnalytics(event: "notification_marked_done", followUp: followUp)
    }
    
    private func handleOpenAppAction(followUp: FollowUp) async {
        print("📱 Opening app for follow-up: \(followUp.id)")
        
        // The app is already opening, just log the event
        logAnalytics(event: "notification_opened_app", followUp: followUp)
    }
    
    private func scheduleNextOccurrence(for followUp: FollowUp) async {
        guard followUp.cadence != .none else { return }
        
        let calendar = Calendar.current
        let nextDueDate: Date
        
        switch followUp.cadence {
        case .every7Days:
            nextDueDate = calendar.date(byAdding: .day, value: 7, to: followUp.dueAt) ?? followUp.dueAt
        case .every30Days:
            nextDueDate = calendar.date(byAdding: .day, value: 30, to: followUp.dueAt) ?? followUp.dueAt
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: followUp.dueAt) ?? followUp.dueAt
        case .none:
            return
        }
        
        // Create new follow-up for next occurrence
        let nextFollowUp = FollowUp(
            person: followUp.person,
            appType: followUp.appType,
            note: followUp.note,
            url: followUp.url,
            dueAt: nextDueDate,
            cadence: followUp.cadence,
            templateId: followUp.templateId
        )
        
        await MainActor.run {
            let followUpStore = FollowUpStore.shared
            followUpStore.addFollowUp(nextFollowUp)
        }
        
        // Schedule notification for next occurrence
        do {
            try await scheduleNotification(for: nextFollowUp)
            print("🔄 Scheduled next occurrence: \(nextFollowUp.id) at \(nextDueDate)")
        } catch {
            print("❌ Failed to schedule next occurrence: \(error)")
        }
    }
    
    private func createMessage(for followUp: FollowUp) -> String {
        // TODO: Use template system when implemented
        // For now, return the note
        return followUp.note
    }
    
    private func logAnalytics(event: String, followUp: FollowUp) {
        switch event {
        case "notification_chat_opened":
            AnalyticsService.shared.trackChatOpened(app: followUp.appType, source: "notification")
        case "notification_snoozed":
            AnalyticsService.shared.trackFollowUpSnoozed(followUpId: followUp.id, source: "notification")
        case "notification_marked_done":
            AnalyticsService.shared.trackFollowUpCompleted(
                followUpId: followUp.id,
                hadCadence: followUp.cadence != .none,
                source: "notification"
            )
        case "notification_opened_app":
            // This is handled by the general app open analytics
            break
        default:
            break
        }
    }
}
