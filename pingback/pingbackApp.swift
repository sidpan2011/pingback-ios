//
//  pingbackApp.swift
//  pingback
//
//  Created by Sidhanth Pandey on 09/09/25.
//

import SwiftUI

@main
struct pingbackApp: App {
    // Initialize the Core Data stack
    let coreDataStack = CoreDataStack.shared
    @StateObject private var userProfileStore = UserProfileStore()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init() {
        // Configure RevenueCat on app launch
        RevenueCatConfiguration.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(userProfileStore)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .animation(.easeInOut(duration: 0.1), value: themeManager.colorScheme)
                .onReceive(themeManager.$colorScheme) { newColorScheme in
                    print("🎨 pingbackApp: ColorScheme changed to: \(String(describing: newColorScheme))")
                }
                .onReceive(themeManager.$selectedTheme) { newTheme in
                    print("🎨 pingbackApp: SelectedTheme changed to: \(newTheme)")
                }
                .task {
                    // Initialize ThemeManager with UserProfileStore
                    themeManager.initialize(with: userProfileStore)
                }
        }
    }
}
