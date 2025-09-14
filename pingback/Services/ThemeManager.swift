import Foundation
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
    @Published var selectedTheme: ThemeView.Theme = .light
    
    static let shared = ThemeManager()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTheme()
        setupSystemThemeObserver()
    }
    
    private func loadTheme() {
        // Load theme from UserDefaults
        if let themeString = UserDefaults.standard.string(forKey: "selectedTheme") {
            print("🎨 ThemeManager: Loading theme from UserDefaults: \(themeString)")
            updateThemeFromString(themeString)
        } else {
            print("🎨 ThemeManager: Using default theme: system")
            updateThemeFromString("system")
        }
    }
    
    private func setupSystemThemeObserver() {
        // Listen for system theme changes when using system theme
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateSystemThemeIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func updateSystemThemeIfNeeded() {
        if selectedTheme == .system {
            let systemColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : ColorScheme.light
            if colorScheme != systemColorScheme {
                DispatchQueue.main.async {
                    self.colorScheme = systemColorScheme
                    print("🎨 ThemeManager: System theme changed to: \(systemColorScheme)")
                }
            }
        }
    }
    
    private func updateThemeFromString(_ themeString: String) {
        print("🎨 ThemeManager: updateThemeFromString called with: \(themeString)")
        
        DispatchQueue.main.async {
            switch themeString {
            case "light":
                self.selectedTheme = .light
                self.colorScheme = .light
            case "dark":
                self.selectedTheme = .dark
                self.colorScheme = .dark
            case "system":
                self.selectedTheme = .system
                self.colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            default:
                self.selectedTheme = .system
                self.colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            }
            print("🎨 ThemeManager: After update - selectedTheme: \(self.selectedTheme), colorScheme: \(self.colorScheme)")
        }
    }
    
    func setTheme(_ theme: String) {
        print("🎨 ThemeManager: Setting theme to: \(theme)")
        
        // Update local state immediately
        updateThemeFromString(theme)
        
        // Save to UserDefaults
        UserDefaults.standard.set(theme, forKey: "selectedTheme")
        print("✅ ThemeManager: Theme saved to UserDefaults")
    }
    
    // Computed properties for theme-aware colors
    var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground)
    }
    
    var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground)
    }
}
