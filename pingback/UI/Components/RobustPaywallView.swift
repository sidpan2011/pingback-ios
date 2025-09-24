import SwiftUI
import SafariServices

struct RobustPaywallView: View {
    @StateObject private var paywallManager = RobustPaywallManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @State private var selectedPlan: PlanType = .yearly
    
    enum PlanType: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
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
                    .padding(.horizontal, PaywallConstants.horizontalPadding)
                    .padding(.vertical, PaywallConstants.spacing)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures consistent behavior on iPad
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: PaywallConstants.privacyURL)!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: PaywallConstants.termsURL)!)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // App Icon
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
            
            // App Name
            Text("Pingback")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Available Plans")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Main Paywall View
    private var mainPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            // Plan Selection
            VStack(spacing: 12) {
                // Monthly Plan
                planSelectionView(
                    planType: .monthly,
                    title: "Monthly",
                    price: paywallManager.monthlyPrice,
                    perMonth: paywallManager.monthlyPerMonth,
                    isRecommended: false
                )
                
                // Yearly Plan
                planSelectionView(
                    planType: .yearly,
                    title: "Yearly",
                    price: paywallManager.yearlyPrice,
                    perMonth: paywallManager.yearlyPerMonth,
                    isRecommended: true,
                    savings: paywallManager.savings
                )
            }
            
            // Action Buttons
            actionButtonsView
        }
    }
    
    // MARK: - Fallback Paywall View
    private var fallbackPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            // Plan Selection (Fallback)
            VStack(spacing: 12) {
                // Monthly Plan (Fallback)
                planSelectionView(
                    planType: .monthly,
                    title: "Monthly",
                    price: paywallManager.monthlyPrice,
                    perMonth: paywallManager.monthlyPerMonth,
                    isRecommended: false,
                    isEnabled: paywallManager.canPurchase
                )
                
                // Yearly Plan (Fallback)
                planSelectionView(
                    planType: .yearly,
                    title: "Yearly",
                    price: paywallManager.yearlyPrice,
                    perMonth: paywallManager.yearlyPerMonth,
                    isRecommended: true,
                    savings: paywallManager.savings,
                    isEnabled: paywallManager.canPurchase
                )
            }
            
            // Error Message
            if let errorMessage = paywallManager.errorMessage {
                errorMessageView(errorMessage)
            }
            
            // Action Buttons
            actionButtonsView
        }
    }
    
    // MARK: - Plan Selection View
    private func planSelectionView(
        planType: PlanType,
        title: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        Button(action: {
            selectedPlan = planType
        }) {
            VStack(spacing: 8) {
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
                    
                    // Selection indicator
                    Image(systemName: selectedPlan == planType ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(selectedPlan == planType ? .blue : .secondary)
                }
                .padding(PaywallConstants.spacing)
                .background(
                    RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
                        .fill(isEnabled ? Color(.systemGray6) : Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
                                .stroke(
                                    selectedPlan == planType ? Color.blue : (isRecommended ? Color.blue.opacity(0.3) : Color.clear),
                                    lineWidth: selectedPlan == planType ? 2 : (isRecommended ? 1 : 0)
                                )
                        )
                )
            }
        }
        .disabled(!isEnabled || paywallManager.isPurchasing)
        .accessibilityLabel("\(title) subscription, \(price)")
        .accessibilityHint(isEnabled ? "Tap to select" : "Subscription not available")
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Retry Button (only show in fallback mode)
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
            
            // Restore Purchases Button
            Button(action: {
                Task {
                    await paywallManager.restorePurchases()
                }
            }) {
                HStack {
                    // Image(systemName: "arrow.clockwise.circle")
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
        .padding(.top, 20)
    }
}


// MARK: - Preview
#Preview {
    RobustPaywallView()
}
