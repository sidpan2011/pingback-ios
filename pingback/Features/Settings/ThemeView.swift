import SwiftUI

struct ThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Use native SwiftUI colors for instant theme switching
    
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
        List {
            ForEach(Theme.allCases, id: \.self) { theme in
                ThemeRow(
                    theme: theme
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
                .foregroundColor(.primary)
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
    let onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Use native SwiftUI colors for instant theme switching
    
    // Make isSelected computed from themeManager to be reactive
    private var isSelected: Bool {
        themeManager.selectedTheme == theme.rawValue.lowercased()
    }
    
    var body: some View {
        let _ = print("🎨 ThemeRow: Body updated - theme: \(theme.rawValue), isSelected: \(isSelected), colorScheme: \(themeManager.colorScheme), themeManager.selectedTheme: \(themeManager.selectedTheme)")
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: theme.icon)
                    .foregroundColor(.primary)
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
                        .foregroundColor(.primary)
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
