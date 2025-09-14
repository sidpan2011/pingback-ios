import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var notificationsEnabled = true
    @State private var reminderAlerts = true
    @State private var quietHoursEnabled = false
    @State private var quietStartHour = 22
    @State private var quietEndHour = 8
    @State private var reminderTime = 9
    @State private var hasChanges = false
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        NavigationView {
            List {
                masterToggleSection
                if notificationsEnabled {
                    reminderSettingsSection
                    quietHoursSection
                    notificationTypesSection
                    testNotificationSection
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                
                if hasChanges {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveNotificationSettings()
                        }
                        // .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            .onChange(of: notificationsEnabled) { _, _ in hasChanges = true }
            .onChange(of: reminderAlerts) { _, _ in hasChanges = true }
            .onChange(of: quietHoursEnabled) { _, _ in hasChanges = true }
            .onChange(of: quietStartHour) { _, _ in hasChanges = true }
            .onChange(of: quietEndHour) { _, _ in hasChanges = true }
            .onChange(of: reminderTime) { _, _ in hasChanges = true }
        }
    }
    
    private var masterToggleSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                    
                    // Text(notificationsEnabled ? "All notifications are enabled" : "All notifications are disabled")
                    //     .font(.subheadline)
                    //     .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
            }
            // .padding(.vertical, 8)
        } footer: {
            Text("Turn off to disable all follow-up notifications.")
        }
    }
    
    private var reminderSettingsSection: some View {
        Section {
            HStack {
                Text("Reminder Alerts")
                Spacer()
                Toggle("", isOn: $reminderAlerts)
            }
            
            if reminderAlerts {
                HStack {
                    Text("Daily Reminder Time")
                    Spacer()
                    Picker("", selection: $reminderTime) {
                        ForEach(6...22, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(primaryColor)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Get reminded about your follow-ups at the specified time.")
        }
    }
    
    private var quietHoursSection: some View {
        Section {
            HStack {
                Text("Enable Quiet Hours")
                Spacer()
                Toggle("", isOn: $quietHoursEnabled)
            }
            
            if quietHoursEnabled {
                HStack {
                    Text("Start Time")
                    Spacer()
                    Picker("Start Time", selection: $quietStartHour) {
                        ForEach(18...23, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(primaryColor)
                }
                
                HStack {
                    Text("End Time")
                    Spacer()
                    Picker("End Time", selection: $quietEndHour) {
                        ForEach(6...12, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(primaryColor)
                }
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("No notifications will be sent during quiet hours.")
        }
    }
    
    private var notificationTypesSection: some View {
        Section {
            HStack {
                Text("Due Date Reminders")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            HStack {
                Text("Overdue Alerts")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            HStack {
                Text("Snooze Reminders")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
        } header: {
            Text("Notification Types")
        } footer: {
            Text("Choose which types of notifications you want to receive.")
        }
    }
    
    private var testNotificationSection: some View {
        Section {
            Button("Send Test Notification") {
                sendTestNotification()
            }
            .foregroundColor(primaryColor)
        } footer: {
            Text("Test your notification settings to make sure they're working properly.")
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
    
    private func sendTestNotification() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // In a real app, you would schedule a test notification
        // UNUserNotificationCenter.current().add(...)
    }
    
    private func saveNotificationSettings() {
        // Save notification settings
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        hasChanges = false
        dismiss()
    }
}

#Preview {
    NotificationsView()
        .environmentObject(ThemeManager.shared)
}
