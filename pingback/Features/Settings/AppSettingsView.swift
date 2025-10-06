import SwiftUI

struct AppSettingsView: View {
    @StateObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        NavigationView {
            List {
                // Default App Section
                Section("Default App") {
                    Picker("Default App", selection: $settingsStore.defaultApp) {
                        ForEach(AppType.allCases) { appType in
                            HStack {
                                Image(systemName: appType.icon)
                                    .foregroundColor(.blue)
                                Text(appType.label)
                            }
                            .tag(appType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Default Reminder Time Section
                Section("Default Reminder Time") {
                    DatePicker(
                        "Default Time",
                        selection: $settingsStore.defaultReminderTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    
                    Text("New follow-ups will default to this time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quiet Hours Section
                Section("Quiet Hours") {
                    Toggle("Enable Quiet Hours", isOn: $settingsStore.quietHoursEnabled)
                    
                    if settingsStore.quietHoursEnabled {
                        HStack {
                            Text("From")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $settingsStore.quietHoursStart,
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                        }
                        
                        HStack {
                            Text("To")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $settingsStore.quietHoursEnd,
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                        }
                        
                        Text("Notifications won't be sent during quiet hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(getAppVersion())
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://getpingback.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}


// MARK: - Settings Store

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var defaultApp: AppType {
        didSet { saveSettings() }
    }
    
    @Published var defaultReminderTime: Date {
        didSet { saveSettings() }
    }
    
    @Published var quietHoursEnabled: Bool {
        didSet { saveSettings() }
    }
    
    @Published var quietHoursStart: Date {
        didSet { saveSettings() }
    }
    
    @Published var quietHoursEnd: Date {
        didSet { saveSettings() }
    }
    
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        // Load saved settings or use defaults
        self.defaultApp = AppType(rawValue: userDefaults.string(forKey: "defaultApp") ?? "") ?? .whatsapp
        
        let defaultTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        self.defaultReminderTime = userDefaults.object(forKey: "defaultReminderTime") as? Date ?? defaultTime
        
        self.quietHoursEnabled = userDefaults.bool(forKey: "quietHoursEnabled")
        
        let quietStart = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        self.quietHoursStart = userDefaults.object(forKey: "quietHoursStart") as? Date ?? quietStart
        
        let quietEnd = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        self.quietHoursEnd = userDefaults.object(forKey: "quietHoursEnd") as? Date ?? quietEnd
    }
    
    private func saveSettings() {
        userDefaults.set(defaultApp.rawValue, forKey: "defaultApp")
        userDefaults.set(defaultReminderTime, forKey: "defaultReminderTime")
        userDefaults.set(quietHoursEnabled, forKey: "quietHoursEnabled")
        userDefaults.set(quietHoursStart, forKey: "quietHoursStart")
        userDefaults.set(quietHoursEnd, forKey: "quietHoursEnd")
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endTime = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute,
              let startHour = startTime.hour,
              let startMinute = startTime.minute,
              let endHour = endTime.hour,
              let endMinute = endTime.minute else {
            return false
        }
        
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        if startMinutes <= endMinutes {
            // Same day range (e.g., 22:00 to 23:00)
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Overnight range (e.g., 22:00 to 07:00)
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}

#if DEBUG
#Preview {
    AppSettingsView()
}
#endif
