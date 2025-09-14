import SwiftUI

struct DefaultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    // @State private var defaultTag: DefaultTag = .`do`
    @State private var morningHour = 9
    @State private var endOfDayHour = 17
    @State private var selectedSnoozeTime: SnoozeTime = .fifteenMinutes
    @State private var selectedSnoozeDate: SnoozeDate = .tonight
    @State private var hasChanges = false
    
    // Store initial values to compare against
    @State private var initialMorningHour = 9
    @State private var initialEndOfDayHour = 17
    @State private var initialSnoozeTime: SnoozeTime = .fifteenMinutes
    @State private var initialSnoozeDate: SnoozeDate = .tonight
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    private func checkForChanges() {
        hasChanges = morningHour != initialMorningHour ||
                    endOfDayHour != initialEndOfDayHour ||
                    selectedSnoozeTime != initialSnoozeTime ||
                    selectedSnoozeDate != initialSnoozeDate
    }
    
    // enum DefaultTag: String, CaseIterable {
    //     case `do` = "Do"
    //     case waitingOn = "Waiting-On"
    //     
    //     var description: String {
    //         switch self {
    //         case .`do`: return "Tasks you need to do"
    //         case .waitingOn: return "Tasks waiting for others"
    //         }
    //     }
    // }
    
    enum SnoozeTime: String, CaseIterable {
        case fiveMinutes = "5m"
        case fifteenMinutes = "15m"
        case thirtyMinutes = "30m"
        case oneHour = "1h"
        
        var displayName: String {
            switch self {
            case .fiveMinutes: return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .oneHour: return "1 hour"
            }
        }
    }
    
    enum SnoozeDate: String, CaseIterable {
        case tonight = "Tonight"
        case tomorrow = "Tomorrow"
        
        var displayName: String {
            switch self {
            case .tonight: return "Tonight"
            case .tomorrow: return "Tomorrow"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Default Tag Section
                // Section {
                //     Picker("Default Tag", selection: $defaultTag) {
                //         ForEach(DefaultTag.allCases, id: \.self) { tag in
                //             VStack(alignment: .leading, spacing: 2) {
                //                 Text(tag.rawValue)
                //                     .font(.body)
                //                 Text(tag.description)
                //                     .font(.caption)
                //                     .foregroundColor(.secondary)
                //             }
                //             .tag(tag)
                //         }
                //     }
                //     .pickerStyle(.segmented)
                // } header: {
                //     Text("Default Tag")
                // } footer: {
                //     Text("Choose the default tag for new follow-ups.")
                // }
                
                // Time Settings Section
                Section {
                    HStack {
                        Text("Morning Hour")
                        Spacer()
                        Picker("", selection: $morningHour) {
                            ForEach(6...12, id: \.self) { hour in
                                Text("\(hour):00 AM").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                    
                    HStack {
                        Text("End-of-Day Hour")
                        Spacer()
                        Picker("", selection: $endOfDayHour) {
                            ForEach(16...22, id: \.self) { hour in
                                Text("\(hour - 12):00 PM").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                } header: {
                    Text("Time Settings")
                } footer: {
                    Text("Set your working hours for better follow-up scheduling.")
                }
                
                // Snooze Settings Section
                Section {
                    HStack {
                        Text("When snoozed")
                        Spacer()
                        Picker("", selection: $selectedSnoozeTime) {
                            ForEach(SnoozeTime.allCases, id: \.self) { time in
                                Text(time.displayName).tag(time)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                    
                    HStack {
                        Text("At what time")
                        Spacer()
                        Picker("", selection: $selectedSnoozeDate) {
                            ForEach(SnoozeDate.allCases, id: \.self) { date in
                                Text(date.displayName).tag(date)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                } header: {
                    Text("Snooze Settings")
                } footer: {
                    Text("Set default snooze duration and timing for follow-ups.")
                }
            }
            .navigationTitle("Defaults")
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
                            saveDefaults()
                        }
                        // .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            // .onChange(of: defaultTag) { _, _ in checkForChanges() }
            .onChange(of: morningHour) { _, _ in checkForChanges() }
            .onChange(of: endOfDayHour) { _, _ in checkForChanges() }
            .onChange(of: selectedSnoozeTime) { _, _ in checkForChanges() }
            .onChange(of: selectedSnoozeDate) { _, _ in checkForChanges() }
        }
    }
    
    
    private func saveDefaults() {
        // Save settings to UserDefaults or app state
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // In a real app, you would save these settings:
        // UserDefaults.standard.set(defaultTag.rawValue, forKey: "defaultTag")
        // UserDefaults.standard.set(morningHour, forKey: "morningHour")
        // UserDefaults.standard.set(endOfDayHour, forKey: "endOfDayHour")
        // UserDefaults.standard.set(selectedSnoozeTime.rawValue, forKey: "snoozeTime")
        // UserDefaults.standard.set(selectedSnoozeDate.rawValue, forKey: "snoozeDate")
        
        // Update initial values to current values
        initialMorningHour = morningHour
        initialEndOfDayHour = endOfDayHour
        initialSnoozeTime = selectedSnoozeTime
        initialSnoozeDate = selectedSnoozeDate
        
        hasChanges = false
        dismiss()
    }
}


#Preview {
    DefaultsView()
        .environmentObject(ThemeManager.shared)
}
