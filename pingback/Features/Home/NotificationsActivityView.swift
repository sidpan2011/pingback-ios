import SwiftUI
import UserNotifications

struct NotificationsActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading notifications...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Pending Notifications Section
                    if !pendingNotifications.isEmpty {
                        Section("Scheduled Notifications") {
                            ForEach(pendingNotifications, id: \.identifier) { notification in
                                NotificationRowView(notification: notification)
                            }
                        }
                    }
                    
                    // Delivered Notifications Section
                    if !deliveredNotifications.isEmpty {
                        Section("Recent Notifications") {
                            ForEach(deliveredNotifications, id: \.request.identifier) { notification in
                                DeliveredNotificationRowView(notification: notification)
                            }
                        }
                    }
                    
                    // Empty State
                    if pendingNotifications.isEmpty && deliveredNotifications.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 4) {
                                    Text("No Notifications")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Your scheduled and recent notifications will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    }
                    
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .refreshable {
                await loadNotifications()
            }
        }
        .onAppear {
            Task {
                await loadNotifications()
            }
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        
        do {
            // Load pending notifications
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            
            // Load delivered notifications
            let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
            
            await MainActor.run {
                self.pendingNotifications = pending.sorted { first, second in
                    guard let firstTrigger = first.trigger as? UNCalendarNotificationTrigger,
                          let secondTrigger = second.trigger as? UNCalendarNotificationTrigger,
                          let firstDate = Calendar.current.date(from: firstTrigger.dateComponents),
                          let secondDate = Calendar.current.date(from: secondTrigger.dateComponents) else {
                        return false
                    }
                    return firstDate < secondDate
                }
                
                self.deliveredNotifications = delivered.sorted { first, second in
                    first.date > second.date
                }
                
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: UNNotificationRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.content.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !notification.content.body.isEmpty {
                        Text(notification.content.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                       let date = Calendar.current.date(from: trigger.dateComponents) {
                        Text(formatScheduledDate(date))
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(formatScheduledTime(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Follow-up info if available
            if let followUpId = notification.content.userInfo["followUpId"] as? String {
                HStack {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Follow-up: \(followUpId.prefix(8))...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatScheduledDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatScheduledTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DeliveredNotificationRowView: View {
    let notification: UNNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.request.content.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatDeliveredTime(notification.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !notification.request.content.body.isEmpty {
                        Text(notification.request.content.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Follow-up info if available
            if let followUpId = notification.request.content.userInfo["followUpId"] as? String {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("Follow-up: \(followUpId.prefix(8))...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    
    private func formatDeliveredTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NotificationsActivityView()
        .environmentObject(NotificationManager.shared)
}
