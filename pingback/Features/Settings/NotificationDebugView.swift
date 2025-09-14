import SwiftUI
import UserNotifications
import CoreData

struct NotificationDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingRequests: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                statusSection
                actionsSection
                pendingSection
                deliveredSection
                settingsSection
            }
            .navigationTitle("Notification Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await loadNotificationData()
                        }
                    }
                }
            }
            .task {
                await loadNotificationData()
            }
        }
    }
    
    private var statusSection: some View {
        Section("Authorization Status") {
            HStack {
                Text("Status")
                Spacer()
                Text(statusText)
                    .foregroundColor(statusColor)
            }
            
            HStack {
                Text("Badge Count")
                Spacer()
                Text("\(UIApplication.shared.applicationIconBadgeNumber)")
            }
            
            HStack {
                Text("Pending Requests")
                Spacer()
                Text("\(pendingRequests.count)")
            }
            
            HStack {
                Text("Delivered")
                Spacer()
                Text("\(deliveredNotifications.count)")
            }
        }
    }
    
    private var actionsSection: some View {
        Section("Test Actions") {
            Button("Send Test Notification") {
                Task {
                    await sendTestNotification()
                }
            }
            
            Button("Update Badge Count") {
                Task {
                    await notificationManager.updateBadgeCount()
                    await loadNotificationData()
                }
            }
            
            Button("Reschedule All Notifications") {
                Task {
                    await notificationManager.rescheduleAllNotifications()
                    await loadNotificationData()
                }
            }
            
            Button("Clear All Notifications") {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                Task {
                    await loadNotificationData()
                }
            }
            .foregroundColor(.red)
        }
    }
    
    private var pendingSection: some View {
        Section("Pending Notifications (\(pendingRequests.count))") {
            if pendingRequests.isEmpty {
                Text("No pending notifications")
                    .foregroundColor(.secondary)
            } else {
                ForEach(pendingRequests, id: \.identifier) { request in
                    NotificationRequestRow(request: request)
                }
            }
        }
    }
    
    private var deliveredSection: some View {
        Section("Delivered Notifications (\(deliveredNotifications.count))") {
            if deliveredNotifications.isEmpty {
                Text("No delivered notifications")
                    .foregroundColor(.secondary)
            } else {
                ForEach(deliveredNotifications, id: \.request.identifier) { notification in
                    NotificationDeliveredRow(notification: notification)
                }
            }
        }
    }
    
    private var settingsSection: some View {
        Section("Current Settings") {
            HStack {
                Text("Due Reminders")
                Spacer()
                Text(notificationManager.dueRemindersEnabled ? "Enabled" : "Disabled")
                    .foregroundColor(notificationManager.dueRemindersEnabled ? .green : .red)
            }
            
            HStack {
                Text("Overdue Alerts")
                Spacer()
                Text(notificationManager.overdueAlertsEnabled ? "Enabled" : "Disabled")
                    .foregroundColor(notificationManager.overdueAlertsEnabled ? .green : .red)
            }
            
            HStack {
                Text("Creation Nudge")
                Spacer()
                Text(notificationManager.creationNudgeEnabled ? "Enabled" : "Disabled")
                    .foregroundColor(notificationManager.creationNudgeEnabled ? .green : .red)
            }
            
            HStack {
                Text("Quiet Hours")
                Spacer()
                Text(notificationManager.quietHoursEnabled ? "Enabled" : "Disabled")
                    .foregroundColor(notificationManager.quietHoursEnabled ? .green : .red)
            }
            
            if notificationManager.quietHoursEnabled {
                HStack {
                    Text("Quiet Hours")
                    Spacer()
                    Text("\(formatTime(notificationManager.quietHoursStart)) - \(formatTime(notificationManager.quietHoursEnd))")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined, .provisional:
            return .orange
        default:
            return .secondary
        }
    }
    
    private func loadNotificationData() async {
        isLoading = true
        
        let center = UNUserNotificationCenter.current()
        
        async let pending = center.pendingNotificationRequests()
        async let delivered = center.deliveredNotifications()
        
        do {
            let (pendingResults, deliveredResults) = try await (pending, delivered)
            
            await MainActor.run {
                self.pendingRequests = pendingResults.sorted { $0.identifier < $1.identifier }
                self.deliveredNotifications = deliveredResults.sorted { $0.date > $1.date }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Failed to load notification data: \(error)")
        }
    }
    
    private func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Debug Test Notification"
        content.body = "This is a test notification sent at \(Date().formatted(date: .omitted, time: .standard))"
        content.sound = .default
        content.categoryIdentifier = "FOLLOWUP_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "debug_test_\(UUID().uuidString)", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            await loadNotificationData()
        } catch {
            print("Failed to send test notification: \(error)")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct NotificationRequestRow: View {
    let request: UNNotificationRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(request.content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(request.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(request.content.body)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(formatTriggerDate(trigger))
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("In \(Int(trigger.timeInterval))s")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        let components = trigger.dateComponents
        let calendar = Calendar.current
        
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return "Invalid date"
    }
}

struct NotificationDeliveredRow: View {
    let notification: UNNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(notification.request.content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(notification.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(notification.request.content.body)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NotificationDebugView()
        .environment(\.managedObjectContext, CoreDataStack.preview.viewContext)
}
