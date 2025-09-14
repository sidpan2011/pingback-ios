import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var hasChanges = false
    @State private var showingPermissionAlert = false
    @State private var showingSettingsAlert = false
    
    // Use native SwiftUI colors for instant theme switching
    
    var body: some View {
        List {
            if notificationManager.authorizationStatus == .denied {
                permissionDeniedSection
            } else {
                masterToggleSection
                if notificationManager.isEnabled {
                    reminderSettingsSection
                    quietHoursSection
                    testNotificationSection
                    debugSection
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
            
            if hasChanges {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNotificationSettings()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                showingSettingsAlert = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive follow-up reminders, please enable notifications in Settings.")
        }
        .alert("Open Settings", isPresented: $showingSettingsAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Go to Settings > Pingback > Notifications to enable notifications.")
        }
        .task {
            await notificationManager.checkAuthorizationStatus()
        }
        .onChange(of: notificationManager.dueRemindersEnabled) { _, _ in hasChanges = true }
        .onChange(of: notificationManager.overdueAlertsEnabled) { _, _ in hasChanges = true }
        .onChange(of: notificationManager.creationNudgeEnabled) { _, _ in hasChanges = true }
        .onChange(of: notificationManager.quietHoursEnabled) { _, _ in hasChanges = true }
        .onChange(of: notificationManager.quietHoursStart) { _, _ in hasChanges = true }
        .onChange(of: notificationManager.quietHoursEnd) { _, _ in hasChanges = true }
    }
    
    private var permissionDeniedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications Disabled")
                            .font(.headline)
                        Text("Enable notifications to receive follow-up reminders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("Enable Notifications") {
                    showingPermissionAlert = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var masterToggleSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                    
                    Text(notificationManager.authorizationStatus == .authorized ? (notificationManager.dueRemindersEnabled ? "Enabled" : "Disabled") : "Tap to enable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if notificationManager.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        Task {
                            await requestNotificationPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else if notificationManager.authorizationStatus == .authorized {
                    Toggle("", isOn: $notificationManager.dueRemindersEnabled)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        } footer: {
            Text("Receive reminders for your follow-ups at the right time.")
        }
    }
    
    private var reminderSettingsSection: some View {
        Section {
            HStack {
                Text("Due Date Reminders")
                Spacer()
                Toggle("", isOn: $notificationManager.dueRemindersEnabled)
            }
            
            HStack {
                Text("Overdue Alerts")
                Spacer()
                Toggle("", isOn: $notificationManager.overdueAlertsEnabled)
            }
            
            HStack {
                Text("Creation Nudge")
                Spacer()
                Toggle("", isOn: $notificationManager.creationNudgeEnabled)
            }
        } header: {
            Text("Reminder Types")
        } footer: {
            Text("Choose which types of reminders you want to receive. Creation nudges appear briefly after creating a follow-up.")
        }
    }
    
    private var quietHoursSection: some View {
        Section {
            HStack {
                Text("Enable Quiet Hours")
                Spacer()
                Toggle("", isOn: $notificationManager.quietHoursEnabled)
            }
            
            if notificationManager.quietHoursEnabled {
                DatePicker("Start Time", selection: $notificationManager.quietHoursStart, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                
                DatePicker("End Time", selection: $notificationManager.quietHoursEnd, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("Notifications scheduled during quiet hours will be delayed until the end time. Respects Do Not Disturb and Focus modes.")
        }
    }
    
    private var debugSection: some View {
        Section {
            Button("Clear All Notifications") {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                Task {
                    try? await UNUserNotificationCenter.current().setBadgeCount(0)
                }
            }
            .foregroundColor(.red)
            
            Button("Reschedule All Notifications") {
                Task {
                    await notificationManager.rescheduleAllNotifications()
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("Debug Actions")
        } footer: {
            Text("Use these options to manage and reset your notification state.")
        }
    }
    
    private var testNotificationSection: some View {
        Section {
            Button("Send Test Notification") {
                Task {
                    await sendTestNotification()
                }
            }
            .foregroundColor(.primary)
        } footer: {
            Text("Test your notification settings. The test notification will appear in 3 seconds.")
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12:00 AM"
        } else if hour < 12 {
            return "\(hour):00 AM"
        } else if hour == 12 {
            return "12:00 PM"
        } else {
            return "\(hour - 12):00 PM"
        }
    }
    
    private func requestNotificationPermission() async {
        let granted = await notificationManager.requestPermission()
        if !granted {
            showingPermissionAlert = true
        }
    }
    
    private func sendTestNotification() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notification settings are working correctly! 🎉"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send test notification: \(error)")
        }
    }
    
    private func saveNotificationSettings() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Settings are automatically saved via @Published properties in NotificationManager
        Task {
            await notificationManager.rescheduleAllNotifications()
        }
        
        hasChanges = false
        dismiss()
    }
}

#Preview {
    NotificationsView()
        .environmentObject(ThemeManager.shared)
}
