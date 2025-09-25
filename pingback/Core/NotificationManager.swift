import Foundation
import UserNotifications
import CoreData
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Constants
    private static let maxScheduledNotifications = 64
    private static let categoryIdentifier = "FOLLOWUP_REMINDER"
    private static let creationNudgeDelay: TimeInterval = 4.0
    private static let overdueGracePeriod: TimeInterval = 30 * 60 // 30 minutes
    
    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false
    
    // MARK: - Settings
    @Published var dueRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(dueRemindersEnabled, forKey: "notifications.dueReminders") }
    }
    @Published var overdueAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(overdueAlertsEnabled, forKey: "notifications.overdueAlerts") }
    }
    @Published var creationNudgeEnabled: Bool {
        didSet { UserDefaults.standard.set(creationNudgeEnabled, forKey: "notifications.creationNudge") }
    }
    @Published var quietHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(quietHoursEnabled, forKey: "notifications.quietHours") }
    }
    @Published var quietHoursStart: Date {
        didSet { UserDefaults.standard.set(quietHoursStart, forKey: "notifications.quietHoursStart") }
    }
    @Published var quietHoursEnd: Date {
        didSet { UserDefaults.standard.set(quietHoursEnd, forKey: "notifications.quietHoursEnd") }
    }
    
    // MARK: - Private Properties
    private var scheduledNotificationIds: Set<String> = []
    private let notificationCenter = UNUserNotificationCenter.current()
    private var coreDataContext: NSManagedObjectContext?
    
    // MARK: - Initialization
    override init() {
        // Initialize settings from UserDefaults
        self.dueRemindersEnabled = UserDefaults.standard.object(forKey: "notifications.dueReminders") as? Bool ?? true
        self.overdueAlertsEnabled = UserDefaults.standard.object(forKey: "notifications.overdueAlerts") as? Bool ?? true
        self.creationNudgeEnabled = UserDefaults.standard.object(forKey: "notifications.creationNudge") as? Bool ?? true
        self.quietHoursEnabled = UserDefaults.standard.object(forKey: "notifications.quietHours") as? Bool ?? false
        
        // Default quiet hours: 10 PM to 8 AM
        let calendar = Calendar.current
        let defaultStart = UserDefaults.standard.object(forKey: "notifications.quietHoursStart") as? Date ?? 
            calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultEnd = UserDefaults.standard.object(forKey: "notifications.quietHoursEnd") as? Date ?? 
            calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        
        self.quietHoursStart = defaultStart
        self.quietHoursEnd = defaultEnd
        super.init()
        
        // Set up notification center delegate
        notificationCenter.delegate = self
        
        // Set up notification categories
        setupNotificationCategories()
        
        // Set up observers for app lifecycle
        setupAppLifecycleObservers()
        
        // Check authorization status asynchronously
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Setup
    private func setupNotificationCategories() {
        // Create notification category with actions
        let snooze10Action = UNNotificationAction(
            identifier: "SNOOZE_10M",
            title: "Snooze 10m",
            options: []
        )
        
        let snooze1HAction = UNNotificationAction(
            identifier: "SNOOZE_1H",
            title: "Snooze 1h",
            options: []
        )
        
        let snoozeTomorrowAction = UNNotificationAction(
            identifier: "SNOOZE_TOMORROW",
            title: "Snooze Tomorrow",
            options: []
        )
        
        let markDoneAction = UNNotificationAction(
            identifier: "MARK_DONE",
            title: "Mark Done",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [snooze10Action, snooze1HAction, snoozeTomorrowAction, markDoneAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    private func setupAppLifecycleObservers() {
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Listen for significant time changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(significantTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        
        // Listen for day change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func initialize(with context: NSManagedObjectContext) {
        self.coreDataContext = context
        Task {
            await syncScheduledNotifications()
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ NotificationManager: Failed to request permission: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isEnabled = settings.authorizationStatus == .authorized
        
        print("🔔 NotificationManager: Authorization status: \(authorizationStatus.rawValue), isEnabled: \(isEnabled)")
        
        // If not determined, request permission
        if authorizationStatus == .notDetermined {
            print("🔔 NotificationManager: Permission not determined, requesting...")
            let granted = await requestPermission()
            print("🔔 NotificationManager: Permission request result: \(granted)")
        }
    }
    
    // MARK: - Test Methods
    func sendTestNotification() async {
        guard isEnabled else {
            print("🔔 NotificationManager: Cannot send test notification - notifications disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Pingback Test"
        content.body = "This is a test notification from Pingback"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Test notification scheduled")
        } catch {
            print("❌ NotificationManager: Failed to schedule test notification: \(error)")
        }
    }
    
    /// Send an immediate test notification for follow-up creation
    func sendImmediateTestNotification() async {
        guard isEnabled else {
            print("🔔 NotificationManager: Cannot send immediate test notification - notifications disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Follow-up created"
        content.body = "Don't forget: Test follow-up"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate_test_notification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Immediate test notification scheduled")
        } catch {
            print("❌ NotificationManager: Failed to schedule immediate test notification: \(error)")
        }
    }
    
    /// Test scheduling a notification with a due date in the past (should fire immediately)
    func testImmediateDueNotification() async {
        guard isEnabled else {
            print("🔔 NotificationManager: Cannot send test due notification - notifications disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Due Notification"
        content.body = "This follow-up is due now!"
        content.sound = .default
        
        // Schedule for 1 second from now (simulating a due notification)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_due_notification", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Test due notification scheduled")
        } catch {
            print("❌ NotificationManager: Failed to schedule test due notification: \(error)")
        }
    }
    
    // MARK: - Scheduling Methods
    func scheduleCreationNudge(for followUp: CDFollowUp) {
        guard creationNudgeEnabled, isEnabled else { 
            print("🔔 NotificationManager: Creation nudge disabled - creationNudgeEnabled: \(creationNudgeEnabled), isEnabled: \(isEnabled)")
            return 
        }
        
        let identifier = "\(followUp.id?.uuidString ?? UUID().uuidString)_creation"
        let content = UNMutableNotificationContent()
        content.title = "Follow-up created"
        content.body = "Don't forget: \(followUp.title ?? "Untitled")"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Self.creationNudgeDelay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        print("🔔 NotificationManager: Scheduling creation nudge for '\(followUp.title ?? "Untitled")' in \(Self.creationNudgeDelay) seconds")
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ NotificationManager: Failed to schedule creation nudge: \(error)")
            } else {
                print("✅ NotificationManager: Successfully scheduled creation nudge")
            }
        }
    }
    
    func scheduleNotification(for followUp: CDFollowUp) async {
        guard isEnabled, dueRemindersEnabled else { 
            print("🔔 NotificationManager: Notifications disabled - isEnabled: \(isEnabled), dueRemindersEnabled: \(dueRemindersEnabled)")
            return 
        }
        guard let followUpId = followUp.id else { 
            print("🔔 NotificationManager: No follow-up ID found")
            return 
        }
        
        // Skip if already completed or notifications disabled for this item
        if followUp.isCompleted || !followUp.shouldNotify {
            print("🔔 NotificationManager: Skipping notification - isCompleted: \(followUp.isCompleted), shouldNotify: \(followUp.shouldNotify)")
            await cancelNotification(for: followUpId)
            return
        }
        
        // Determine next fire time
        let nextFireTime: Date
        if let snoozedUntil = followUp.snoozedUntil, snoozedUntil > Date() {
            nextFireTime = snoozedUntil
            print("🔔 NotificationManager: Using snoozed time: \(snoozedUntil)")
        } else if let dueAt = followUp.dueAt {
            nextFireTime = dueAt
            print("🔔 NotificationManager: Using due time: \(dueAt)")
        } else {
            // No due date, can't schedule
            print("🔔 NotificationManager: No due date found, cannot schedule notification")
            return
        }
        
        // Adjust for quiet hours
        let adjustedFireTime = adjustForQuietHours(nextFireTime)
        
        // Check if we've already scheduled this exact time
        if let lastScheduled = followUp.lastScheduledAt,
           abs(lastScheduled.timeIntervalSince(adjustedFireTime)) < 60 {
            return // Already scheduled within a minute of this time
        }
        
        // Create notification content
        let content = createNotificationContent(for: followUp, fireTime: adjustedFireTime)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: adjustedFireTime),
            repeats: false
        )
        
        let identifier = followUpId.uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Cancel existing notification and add new one
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        do {
            print("🔔 NotificationManager: Attempting to schedule notification for '\(followUp.title ?? "Untitled")' at \(adjustedFireTime)")
            try await notificationCenter.add(request)
            scheduledNotificationIds.insert(identifier)
            
            // Update lastScheduledAt in Core Data
            followUp.lastScheduledAt = adjustedFireTime
            try? coreDataContext?.save()
            
            print("✅ NotificationManager: Successfully scheduled notification for '\(followUp.title ?? "Untitled")' at \(adjustedFireTime)")
        } catch {
            print("❌ NotificationManager: Failed to schedule notification for '\(followUp.title ?? "Untitled")': \(error)")
        }
    }
    
    func cancelNotification(for followUpId: UUID) async {
        let identifier = followUpId.uuidString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotificationIds.remove(identifier)
    }
    
    func rescheduleAllNotifications() async {
        guard let context = coreDataContext else { return }
        
        // Cancel all existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        scheduledNotificationIds.removeAll()
        
        // Fetch eligible follow-ups
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO AND shouldNotify == YES AND dueAt != nil")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDFollowUp.snoozedUntil, ascending: true),
            NSSortDescriptor(keyPath: \CDFollowUp.dueAt, ascending: true)
        ]
        request.fetchLimit = Self.maxScheduledNotifications
        
        do {
            let followUps = try context.fetch(request)
            
            for followUp in followUps {
                await scheduleNotification(for: followUp)
            }
            
            await updateBadgeCount()
            
        } catch {
            print("❌ NotificationManager: Failed to fetch follow-ups for rescheduling: \(error)")
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() async {
        // Get delivered notifications count instead of overdue items
        let deliveredNotifications = await UNUserNotificationCenter.current().deliveredNotifications()
        let deliveredCount = deliveredNotifications.count
        
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(deliveredCount)
            print("✅ NotificationManager: Updated badge count to \(deliveredCount) delivered notifications")
        } catch {
            print("❌ NotificationManager: Failed to update badge count: \(error)")
        }
    }
    
    // MARK: - Action Handlers
    func handleNotificationAction(_ actionIdentifier: String, for followUpId: String) async {
        guard let context = coreDataContext,
              let uuid = UUID(uuidString: followUpId) else { return }
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let followUps = try context.fetch(request)
            guard let followUp = followUps.first else { return }
            
            switch actionIdentifier {
            case "SNOOZE_10M":
                await snoozeFollowUp(followUp, for: 10 * 60)
            case "SNOOZE_1H":
                await snoozeFollowUp(followUp, for: 60 * 60)
            case "SNOOZE_TOMORROW":
                await snoozeTomorrow(followUp)
            case "MARK_DONE":
                await markFollowUpDone(followUp)
            default:
                break
            }
        } catch {
            print("❌ NotificationManager: Failed to handle action: \(error)")
        }
    }
    
    // MARK: - Private Helper Methods
    private func createNotificationContent(for followUp: CDFollowUp, fireTime: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Determine follow-up type and set appropriate icon and title
        let followUpType = FollowType(rawValue: followUp.type ?? "") ?? .doIt
        let (iconName, titlePrefix) = getNotificationIconAndTitle(for: followUpType)
        
        // Title with icon and type-specific prefix
        content.title = "\(titlePrefix): \(followUp.title ?? "Untitled")"
        
        // Body with relative time and contact/URL info
        var bodyComponents: [String] = []
        
        let timeFormatter = RelativeDateTimeFormatter()
        timeFormatter.unitsStyle = .short
        let relativeTime = timeFormatter.localizedString(for: fireTime, relativeTo: Date())
        bodyComponents.append(relativeTime)
        
        if let urlString = followUp.webURL,
           let url = URL(string: urlString),
           let host = url.host {
            bodyComponents.append("with \(host)")
        } else if let contactLabel = followUp.contactLabel, !contactLabel.isEmpty {
            bodyComponents.append("with \(contactLabel)")
        }
        
        content.body = bodyComponents.joined(separator: " — ")
        
        // Category for actions (but we're not using actions anymore)
        content.categoryIdentifier = Self.categoryIdentifier
        
        // Thread identifier for grouping by type
        content.threadIdentifier = "followup_\(followUpType.rawValue)"
        
        // Sound based on type
        content.sound = followUpType == .doIt ? .default : .defaultRingtone
        
        // User info for deep linking with type information
        content.userInfo = [
            "followUpId": followUp.id?.uuidString ?? "",
            "action": "open_followup",
            "type": followUpType.rawValue,
            "iconName": iconName
        ]
        
        return content
    }
    
    private func getNotificationIconAndTitle(for type: FollowType) -> (iconName: String, titlePrefix: String) {
        switch type {
        case .doIt:
            return ("checkmark.circle", "Action Required")
        case .waitingOn:
            return ("clock", "Waiting On")
        }
    }
    
    private func adjustForQuietHours(_ date: Date) -> Date {
        guard quietHoursEnabled else { return date }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        guard let hour = dateComponents.hour,
              let minute = dateComponents.minute,
              let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return date
        }
        
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        // Handle quiet hours spanning midnight
        let isInQuietHours: Bool
        if startMinutes > endMinutes {
            // Spans midnight (e.g., 22:00 to 08:00)
            isInQuietHours = currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            // Same day (e.g., 01:00 to 06:00)
            isInQuietHours = currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
        
        if isInQuietHours {
            // Move to end of quiet hours
            var adjustedDate = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date) ?? date
            
            // If end time is earlier in the day, it means next day
            if endMinutes <= currentMinutes && startMinutes > endMinutes {
                adjustedDate = calendar.date(byAdding: .day, value: 1, to: adjustedDate) ?? adjustedDate
            }
            
            return adjustedDate
        }
        
        return date
    }
    
    private func snoozeFollowUp(_ followUp: CDFollowUp, for seconds: TimeInterval) async {
        let snoozeUntil = Date().addingTimeInterval(seconds)
        let adjustedTime = adjustForQuietHours(snoozeUntil)
        
        followUp.snoozedUntil = adjustedTime
        try? coreDataContext?.save()
        
        await scheduleNotification(for: followUp)
        await updateBadgeCount()
    }
    
    private func snoozeTomorrow(_ followUp: CDFollowUp) async {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        // Use the same time as original due date, or current time if no due date
        let targetTime: Date
        if let dueAt = followUp.dueAt {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: dueAt)
            targetTime = calendar.date(bySettingHour: timeComponents.hour ?? 9, 
                                     minute: timeComponents.minute ?? 0, 
                                     second: 0, 
                                     of: tomorrow) ?? tomorrow
        } else {
            targetTime = tomorrow
        }
        
        let adjustedTime = adjustForQuietHours(targetTime)
        
        followUp.snoozedUntil = adjustedTime
        try? coreDataContext?.save()
        
        await scheduleNotification(for: followUp)
        await updateBadgeCount()
    }
    
    private func markFollowUpDone(_ followUp: CDFollowUp) async {
        followUp.isCompleted = true
        followUp.status = Status.done.rawValue
        try? coreDataContext?.save()
        
        if let followUpId = followUp.id {
            await cancelNotification(for: followUpId)
        }
        await updateBadgeCount()
    }
    
    private func syncScheduledNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let pendingIds = Set(pendingRequests.map { $0.identifier })
        
        scheduledNotificationIds = pendingIds
        
        // Clean up any notifications that shouldn't exist
        guard let context = coreDataContext else { return }
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES OR shouldNotify == NO")
        
        do {
            let completedFollowUps = try context.fetch(request)
            let idsToCancel = completedFollowUps.compactMap { $0.id?.uuidString }
            
            if !idsToCancel.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToCancel)
                idsToCancel.forEach { scheduledNotificationIds.remove($0) }
            }
        } catch {
            print("❌ NotificationManager: Failed to sync notifications: \(error)")
        }
    }
    
    // MARK: - Overdue Notifications
    func scheduleOverdueNotifications() async {
        guard let context = coreDataContext, overdueAlertsEnabled else { return }
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        let now = Date()
        let gracePeriodAgo = now.addingTimeInterval(-Self.overdueGracePeriod)
        
        // Find items that are overdue and haven't been notified today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        request.predicate = NSPredicate(format: """
            isCompleted == NO AND 
            shouldNotify == YES AND 
            dueAt < %@ AND 
            dueAt < %@ AND
            (lastOverdueNotifiedAt == nil OR lastOverdueNotifiedAt < %@)
        """, now as NSDate, gracePeriodAgo as NSDate, startOfDay as NSDate)
        
        do {
            let overdueFollowUps = try context.fetch(request)
            
            for followUp in overdueFollowUps {
                await scheduleOverdueNotification(for: followUp)
            }
        } catch {
            print("❌ NotificationManager: Failed to fetch overdue follow-ups: \(error)")
        }
    }
    
    private func scheduleOverdueNotification(for followUp: CDFollowUp) async {
        guard let followUpId = followUp.id else { return }
        
        let identifier = "\(followUpId.uuidString)_overdue"
        let content = UNMutableNotificationContent()
        
        // Determine follow-up type for appropriate icon
        let followUpType = FollowType(rawValue: followUp.type ?? "") ?? .doIt
        let (iconName, _) = getNotificationIconAndTitle(for: followUpType)
        
        // Title with urgency indicator
        content.title = "🔴 Overdue: \(followUp.title ?? "Follow-up")"
        
        let timeFormatter = RelativeDateTimeFormatter()
        timeFormatter.unitsStyle = .full
        let overdueTime = timeFormatter.localizedString(for: followUp.dueAt ?? Date(), relativeTo: Date())
        
        var bodyComponents = ["This follow-up was due \(overdueTime)"]
        if let contactLabel = followUp.contactLabel, !contactLabel.isEmpty {
            bodyComponents.append("with \(contactLabel)")
        }
        content.body = bodyComponents.joined(separator: " ")
        
        // Category for actions
        content.categoryIdentifier = Self.categoryIdentifier
        
        // Thread identifier for overdue notifications
        content.threadIdentifier = "overdue_\(followUpType.rawValue)"
        
        // Sound - more urgent for overdue
        content.sound = .defaultCritical
        
        // User info with type information
        content.userInfo = [
            "followUpId": followUpId.uuidString,
            "action": "open_followup",
            "type": "overdue",
            "originalType": followUpType.rawValue,
            "iconName": iconName
        ]
        
        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            
            // Update lastOverdueNotifiedAt
            followUp.lastOverdueNotifiedAt = Date()
            try? coreDataContext?.save()
            
            print("✅ NotificationManager: Scheduled overdue notification for \(followUp.title ?? "Untitled")")
        } catch {
            print("❌ NotificationManager: Failed to schedule overdue notification: \(error)")
        }
    }
    
    // MARK: - Observers
    @objc private func appDidBecomeActive() {
        Task {
            await checkAuthorizationStatus()
            await updateBadgeCount()
            await scheduleOverdueNotifications()
        }
    }
    
    @objc private func appWillEnterForeground() {
        Task {
            await syncScheduledNotifications()
            await rescheduleAllNotifications()
            await scheduleOverdueNotifications()
        }
    }
    
    @objc private func significantTimeChange() {
        Task {
            await rescheduleAllNotifications()
        }
    }
    
    @objc private func dayChanged() {
        Task {
            await rescheduleAllNotifications()
            await scheduleOverdueNotifications()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: @preconcurrency UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let followUpId = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        Task {
            await handleNotificationAction(actionIdentifier, for: followUpId)
        }
        
        completionHandler()
    }
    
    private func handleDeepLink(followUpId: String) async {
        // Post notification to handle deep link in the main app
        NotificationCenter.default.post(
            name: .openFollowUpFromNotification,
            object: nil,
            userInfo: ["followUpId": followUpId]
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openFollowUpFromNotification = Notification.Name("openFollowUpFromNotification")
}
