import SwiftUI

struct ThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    enum Theme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var description: String {
            switch self {
            case .system: return "Follows your device settings"
            case .light: return "Always use light appearance"
            case .dark: return "Always use dark appearance"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "gear"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }
        
    }
    
    var body: some View {
        let _ = print("🎨 ThemeView: Body updated - colorScheme: \(themeManager.colorScheme), selectedTheme: \(themeManager.selectedTheme)")
        NavigationView {
            List {
                ForEach(Theme.allCases, id: \.self) { theme in
                    ThemeRow(
                        theme: theme,
                        isSelected: themeManager.selectedTheme == theme
                    ) {
                        print("🎨 ThemeView: Theme selected: \(theme.rawValue)")
                        themeManager.setTheme(theme.rawValue.lowercased())
                        applyTheme(theme)
                    }
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
    }
    
    private func applyTheme(_ theme: Theme) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // The actual theme change is handled by the .preferredColorScheme modifier
        // and the @AppStorage will persist the selection
    }
}

struct ThemeRow: View {
    let theme: ThemeView.Theme
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        let _ = print("🎨 ThemeRow: Body updated - theme: \(theme.rawValue), isSelected: \(isSelected), colorScheme: \(themeManager.colorScheme)")
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: theme.icon)
                    .foregroundColor(primaryColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // Text(theme.description)
                    //     .font(.caption)
                    //     .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            // .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemeView()
        .environmentObject(ThemeManager.shared)
}
