import SwiftUI
import RevenueCat

struct HybridPaywallView: View {
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var showingRobustPaywall = false
    @State private var hasRevenueCatError = false
    @State private var isLoadingRevenueCat = true
    @State private var timeoutReached = false
    @State private var timeRemaining: Int = 5
    
    private let revenueCatTimeout: TimeInterval = 5.0
    
    var body: some View {
        Group {
            if showingRobustPaywall {
                // Show fallback paywall when RevenueCat fails or times out
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadFallbackPaywallView()
                } else {
                    FallbackPaywallView()
                }
            } else {
                // Show RevenueCat paywall first
                RevenueCatUpgradeView()
                    .overlay(
                        // Show loading overlay while waiting for RevenueCat
                        Group {
                            if isLoadingRevenueCat && !timeoutReached {
                                LoadingOverlayView(timeRemaining: timeRemaining)
                            }
                        }
                    )
            }
        }
        .onAppear {
            startRevenueCatTimeout()
        }
        .onChange(of: revenueCatManager.offerings) { offerings in
            checkRevenueCatStatus(offerings: offerings)
        }
        .onChange(of: revenueCatManager.errorMessage) { errorMessage in
            if errorMessage != nil {
                hasRevenueCatError = true
                switchToRobustPaywall()
            }
        }
    }
    
    private func startRevenueCatTimeout() {
        // Start countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                if !hasRevenueCatError && isLoadingRevenueCat {
                    timeoutReached = true
                    switchToRobustPaywall()
                }
            }
        }
        
        // Check initial status
        checkRevenueCatStatus(offerings: revenueCatManager.offerings)
    }
    
    private func checkRevenueCatStatus(offerings: Offerings?) {
        if let offerings = offerings,
           let current = offerings.current,
           !current.availablePackages.isEmpty {
            // RevenueCat has offerings, stop loading
            isLoadingRevenueCat = false
        } else if hasRevenueCatError || timeoutReached {
            // Switch to robust paywall
            switchToRobustPaywall()
        }
    }
    
    private func switchToRobustPaywall() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingRobustPaywall = true
            isLoadingRevenueCat = false
        }
    }
}

// MARK: - Loading Overlay View
struct LoadingOverlayView: View {
    @State private var isAnimating = false
    let timeRemaining: Int
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading subscription options...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if timeRemaining > 0 {
                Text("Switching to backup in \(timeRemaining)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    HybridPaywallView()
}
