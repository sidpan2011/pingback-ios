import SwiftUI
import RevenueCat

struct RevenueCatUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedPlan: PlanType = .yearly
    
    enum PlanType: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
            ScrollView {
                    VStack(spacing: PaywallConstants.spacing) {
                        headerView
                        
                    if subscriptionManager.isLoading {
                            loadingView
                    } else if let errorMessage = subscriptionManager.errorMessage {
                            errorView(errorMessage)
                        } else if let offerings = subscriptionManager.offerings,
                                  let current = offerings.current {
                            mainPaywallView(offerings: current)
                        } else {
                            noOfferingsView
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
        .alert("Purchase Status", isPresented: $showingAlert) {
            Button("OK") { }
            } message: { 
                Text(alertMessage) 
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
            ProgressView("Loading subscription options...")
                .frame(maxWidth: .infinity)
                .frame(height: 100)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: PaywallConstants.spacing) {
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
            
            Button("Retry") {
                Task {
                    await subscriptionManager.loadOfferings()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: PaywallConstants.buttonHeight)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(PaywallConstants.cornerRadius)
        }
    }
    
    // MARK: - Main Paywall View
    private func mainPaywallView(offerings: Offering) -> some View {
        VStack(spacing: PaywallConstants.spacing) {
            // Plan Selection
            VStack(spacing: 12) {
                // Monthly Plan
                if let monthlyPackage = offerings.monthly {
                    planSelectionView(
                        planType: .monthly,
                        package: monthlyPackage,
                        title: "Monthly",
                        price: monthlyPackage.storeProduct.localizedPriceString,
                        perMonth: monthlyPackage.storeProduct.localizedPriceString + "/month",
                        isRecommended: false
                    )
                }
                
                // Yearly Plan
                if let yearlyPackage = offerings.annual {
                    planSelectionView(
                        planType: .yearly,
                        package: yearlyPackage,
                        title: "Yearly",
                        price: yearlyPackage.storeProduct.localizedPriceString,
                        perMonth: subscriptionManager.yearlyPerMonthPriceString ?? "",
                        isRecommended: true,
                        savings: subscriptionManager.calculateSavings()
                    )
                }
            }
            
            // Action Buttons
            actionButtonsView
        }
    }
    
    // MARK: - No Offerings View
    private var noOfferingsView: some View {
        VStack(spacing: PaywallConstants.spacing) {
            VStack(spacing: 12) {
                // Monthly Plan (Placeholder)
                planSelectionView(
                    planType: .monthly,
                    package: nil,
                    title: "Monthly",
                    price: "Loading price…",
                    perMonth: "",
                    isRecommended: false,
                    isEnabled: false
                )
                
                // Yearly Plan (Placeholder)
                planSelectionView(
                    planType: .yearly,
                    package: nil,
                    title: "Yearly",
                    price: "Loading price…",
                    perMonth: "",
                    isRecommended: true,
                    isEnabled: false
                )
            }
            
            Button("Retry") {
                Task {
                    await subscriptionManager.loadOfferings()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: PaywallConstants.buttonHeight)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(PaywallConstants.cornerRadius)
            
            // Action Buttons
            actionButtonsView
        }
    }
    
    // MARK: - Plan Selection View
    private func planSelectionView(
        planType: PlanType,
        package: Package?,
        title: String,
        price: String,
        perMonth: String,
        isRecommended: Bool,
        savings: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        Button(action: {
            selectedPlan = planType
            selectedPackage = package
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
        .disabled(!isEnabled || isPurchasing)
        .accessibilityLabel("\(title) subscription, \(price)")
        .accessibilityHint(isEnabled ? "Tap to select" : "Subscription not available")
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Purchase Button
            Button(action: {
                guard let package = selectedPackage else { return }
                Task {
                    await purchasePackage(package)
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "star.fill")
                    }
                    
                    Text(isPurchasing ? "Processing..." : "Start Free Trial")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: PaywallConstants.buttonHeight)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(PaywallConstants.cornerRadius)
            }
            .disabled(isPurchasing || selectedPackage == nil)
            .accessibilityLabel(selectedPlan == .monthly ? PaywallConstants.Accessibility.monthlyButton : PaywallConstants.Accessibility.yearlyButton)
            
            // Restore Purchases Button
            Button(action: {
                Task {
                    await restorePurchases()
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
            .disabled(isPurchasing)
            .accessibilityLabel(PaywallConstants.Accessibility.restoreButton)
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
                    if let url = URL(string: PaywallConstants.privacyURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityLabel(PaywallConstants.Accessibility.privacyLink)
                
                Button("Terms") {
                    if let url = URL(string: PaywallConstants.termsURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityLabel(PaywallConstants.Accessibility.termsLink)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Purchase Functions
    private func purchasePackage(_ package: Package) async {
        isPurchasing = true
        alertMessage = ""
        
        do {
            let success = await subscriptionManager.purchase(package: package)
            if success {
                alertMessage = "Purchase successful! Welcome to Pro!"
                showingAlert = true
                dismiss()
            } else {
                alertMessage = "Purchase failed. Please try again."
                showingAlert = true
            }
        }
        
        isPurchasing = false
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        alertMessage = ""
        
        do {
            let success = await subscriptionManager.restorePurchases()
            if success {
                alertMessage = "Purchases restored successfully!"
                showingAlert = true
                dismiss()
            } else {
                alertMessage = "No purchases found to restore."
                showingAlert = true
            }
        }
        
        isPurchasing = false
    }
}

#Preview {
    RevenueCatUpgradeView()
}