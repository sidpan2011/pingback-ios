//
//  ContentView.swift
//  pingback
//
//  Created by Sidhanth Pandey on 09/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var followUpStore = FollowUpStore()
    
    var body: some View {
        LaunchGateView()
            .environmentObject(followUpStore)
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
