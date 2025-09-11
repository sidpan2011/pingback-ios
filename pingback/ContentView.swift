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

#Preview { ContentView() }
