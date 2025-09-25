import SwiftUI

struct ProGateView<Content: View>: View {
    let content: Content
    let fallback: (() -> AnyView)?
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var featureAccess = FeatureAccessLayer.shared
    @State private var showingPaywall = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self.fallback = nil
    }
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder fallback: @escaping () -> AnyView) {
        self.content = content()
        self.fallback = fallback
    }
    
    var body: some View {
        Group {
            if featureAccess.isAvailable(.unlimitedReminders) {
                content
            } else if let fallback = fallback {
                fallback()
            } else {
                Button(action: {
                    showingPaywall = true
                }) {
                    content
                }
                .sheet(isPresented: $showingPaywall) {
                    ProPaywallView()
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension ProGateView {
    /// Creates a ProGateView that shows a paywall when tapped if user is not Pro
    static func paywallOnTap<C: View>(@ViewBuilder content: @escaping () -> C) -> some View {
        ProGateView<C>(content: content)
    }
    
    /// Creates a ProGateView that shows custom fallback content if user is not Pro
    static func withFallback<C: View, F: View>(
        @ViewBuilder content: @escaping () -> C,
        @ViewBuilder fallback: @escaping () -> F
    ) -> some View {
        ProGateView<C>(content: content, fallback: { AnyView(fallback()) })
    }
    
    /// Creates a ProGateView that shows a disabled state if user is not Pro
    static func disabledIfNotPro<C: View>(@ViewBuilder content: @escaping () -> C) -> some View {
        ProGateView<C>(content: content, fallback: {
            AnyView(
                content()
                    .disabled(true)
                    .opacity(0.6)
            )
        })
    }
}

// MARK: - Pro Status Checker

struct ProStatusChecker {
    @StateObject private var featureAccess = FeatureAccessLayer.shared
    
    var isPro: Bool {
        featureAccess.isAvailable(.unlimitedReminders)
    }
    
    func requirePro() throws {
        guard isPro else {
            throw ProError.subscriptionRequired
        }
    }
}

enum ProError: LocalizedError {
    case subscriptionRequired
    
    var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return "Pro subscription required"
        }
    }
}

// MARK: - Preview Helpers

#Preview("Pro User") {
    ProGateView {
        Text("Pro Content")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    .environmentObject(SubscriptionManager.shared)
}

#Preview("Free User - Paywall on Tap") {
    ProGateView {
        Text("Tap for Pro")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    .environmentObject(SubscriptionManager.shared)
}

#Preview("Free User - Disabled") {
    ProGateView(content: {
        Text("Disabled Content")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }, fallback: {
        AnyView(
            Text("Disabled Content")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(true)
                .opacity(0.6)
        )
    })
    .environmentObject(SubscriptionManager.shared)
}
