import SwiftUI
import SafariServices

struct FallbackPaywallView: View {
    @StateObject private var fallbackManager = FallbackPaywallManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: PaywallConstants.spacing) {
                        headerView
                        
                        if fallbackManager.isLoading {
                            loadingView
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
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: PaywallConstants.privacyURL)!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: PaywallConstants.termsURL)!)
        }
        .onAppear {
            fallbackManager.startListeningForUpdates()
        }
        .onDisappear {
            fallbackManager.stopListeningForUpdates()
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
            Text("Pingback Pro")
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            VStack(spacing: 12) {
                // Monthly Plan (Loading)
                planCardView(
                    planType: .monthly,
                    title: "Monthly",
                    subtitle: "Auto-renews monthly",
                    price: "Loading price…",
                    perMonth: "",
                    isRecommended: false,
                    isAvailable: false,
                    unavailableReason: nil
                )
                
                // Yearly Plan (Loading)
                planCardView(
                    planType: .yearly,
                    title: "Yearly",
                    subtitle: "Auto-renews yearly",
                    price: "Loading price…",
                    perMonth: "",
                    isRecommended: true,
                    isAvailable: false,
                    unavailableReason: nil
                )
            }
            
            ProgressView("Loading subscription options...")
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
    }
    
    // MARK: - Main Paywall View
    private var mainPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            // Plan Selection
            VStack(spacing: 12) {
                // Monthly Plan
                planCardView(
                    planType: .monthly,
                    title: "Monthly",
                    subtitle: "Auto-renews monthly",
                    price: fallbackManager.monthlyPrice,
                    perMonth: fallbackManager.monthlyPerMonth,
                    isRecommended: false,
                    isAvailable: fallbackManager.monthlyAvailable,
                    unavailableReason: fallbackManager.monthlyUnavailableReason
                )
                
                // Yearly Plan
                planCardView(
                    planType: .yearly,
                    title: "Yearly",
                    subtitle: "Auto-renews yearly",
                    price: fallbackManager.yearlyPrice,
                    perMonth: fallbackManager.yearlyPerMonth,
                    isRecommended: true,
                    savings: fallbackManager.savings,
                    isAvailable: fallbackManager.yearlyAvailable,
                    unavailableReason: fallbackManager.yearlyUnavailableReason
                )
            }
            
            // Inline Message Area
            if let errorMessage = fallbackManager.errorMessage {
                inlineMessageView(errorMessage)
            }
            
            // Action Buttons
            actionButtonsView
        }
    }
    
    // MARK: - Plan Card View
    private func planCardView(
        planType: FallbackPaywallManager.PlanType,
        title: String,
        subtitle: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isAvailable: Bool,
        unavailableReason: String?
    ) -> some View {
        Button(action: {
            if isAvailable {
                fallbackManager.selectedPlan = planType
            }
        }) {
            planCardContent(
                planType: planType,
                title: title,
                subtitle: subtitle,
                price: price,
                perMonth: perMonth,
                isRecommended: isRecommended,
                savings: savings,
                isAvailable: isAvailable,
                unavailableReason: unavailableReason
            )
        }
        .disabled(!isAvailable || fallbackManager.isPurchasing)
        .opacity(isAvailable ? 1.0 : 0.6)
        .accessibilityLabel("\(title) subscription, \(price)")
        .accessibilityHint(isAvailable ? "Tap to select" : "Subscription not available")
    }
    
    private func planCardContent(
        planType: FallbackPaywallManager.PlanType,
        title: String,
        subtitle: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isAvailable: Bool,
        unavailableReason: String?
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                planInfoSection(
                    title: title,
                    subtitle: subtitle,
                    price: price,
                    perMonth: perMonth,
                    isRecommended: isRecommended,
                    savings: savings,
                    isAvailable: isAvailable,
                    unavailableReason: unavailableReason
                )
                
                Spacer()
                
                planSelectionIndicator(planType: planType, isAvailable: isAvailable)
            }
            .padding(PaywallConstants.spacing)
            .background(planCardBackground(planType: planType, isRecommended: isRecommended, isAvailable: isAvailable))
        }
    }
    
    private func planInfoSection(
        title: String,
        subtitle: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isAvailable: Bool,
        unavailableReason: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            planTitleRow(title: title, isRecommended: isRecommended)
            planSubtitle(subtitle: subtitle)
            planPrice(price: price, isAvailable: isAvailable)
            planDetails(perMonth: perMonth, savings: savings, unavailableReason: unavailableReason)
        }
    }
    
    private func planTitleRow(title: String, isRecommended: Bool) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            if isRecommended {
                Text("Best value")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
        }
    }
    
    private func planSubtitle(subtitle: String) -> some View {
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private func planPrice(price: String, isAvailable: Bool) -> some View {
        Text(price)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(isAvailable ? .primary : .secondary)
    }
    
    private func planDetails(perMonth: String, savings: String?, unavailableReason: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
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
            
            if let reason = unavailableReason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func planSelectionIndicator(planType: FallbackPaywallManager.PlanType, isAvailable: Bool) -> some View {
        Image(systemName: fallbackManager.selectedPlan == planType ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundColor(
                fallbackManager.selectedPlan == planType ? .blue : 
                (isAvailable ? .secondary : .gray)
            )
    }
    
    private func planCardBackground(planType: FallbackPaywallManager.PlanType, isRecommended: Bool, isAvailable: Bool) -> some View {
        RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
            .fill(isAvailable ? Color(.systemGray6) : Color(.systemGray5))
            .overlay(
                RoundedRectangle(cornerRadius: PaywallConstants.cornerRadius)
                    .stroke(
                        fallbackManager.selectedPlan == planType ? Color.blue : 
                        (isRecommended ? Color.blue.opacity(0.3) : Color.clear),
                        lineWidth: fallbackManager.selectedPlan == planType ? 2 : 
                        (isRecommended ? 1 : 0)
                    )
            )
    }
    
    // MARK: - Inline Message View
    private func inlineMessageView(_ message: String) -> some View {
        let isTestingMode = fallbackManager.isUsingMockPrices
        let iconName = isTestingMode ? "testtube.2" : (message.contains("internet") ? "wifi.slash" : "exclamationmark.triangle.fill")
        let iconColor = isTestingMode ? Color.blue : Color.orange
        let backgroundColor = isTestingMode ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1)
        
        return HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, PaywallConstants.spacing)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Primary CTA Button
            Button(action: {
                Task {
                    await fallbackManager.purchaseSelectedPlan()
                }
            }) {
                HStack {
                    if fallbackManager.isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    
                    Text(fallbackManager.isPurchasing ? "Processing..." : "Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: PaywallConstants.buttonHeight)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(PaywallConstants.cornerRadius)
            }
            .disabled(fallbackManager.isPurchasing || !fallbackManager.canContinue)
            .accessibilityLabel("Continue with \(fallbackManager.selectedPlan.rawValue) subscription")
            .accessibilityHint(fallbackManager.canContinue ? "Tap to continue" : "Price required to continue")
            
            // Price Required Note
            if !fallbackManager.canContinue {
                Text("Price required to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Secondary Actions
            HStack(spacing: 12) {
                // Try Again Button
                Button(action: {
                    Task {
                        await fallbackManager.retry()
                    }
                }) {
                    HStack {
                        if fallbackManager.isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: PaywallConstants.buttonHeight)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(PaywallConstants.cornerRadius)
                }
                .disabled(fallbackManager.isRetrying)
                .accessibilityLabel("Try again to load subscription options")
                
                // Restore Purchases Button
                Button(action: {
                    Task {
                        await fallbackManager.restorePurchases()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: PaywallConstants.buttonHeight)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(PaywallConstants.cornerRadius)
                }
                .disabled(fallbackManager.isPurchasing)
                .accessibilityLabel("Restore previous purchases")
            }
        }
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
    FallbackPaywallView()
}
