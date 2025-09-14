//
//  LaunchGateView.swift
//  pingback
//
//  Created by Sidhanth Pandey on 13/09/25.
//

import SwiftUI

struct LaunchGateView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboardingSheet = false
    @State private var showHomeView = false
    @EnvironmentObject var followUpStore: FollowUpStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // App Icon
                VStack(spacing: 16) {
                    if let appIcon = UIImage(named: "AppIcon") {
                        Image(uiImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    } else {
                        // Fallback if app icon is not found
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.blue.gradient)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    }
                    
                    Text("Pingback")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Only show Get Started button for first-time users
                if !hasSeenOnboarding {
                    Button(action: {
                        showOnboardingSheet = true
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .accessibilityLabel("Get Started button")
                    .accessibilityHint("Tap to begin the onboarding process")
                }
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView()
        }
        .onAppear {
            if hasSeenOnboarding {
                // User has seen onboarding - brief splash then go to HomeView
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showHomeView = true
                    }
                }
            }
        }
        .onChange(of: hasSeenOnboarding) { _, newValue in
            if newValue {
                // User just completed onboarding - go to HomeView immediately
                withAnimation(.easeInOut(duration: 0.5)) {
                    showHomeView = true
                }
            }
        }
        .fullScreenCover(isPresented: $showHomeView) {
            HomeView()
                .environmentObject(followUpStore)
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    LaunchGateView()
}
