//
//  ContentView.swift
//  pingback
//
//  Created by Sidhanth Pandey on 09/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showOnboarding: Bool = true
    var body: some View {
        ZStack {
            HomeView()
                .opacity(showOnboarding ? 0 : 1)
            if showOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        withAnimation(.easeInOut) { showOnboarding = false }
                    }
            }
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
