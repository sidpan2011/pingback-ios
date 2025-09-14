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
    @StateObject private var notificationManager = NotificationManager.shared
    
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
                .environmentObject(notificationManager)
                .preferredColorScheme(themeManager.colorScheme)
                .animation(.easeInOut(duration: 0.1), value: themeManager.colorScheme)
                .onReceive(themeManager.$colorScheme) { newColorScheme in
                    print("🎨 pingbackApp: ColorScheme changed to: \(String(describing: newColorScheme))")
                }
                .onReceive(themeManager.$selectedTheme) { newTheme in
                    print("🎨 pingbackApp: SelectedTheme changed to: \(newTheme)")
                }
                .onReceive(NotificationCenter.default.publisher(for: .openFollowUpFromNotification)) { notification in
                    if let followUpId = notification.userInfo?["followUpId"] as? String {
                        handleDeepLinkFromNotification(followUpId: followUpId)
                    }
                }
                .task {
                    // Initialize ThemeManager with UserProfileStore
                    themeManager.initialize(with: userProfileStore)
                    
                    // Initialize NotificationManager with Core Data context
                    notificationManager.initialize(with: coreDataStack.viewContext)
                }
        }
    }
    
    private func handleDeepLinkFromNotification(followUpId: String) {
        // Post a notification that can be handled by the appropriate view
        NotificationCenter.default.post(
            name: .navigateToFollowUp,
            object: nil,
            userInfo: ["followUpId": followUpId]
        )
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let navigateToFollowUp = Notification.Name("navigateToFollowUp")
}
