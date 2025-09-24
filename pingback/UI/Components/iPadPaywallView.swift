import SwiftUI

struct iPadPaywallView: View {
    @StateObject private var paywallManager = RobustPaywallManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }
    
    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isCompactWidth || isCompactHeight {
                // Compact layout for split view or landscape
                compactLayout(geometry: geometry)
            } else {
                // Full layout for portrait
                fullLayout(geometry: geometry)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: PaywallConstants.privacyURL)!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: PaywallConstants.termsURL)!)
        }
    }
    
    // MARK: - Full Layout (Portrait)
    private func fullLayout(geometry: GeometryProxy) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PaywallConstants.spacing) {
                    headerView
                    
                    if paywallManager.showFallback || paywallManager.isLoading {
                        fallbackPaywallView
                    } else {
                        mainPaywallView
                    }
                    
                    footerView
                }
                .padding(.horizontal, max(PaywallConstants.horizontalPadding, geometry.size.width * 0.1))
                .padding(.vertical, PaywallConstants.spacing)
            }
            .navigationTitle("Pingback Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Compact Layout (Split View/Landscape)
    private func compactLayout(geometry: GeometryProxy) -> some View {
        NavigationView {
            VStack(spacing: PaywallConstants.spacing) {
                headerView
                    .padding(.top, 10)
                
                if paywallManager.showFallback || paywallManager.isLoading {
                    fallbackPaywallView
                } else {
                    mainPaywallView
                }
                
                Spacer()
                
                footerView
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, PaywallConstants.horizontalPadding)
            .navigationTitle("Pingback Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: isCompactWidth ? 8 : 12) {
            Image(systemName: "star.fill")
                .font(.system(size: isCompactWidth ? 32 : 48))
                .foregroundColor(.yellow)
            
            Text("Unlock Pro Features")
                .font(isCompactWidth ? .title2 : .largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get unlimited follow-ups, advanced scheduling, and premium features")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Main Paywall View
    private var mainPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            if isCompactWidth {
                // Horizontal layout for compact width
                HStack(spacing: PaywallConstants.spacing) {
                    subscriptionOptionView(
                        title: "Monthly",
                        price: paywallManager.monthlyPrice,
                        perMonth: paywallManager.monthlyPerMonth,
                        isRecommended: false,
                        action: {
                            Task {
                                await paywallManager.purchaseMonthly()
                            }
                        }
                    )
                    
                    subscriptionOptionView(
                        title: "Yearly",
                        price: paywallManager.yearlyPrice,
                        perMonth: paywallManager.yearlyPerMonth,
                        isRecommended: true,
                        savings: paywallManager.savings,
                        action: {
                            Task {
                                await paywallManager.purchaseYearly()
                            }
                        }
                    )
                }
            } else {
                // Vertical layout for full width
                VStack(spacing: PaywallConstants.spacing) {
                    subscriptionOptionView(
                        title: "Monthly",
                        price: paywallManager.monthlyPrice,
                        perMonth: paywallManager.monthlyPerMonth,
                        isRecommended: false,
                        action: {
                            Task {
                                await paywallManager.purchaseMonthly()
                            }
                        }
                    )
                    
                    subscriptionOptionView(
                        title: "Yearly",
                        price: paywallManager.yearlyPrice,
                        perMonth: paywallManager.yearlyPerMonth,
                        isRecommended: true,
                        savings: paywallManager.savings,
                        action: {
                            Task {
                                await paywallManager.purchaseYearly()
                            }
                        }
                    )
                }
            }
            
            actionButtonsView
        }
    }
    
    // MARK: - Fallback Paywall View
    private var fallbackPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            if isCompactWidth {
                // Horizontal layout for compact width
                HStack(spacing: PaywallConstants.spacing) {
                    subscriptionOptionView(
                        title: "Monthly",
                        price: paywallManager.monthlyPrice,
                        perMonth: paywallManager.monthlyPerMonth,
                        isRecommended: false,
                        isEnabled: paywallManager.canPurchase,
                        action: {
                            Task {
                                await paywallManager.purchaseMonthly()
                            }
                        }
                    )
                    
                    subscriptionOptionView(
                        title: "Yearly",
                        price: paywallManager.yearlyPrice,
                        perMonth: paywallManager.yearlyPerMonth,
                        isRecommended: true,
                        savings: paywallManager.savings,
                        isEnabled: paywallManager.canPurchase,
                        action: {
                            Task {
                                await paywallManager.purchaseYearly()
                            }
                        }
                    )
                }
            } else {
                // Vertical layout for full width
                VStack(spacing: PaywallConstants.spacing) {
                    subscriptionOptionView(
                        title: "Monthly",
                        price: paywallManager.monthlyPrice,
                        perMonth: paywallManager.monthlyPerMonth,
                        isRecommended: false,
                        isEnabled: paywallManager.canPurchase,
                        action: {
                            Task {
                                await paywallManager.purchaseMonthly()
                            }
                        }
                    )
                    
                    subscriptionOptionView(
                        title: "Yearly",
                        price: paywallManager.yearlyPrice,
                        perMonth: paywallManager.yearlyPerMonth,
                        isRecommended: true,
                        savings: paywallManager.savings,
                        isEnabled: paywallManager.canPurchase,
                        action: {
                            Task {
                                await paywallManager.purchaseYearly()
                            }
                        }
                    )
                }
            }
            
            if let errorMessage = paywallManager.errorMessage {
                errorMessageView(errorMessage)
            }
            
            actionButtonsView
        }
    }
    
    // MARK: - Subscription Option View
    private func subscriptionOptionView(
        title: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(isCompactWidth ? .subheadline : .headline)
                                .fontWeight(.semibold)
                            
                            if isRecommended {
                                Text("BEST VALUE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(price)
                            .font(isCompactWidth ? .title3 : .title2)
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
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(isCompactWidth ? 12 : PaywallConstants.spacing)
                .background(
                    RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
                        .fill(isEnabled ? Color(.systemGray6) : Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
                                .stroke(isRecommended ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )
            }
        }
        .disabled(!isEnabled || paywallManager.isPurchasing)
        .accessibilityLabel("\(title) subscription, \(price)")
        .accessibilityHint(isEnabled ? "Tap to subscribe" : "Subscription not available")
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
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
                    .frame(height: PaywallConstants.buttonHeight)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(PaywallConstants.cornerRadius)
                }
                .disabled(paywallManager.isRetrying)
                .accessibilityLabel(PaywallConstants.Accessibility.retryButton)
            }
            
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
                .frame(height: PaywallConstants.buttonHeight)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(PaywallConstants.cornerRadius)
            }
            .disabled(paywallManager.isPurchasing)
            .accessibilityLabel(PaywallConstants.Accessibility.restoreButton)
        }
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
        .padding(.horizontal, PaywallConstants.spacing)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        VStack(spacing: 8) {
            Text(PaywallConstants.footerText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                Button("Privacy") {
                    showingPrivacy = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityLabel(PaywallConstants.Accessibility.privacyLink)
                
                Button("Terms") {
                    showingTerms = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityLabel(PaywallConstants.Accessibility.termsLink)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    iPadPaywallView()
}
