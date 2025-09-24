import SwiftUI
import SafariServices

struct iPadFallbackPaywallView: View {
    @StateObject private var fallbackManager = FallbackPaywallManager()
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
        .onAppear {
            fallbackManager.startListeningForUpdates()
        }
        .onDisappear {
            fallbackManager.stopListeningForUpdates()
        }
    }
    
    // MARK: - Full Layout (Portrait)
    private func fullLayout(geometry: GeometryProxy) -> some View {
        NavigationStack {
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
                .padding(.horizontal, max(PaywallConstants.horizontalPadding, geometry.size.width * 0.1))
                .padding(.vertical, PaywallConstants.spacing)
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
    }
    
    // MARK: - Compact Layout (Split View/Landscape)
    private func compactLayout(geometry: GeometryProxy) -> some View {
        NavigationStack {
            VStack(spacing: PaywallConstants.spacing) {
                headerView
                    .padding(.top, 10)
                
                if fallbackManager.isLoading {
                    loadingView
                } else {
                    mainPaywallView
                }
                
                Spacer()
                
                footerView
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, PaywallConstants.horizontalPadding)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: isCompactWidth ? 8 : 16) {
            // App Icon
            Image(systemName: "star.fill")
                .font(.system(size: isCompactWidth ? 32 : 48))
                .foregroundColor(.blue)
                .frame(width: isCompactWidth ? 80 : 120, height: isCompactWidth ? 80 : 120)
                .background(
                    RoundedRectangle(cornerRadius: isCompactWidth ? 16 : 24)
                        .fill(Color(.systemGray6))
                )
                .shadow(color: .black.opacity(0.2), radius: isCompactWidth ? 8 : 15, x: 0, y: isCompactWidth ? 4 : 8)
            
            // App Name
            Text("Pingback Pro")
                .font(isCompactWidth ? .title2 : .largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            if isCompactWidth {
                // Horizontal layout for compact width
                HStack(spacing: PaywallConstants.spacing) {
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
            } else {
                // Vertical layout for full width
                VStack(spacing: 12) {
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
            }
            
            ProgressView("Loading subscription options...")
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
    }
    
    // MARK: - Main Paywall View
    private var mainPaywallView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            if isCompactWidth {
                // Horizontal layout for compact width
                HStack(spacing: PaywallConstants.spacing) {
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
            } else {
                // Vertical layout for full width
                VStack(spacing: 12) {
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
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(isCompactWidth ? .subheadline : .headline)
                                .fontWeight(.semibold)
                            
                            if isRecommended {
                                Text("Best value")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(price)
                            .font(isCompactWidth ? .title3 : .title2)
                            .fontWeight(.bold)
                            .foregroundColor(isAvailable ? .primary : .secondary)
                        
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
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: fallbackManager.selectedPlan == planType ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(
                            fallbackManager.selectedPlan == planType ? .blue : 
                            (isAvailable ? .secondary : .gray)
                        )
                }
                .padding(isCompactWidth ? 12 : PaywallConstants.spacing)
                .background(
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
                )
            }
        }
        .disabled(!isAvailable || fallbackManager.isPurchasing)
        .opacity(isAvailable ? 1.0 : 0.6)
        .accessibilityLabel("\(title) subscription, \(price)")
        .accessibilityHint(isAvailable ? "Tap to select" : "Subscription not available")
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
                    } else {
                        Image(systemName: "star.fill")
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
    }
}

// MARK: - Preview
#Preview {
    iPadFallbackPaywallView()
}
