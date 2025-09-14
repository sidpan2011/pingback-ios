import Foundation
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme?
    @Published var selectedTheme: String = "system"
    
    static let shared = ThemeManager()
    private var cancellables = Set<AnyCancellable>()
    private var userProfileStore: UserProfileStore?
    
    private init() {
        print("🎨 ThemeManager: Initializing ThemeManager.shared")
        print("🎨 ThemeManager: Initial selectedTheme: \(selectedTheme)")
        print("🎨 ThemeManager: Initial colorScheme: \(String(describing: colorScheme))")
        setupSystemThemeObserver()
        print("🎨 ThemeManager: Initialization complete")
    }
    
    /// Initialize with UserProfileStore for CoreData persistence
    func initialize(with userProfileStore: UserProfileStore) {
        self.userProfileStore = userProfileStore
        
        // Load theme from UserProfile if available (on main actor)
        Task { @MainActor in
            if let profile = userProfileStore.profile {
                print("🎨 ThemeManager: Loading theme from UserProfile: \(profile.theme)")
                self.updateThemeFromString(profile.theme)
            } else {
                print("🎨 ThemeManager: No UserProfile found, loading from UserDefaults fallback")
                self.loadThemeFromUserDefaults()
            }
            
            // Listen for profile changes
            userProfileStore.$profile
                .compactMap { $0 }
                .sink { [weak self] profile in
                    print("🎨 ThemeManager: UserProfile theme changed to: \(profile.theme)")
                    self?.updateThemeFromString(profile.theme)
                }
                .store(in: &self.cancellables)
        }
    }
    
    private func loadThemeFromUserDefaults() {
        // Load theme from UserDefaults (fallback when no UserProfile exists)
        let storedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        print("🎨 ThemeManager: loadThemeFromUserDefaults() called")
        print("🎨 ThemeManager: UserDefaults.selectedTheme = \(storedTheme ?? "nil")")
        
        if let themeString = storedTheme {
            print("🎨 ThemeManager: Loading theme from UserDefaults: \(themeString)")
            updateThemeFromString(themeString)
        } else {
            print("🎨 ThemeManager: No stored theme, using default: system")
            updateThemeFromString("system")
            // Save the default system theme
            UserDefaults.standard.set("system", forKey: "selectedTheme")
            UserDefaults.standard.synchronize()
            print("✅ ThemeManager: Set and saved default system theme to UserDefaults")
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
        if selectedTheme == "system" {
            DispatchQueue.main.async {
                // For system theme, set colorScheme to nil to let SwiftUI handle it
                self.colorScheme = nil
                print("🎨 ThemeManager: Using system theme (nil colorScheme)")
            }
        }
    }
    
    private func updateThemeFromString(_ themeString: String) {
        print("🎨 ThemeManager: updateThemeFromString called with: \(themeString)")
        
        DispatchQueue.main.async {
            switch themeString {
            case "light":
                self.selectedTheme = "light"
                self.colorScheme = .light
            case "dark":
                self.selectedTheme = "dark"
                self.colorScheme = .dark
            case "system":
                self.selectedTheme = "system"
                self.colorScheme = nil  // Let SwiftUI handle system theme
            default:
                self.selectedTheme = "system"
                self.colorScheme = nil  // Let SwiftUI handle system theme
            }
            print("🎨 ThemeManager: After update - selectedTheme: \(self.selectedTheme), colorScheme: \(String(describing: self.colorScheme))")
        }
    }
    
    func setTheme(_ theme: String) {
        print("🎨 ThemeManager: Setting theme to: \(theme)")
        
        // Update local state immediately for instant UI update
        updateThemeFromString(theme)
        
        // Save to storage asynchronously (don't block UI)
        Task { @MainActor in
            if let userProfileStore = self.userProfileStore {
                print("🎨 ThemeManager: Saving theme to CoreData via UserProfileStore")
                
                // Get or create profile
                let existingProfile = userProfileStore.profile ?? UserProfile()
                let profile = UserProfile(
                    fullName: existingProfile.fullName,
                    email: existingProfile.email,
                    avatarData: existingProfile.avatarData,
                    theme: theme
                )
                
                do {
                    try await userProfileStore.saveProfile(profile)
                    print("✅ ThemeManager: Theme saved to CoreData successfully")
                } catch {
                    print("❌ ThemeManager: Failed to save theme to CoreData: \(error)")
                    // Fallback to UserDefaults
                    self.saveThemeToUserDefaults(theme)
                }
            } else {
                print("🎨 ThemeManager: No UserProfileStore available, saving to UserDefaults")
                self.saveThemeToUserDefaults(theme)
            }
        }
    }
    
    private func saveThemeToUserDefaults(_ theme: String) {
        UserDefaults.standard.set(theme, forKey: "selectedTheme")
        UserDefaults.standard.synchronize()
        print("✅ ThemeManager: Theme saved to UserDefaults and synchronized")
        
        // Verify the save worked
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        print("🔍 ThemeManager: Verification - saved theme is: \(savedTheme ?? "nil")")
    }
    
    // Method to reset to system theme (for debugging)
    func forceSystemTheme() {
        print("🔄 ThemeManager: Forcing system theme")
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        UserDefaults.standard.synchronize()
        loadThemeFromUserDefaults()
    }
    
    // ThemeManager only handles theme state - no color overrides
    // Let SwiftUI handle colors natively for instant theme switching
}
