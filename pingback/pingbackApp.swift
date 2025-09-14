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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
