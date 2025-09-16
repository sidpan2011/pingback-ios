import SwiftUI

struct AppSettingsView: View {
    @StateObject private var settingsStore = SettingsStore.shared
    @StateObject private var templateService = TemplateService.shared
    @State private var showingTemplateEditor = false
    @State private var selectedTemplate: MessageTemplate?
    
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
                
                // Templates Section
                Section("Message Templates") {
                    ForEach(templateService.templates) { template in
                        TemplateRowView(template: template) {
                            selectedTemplate = template
                            showingTemplateEditor = true
                        }
                    }
                    .onDelete(perform: deleteTemplate)
                    
                    Button("Add Template") {
                        selectedTemplate = nil
                        showingTemplateEditor = true
                    }
                    .foregroundColor(.blue)
                }
                
                // iCloud Sync Section (Stubbed)
                Section("Data Sync") {
                    HStack {
                        Toggle("iCloud Sync", isOn: $settingsStore.iCloudSyncEnabled)
                        
                        if settingsStore.iCloudSyncEnabled {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text("Sync follow-ups across your devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(getAppVersion())
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingTemplateEditor) {
            TemplateEditorView(template: selectedTemplate) { updatedTemplate in
                if selectedTemplate != nil {
                    templateService.updateTemplate(updatedTemplate)
                } else {
                    templateService.addTemplate(updatedTemplate)
                }
                showingTemplateEditor = false
            }
        }
    }
    
    private func deleteTemplate(at offsets: IndexSet) {
        for index in offsets {
            let template = templateService.templates[index]
            templateService.deleteTemplate(template)
        }
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

struct TemplateRowView: View {
    let template: MessageTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if template.isDefault {
                        Text("Default")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Text(template.preview())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TemplateEditorView: View {
    let template: MessageTemplate?
    let onSave: (MessageTemplate) -> Void
    
    @State private var name: String
    @State private var content: String
    @State private var isDefault: Bool
    @StateObject private var templateService = TemplateService.shared
    @Environment(\.dismiss) private var dismiss
    
    init(template: MessageTemplate?, onSave: @escaping (MessageTemplate) -> Void) {
        self.template = template
        self.onSave = onSave
        self._name = State(initialValue: template?.name ?? "")
        self._content = State(initialValue: template?.content ?? "")
        self._isDefault = State(initialValue: template?.isDefault ?? false)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Template Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                    
                    TextField("Enter template name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Template Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Template")
                        .font(.headline)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .font(.body)
                }
                
                // Variables Help
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Variables")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(templateService.getAvailableVariables(), id: \.name) { variable in
                            VariableChip(variable: variable) {
                                insertVariable(variable.name)
                            }
                        }
                    }
                }
                
                // Default Toggle
                Toggle("Set as Default Template", isOn: $isDefault)
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(previewMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || content.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var previewMessage: String {
        if content.isEmpty {
            return "Enter template content to see preview"
        }
        
        let previewTemplate = MessageTemplate(
            name: name.isEmpty ? "Preview" : name,
            content: content,
            isDefault: isDefault
        )
        
        return previewTemplate.preview()
    }
    
    private func insertVariable(_ variableName: String) {
        content += variableName
    }
    
    private func saveTemplate() {
        let savedTemplate = MessageTemplate(
            id: template?.id ?? UUID(),
            name: name,
            content: content,
            isDefault: isDefault
        )
        
        if isDefault {
            // Set this as the new default
            templateService.setDefaultTemplate(savedTemplate)
        }
        
        onSave(savedTemplate)
    }
}

struct VariableChip: View {
    let variable: TemplateVariable
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(variable.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(variable.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    @Published var iCloudSyncEnabled: Bool {
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
        
        self.iCloudSyncEnabled = userDefaults.bool(forKey: "iCloudSyncEnabled")
    }
    
    private func saveSettings() {
        userDefaults.set(defaultApp.rawValue, forKey: "defaultApp")
        userDefaults.set(defaultReminderTime, forKey: "defaultReminderTime")
        userDefaults.set(quietHoursEnabled, forKey: "quietHoursEnabled")
        userDefaults.set(quietHoursStart, forKey: "quietHoursStart")
        userDefaults.set(quietHoursEnd, forKey: "quietHoursEnd")
        userDefaults.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
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
