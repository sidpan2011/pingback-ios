import SwiftUI
import RevenueCat

struct RevenueCatUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ProPaywallView()
    }
}

#Preview {
    RevenueCatUpgradeView()
        .environmentObject(SubscriptionManager.shared)
}