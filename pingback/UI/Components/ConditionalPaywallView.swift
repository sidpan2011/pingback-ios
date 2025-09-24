import SwiftUI

struct ConditionalPaywallView: View {
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var showingRobustPaywall = false
    @State private var hasRevenueCatError = false
    
    var body: some View {
        Group {
            if hasRevenueCatError {
                // Show robust paywall when RevenueCat fails
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadPaywallView()
                } else {
                    RobustPaywallView()
                }
            } else {
                // Show normal RevenueCat paywall first
                RevenueCatUpgradeView()
            }
        }
        .onAppear {
            checkRevenueCatStatus()
        }
        .onChange(of: revenueCatManager.errorMessage) { errorMessage in
            if errorMessage != nil {
                hasRevenueCatError = true
            }
        }
    }
    
    private func checkRevenueCatStatus() {
        // Check if RevenueCat has offerings
        if revenueCatManager.offerings?.current == nil {
            // No offerings available, show robust paywall
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                hasRevenueCatError = true
            }
        }
    }
}

#Preview {
    ConditionalPaywallView()
}
