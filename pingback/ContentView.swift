//
//  ContentView.swift
//  pingback
//
//  Created by Sidhanth Pandey on 09/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var followUpStore = FollowUpStore()
    @StateObject private var newFollowUpStore = NewFollowUpStore()
    
    var body: some View {
        LaunchGateView()
            .environmentObject(followUpStore)
            .environmentObject(newFollowUpStore)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Process shared data when app becomes active (e.g., returning from share extension)
                print("📱 ContentView: App became active, processing shared data...")
                SharedDataManager.shared.processOnAppBecomeActive(using: newFollowUpStore)
            }
    }
}

#Preview { 
    // Create a simple preview that shows the onboarding state
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        VStack {
            Image(systemName: "bolt.horizontal.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(.tint)
            
            Text("Pingback")
                .font(.largeTitle.bold())
                .padding(.top)
        }
    }
}
