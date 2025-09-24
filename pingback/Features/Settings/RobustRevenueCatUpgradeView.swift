import SwiftUI
import RevenueCat

struct RobustRevenueCatUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paywallManager = RobustPaywallManager()
    @State private var selectedPackage: Package?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPaywall = false
    
    // Feature carousel
    struct Feature: Identifiable { 
        let id = UUID()
        let title: String
        let subtitle: String
        let symbol: String
    }
    
    private let features: [Feature] = [
        .init(title: "Unlimited Follow-ups", subtitle: "Create as many follow-ups as you need", symbol: "infinity"),
        .init(title: "Advanced Notifications", subtitle: "Customize notification timing and frequency", symbol: "bell.badge.fill"),
        .init(title: "Analytics & Insights", subtitle: "Track your follow-up success rates", symbol: "chart.bar.fill"),
        .init(title: "Cloud Sync", subtitle: "Sync across all your devices", symbol: "icloud.fill"),
        .init(title: "Custom Themes", subtitle: "Personalize your app experience", symbol: "paintbrush.fill"),
        .init(title: "Priority Support", subtitle: "Get help when you need it most", symbol: "headphones")
    ]
    @State private var featureIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: Feature carousel
                    TabView(selection: $featureIndex) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 16) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 80))
                                    .foregroundColor(.primary)

                                Text(item.title)
                                    .font(.title3).bold()
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 200)
                    .onAppear {
                        // Auto-advance carousel
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                featureIndex = (featureIndex + 1) % features.count
                            }
                        }
                    }
                    
                    // MARK: Pricing section
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if paywallManager.showFallback || paywallManager.isLoading {
                            fallbackPricingView
                        } else {
                            mainPricingView
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: Features list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's Included")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(features, id: \.id) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(feature.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: Action buttons
                    VStack(spacing: 12) {
                        // Primary action button
                        Button(action: {
                            showingPaywall = true
                        }) {
                            HStack {
                                if paywallManager.isPurchasing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "star.fill")
                                }
                                
                                Text(paywallManager.isPurchasing ? "Processing..." : "Start Free Trial")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(paywallManager.isPurchasing)
                        
                        // Secondary action button
                        Button(action: {
                            Task {
                                await paywallManager.restorePurchases()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle")
                                Text("Restore Purchases")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(paywallManager.isPurchasing)
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: Footer
                    VStack(spacing: 8) {
                        Text("7-day free trial, then $4.99/month or $49.99/year")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Cancel anytime. Auto-renewing subscription.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadPaywallView()
            } else {
                RobustPaywallView()
            }
        }
        .alert("Purchase Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Main Pricing View
    private var mainPricingView: some View {
        VStack(spacing: 12) {
            // Monthly option
            pricingOptionView(
                title: "Monthly",
                price: paywallManager.monthlyPrice,
                perMonth: paywallManager.monthlyPerMonth,
                isRecommended: false
            )
            
            // Yearly option
            pricingOptionView(
                title: "Yearly",
                price: paywallManager.yearlyPrice,
                perMonth: paywallManager.yearlyPerMonth,
                isRecommended: true,
                savings: paywallManager.savings
            )
        }
    }
    
    // MARK: - Fallback Pricing View
    private var fallbackPricingView: some View {
        VStack(spacing: 12) {
            // Monthly option (fallback)
            pricingOptionView(
                title: "Monthly",
                price: paywallManager.monthlyPrice,
                perMonth: paywallManager.monthlyPerMonth,
                isRecommended: false,
                isEnabled: paywallManager.canPurchase
            )
            
            // Yearly option (fallback)
            pricingOptionView(
                title: "Yearly",
                price: paywallManager.yearlyPrice,
                perMonth: paywallManager.yearlyPerMonth,
                isRecommended: true,
                savings: paywallManager.savings,
                isEnabled: paywallManager.canPurchase
            )
            
            // Error message
            if let errorMessage = paywallManager.errorMessage {
                errorMessageView(errorMessage)
            }
            
            // Retry button
            if paywallManager.showFallback || paywallManager.isRetrying {
                Button(action: {
                    Task {
                        await paywallManager.retry()
                    }
                }) {
                    HStack {
                        if paywallManager.isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Retry")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(paywallManager.isRetrying)
            }
        }
    }
    
    // MARK: - Pricing Option View
    private func pricingOptionView(
        title: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if isRecommended {
                        Text("BEST VALUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(price)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !perMonth.isEmpty {
                    Text(perMonth)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let savings = savings, !savings.isEmpty {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? Color(.systemGray6) : Color(.systemGray5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isRecommended ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Error Message View
    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    RobustRevenueCatUpgradeView()
}
