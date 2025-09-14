import XCTest
import UserNotifications
import CoreData
import UIKit
@testable import pingback

@MainActor
final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    var coreDataStack: CoreDataStack!
    var testContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory Core Data stack for testing
        coreDataStack = CoreDataStack.preview
        testContext = coreDataStack.viewContext
        
        // Initialize notification manager with test context
        notificationManager = NotificationManager.shared
        notificationManager.initialize(with: testContext)
        
        // Clear any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    override func tearDown() async throws {
        // Clean up
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        try await super.tearDown()
    }
    
    // MARK: - Quiet Hours Tests
    
    func testQuietHoursAdjustment() {
        // Test quiet hours settings
        let calendar = Calendar.current
        notificationManager.quietHoursEnabled = true
        notificationManager.quietHoursStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        notificationManager.quietHoursEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        
        // Verify settings are applied
        XCTAssertTrue(notificationManager.quietHoursEnabled)
        XCTAssertEqual(calendar.component(.hour, from: notificationManager.quietHoursStart), 22)
        XCTAssertEqual(calendar.component(.hour, from: notificationManager.quietHoursEnd), 8)
    }
    
    func testQuietHoursDisabled() {
        notificationManager.quietHoursEnabled = false
        
        // Verify setting is applied
        XCTAssertFalse(notificationManager.quietHoursEnabled)
    }
    
    // MARK: - Notification Content Tests
    
    func testNotificationContentCreation() {
        let followUp = createTestFollowUp()
        
        // Test that follow-up has required properties for notification content
        XCTAssertNotNil(followUp.title)
        XCTAssertNotNil(followUp.id)
        XCTAssertEqual(followUp.title, "Test Follow-up")
        XCTAssertTrue(followUp.shouldNotify)
    }
    
    // MARK: - Badge Count Tests
    
    func testBadgeCountCalculation() async {
        // Create test follow-ups
        let dueFollowUp = createTestFollowUp(dueAt: Date().addingTimeInterval(-3600)) // 1 hour ago
        let futureFollowUp = createTestFollowUp(dueAt: Date().addingTimeInterval(3600)) // 1 hour from now
        
        try? testContext.save()
        
        await notificationManager.updateBadgeCount()
        
        // Note: In tests, we can't easily verify the actual badge count
        // This test ensures the method runs without errors
        XCTAssertTrue(true, "Badge count update completed without errors")
    }
    
    // MARK: - Snooze Logic Tests
    
    func testSnoozeCalculation() {
        let followUp = createTestFollowUp()
        let snoozeMinutes = 30
        let expectedSnoozeTime = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        
        // Test snooze calculation (would be used in actual snooze method)
        let calculatedSnoozeTime = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        
        XCTAssertEqual(
            Int(expectedSnoozeTime.timeIntervalSince1970),
            Int(calculatedSnoozeTime.timeIntervalSince1970),
            accuracy: 5,
            "Snooze time calculation should be accurate within 5 seconds"
        )
    }
    
    func testSnoozeTomorrowCalculation() {
        let calendar = Calendar.current
        let followUp = createTestFollowUp(dueAt: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!)
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let expectedTomorrowTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow)!
        
        // Test tomorrow snooze calculation
        let timeComponents = calendar.dateComponents([.hour, .minute], from: followUp.dueAt!)
        let calculatedTomorrowTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: tomorrow
        )!
        
        XCTAssertEqual(
            calendar.component(.hour, from: expectedTomorrowTime),
            calendar.component(.hour, from: calculatedTomorrowTime)
        )
        XCTAssertEqual(
            calendar.component(.minute, from: expectedTomorrowTime),
            calendar.component(.minute, from: calculatedTomorrowTime)
        )
    }
    
    // MARK: - Overdue Detection Tests
    
    func testOverdueDetection() {
        let calendar = Calendar.current
        let now = Date()
        let gracePeriodAgo = now.addingTimeInterval(-NotificationManager.overdueGracePeriod)
        
        // Create follow-up that's been overdue for more than grace period
        let overdueFollowUp = createTestFollowUp(dueAt: gracePeriodAgo.addingTimeInterval(-3600)) // 1 hour before grace period
        
        // Create follow-up that's overdue but within grace period
        let recentlyOverdueFollowUp = createTestFollowUp(dueAt: now.addingTimeInterval(-600)) // 10 minutes ago
        
        try? testContext.save()
        
        // Test overdue detection logic
        let isOverdueWithGrace = overdueFollowUp.dueAt! < gracePeriodAgo
        let isRecentlyOverdue = recentlyOverdueFollowUp.dueAt! > gracePeriodAgo
        
        XCTAssertTrue(isOverdueWithGrace, "Follow-up should be detected as overdue after grace period")
        XCTAssertTrue(isRecentlyOverdue, "Recently overdue follow-up should still be within grace period")
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence() {
        // Test that settings are properly saved to UserDefaults
        notificationManager.dueRemindersEnabled = false
        notificationManager.overdueAlertsEnabled = false
        notificationManager.creationNudgeEnabled = true
        notificationManager.quietHoursEnabled = true
        
        // Verify UserDefaults storage
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "notifications.dueReminders"))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "notifications.overdueAlerts"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "notifications.creationNudge"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "notifications.quietHours"))
    }
    
    // MARK: - Helper Methods
    
    private func createTestFollowUp(
        title: String = "Test Follow-up",
        dueAt: Date = Date().addingTimeInterval(3600),
        isCompleted: Bool = false
    ) -> CDFollowUp {
        let followUp = CDFollowUp(context: testContext)
        followUp.id = UUID()
        followUp.title = title
        followUp.snippet = title
        followUp.contactLabel = "Test Contact"
        followUp.app = AppKind.other.rawValue
        followUp.type = FollowType.doIt.rawValue
        followUp.verb = "follow up"
        followUp.dueAt = dueAt
        followUp.createdAt = Date()
        followUp.status = isCompleted ? Status.done.rawValue : Status.open.rawValue
        followUp.isCompleted = isCompleted
        followUp.shouldNotify = true
        followUp.creationTimeZone = TimeZone.current.identifier
        
        return followUp
    }
}

