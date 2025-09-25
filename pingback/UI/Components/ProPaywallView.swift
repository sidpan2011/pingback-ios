import SwiftUI
import RevenueCat

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPlan: PlanType = .yearly
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum PlanType: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    
                    if subscriptionManager.isLoading {
                        loadingView
                    } else {
                        featuresView
                        plansView
                        actionButtonsView
                    }
                    
                    footerView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            // .navigationTitle("Upgrade to Pro")
            // .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("Purchase", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // App Icon
            if let uiImage = UIImage(named: "AppIcon") {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
}
            
            // Title and Subtitle
            VStack(spacing: 8) {
                Text("Pingback Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get the most out of Pingback with premium features")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading subscription options...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - Plans View
    private var plansView: some View {
        VStack(spacing: 12) {
            if let monthlyPackage = subscriptionManager.monthlyPackage,
               let yearlyPackage = subscriptionManager.yearlyPackage {
                // RevenueCat packages available
                VStack(spacing: 12) {
                    planCard(
                        planType: .monthly,
                        package: monthlyPackage,
                        isRecommended: false
                    )
                    
                    planCard(
                        planType: .yearly,
                        package: yearlyPackage,
                        isRecommended: true,
                        savings: subscriptionManager.calculateSavings()
                    )
                }
            } else {
                // Fallback to product IDs
                VStack(spacing: 12) {
                    planCardFallback(
                        planType: .monthly,
                        productId: RevenueCatConfiguration.ProductIdentifiers.monthly,
                        isRecommended: false
                    )
                    
                    planCardFallback(
                        planType: .yearly,
                        productId: RevenueCatConfiguration.ProductIdentifiers.yearly,
                        isRecommended: true
                    )
                }
            }
        }
    }
    
    // MARK: - Plan Card (RevenueCat Package)
    private func planCard(
        planType: PlanType,
        package: Package,
        isRecommended: Bool,
        savings: String? = nil
    ) -> some View {
        Button(action: {
            selectedPlan = planType
        }) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(planType == .monthly ? "Monthly" : "Yearly")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if isRecommended {
                                Text("Best Value")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(planType == .monthly ? "Auto-renews monthly" : "Auto-renews yearly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(package.storeProduct.localizedPriceString)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if planType == .yearly, let perMonth = subscriptionManager.yearlyPerMonthPriceString {
                            Text(perMonth + " per month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let savings = savings, !savings.isEmpty {
                            Text("Save " + savings)
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
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedPlan == planType ? Color.blue : 
                                    (isRecommended ? Color.blue.opacity(0.3) : Color.clear),
                                    lineWidth: selectedPlan == planType ? 2 : 
                                    (isRecommended ? 1 : 0)
                                )
                        )
                )
            }
        }
        .disabled(subscriptionManager.isLoading || !subscriptionManager.hasOfferings)
    }
    
    // MARK: - Plan Card Fallback (Product ID)
    private func planCardFallback(
        planType: PlanType,
        productId: String,
        isRecommended: Bool
    ) -> some View {
        Button(action: {
            selectedPlan = planType
        }) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(planType == .monthly ? "Monthly" : "Yearly")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if isRecommended {
                                Text("Best Value")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(planType == .monthly ? "Auto-renews monthly" : "Auto-renews yearly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Loading price...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: selectedPlan == planType ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(selectedPlan == planType ? .blue : .secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedPlan == planType ? Color.blue : 
                                    (isRecommended ? Color.blue.opacity(0.3) : Color.clear),
                                    lineWidth: selectedPlan == planType ? 2 : 
                                    (isRecommended ? 1 : 0)
                                )
                        )
                )
            }
        }
        .disabled(subscriptionManager.isLoading || !subscriptionManager.hasOfferings)
    }
    
    // MARK: - Features View
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Text("Pro Features")
            //     .font(.headline)
            //     .fontWeight(.semibold)
            
            // Carousel of features
            TabView {
                ForEach(Array(FeatureCatalog.proFeatureDescriptions.enumerated()), id: \.offset) { index, feature in
                    featureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 250)
            .onAppear {
                // Customize page indicator appearance for better visibility
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.systemBlue
                UIPageControl.appearance().pageIndicatorTintColor = UIColor.systemGray3
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func featureCard(feature: ProFeatureDescription) -> some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Title and Description
            VStack(spacing: 6) {
                Text(feature.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Primary CTA Button
            Button(action: {
                Task {
                    await purchaseSelectedPlan()
                }
            }) {
                ZStack {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    if subscriptionManager.isLoading || !subscriptionManager.hasOfferings {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.8))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .disabled(subscriptionManager.isLoading || !subscriptionManager.hasOfferings)
            
            // Restore Purchases Button
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                HStack {
                    // Image(systemName: "arrow.clockwise.circle")
                    Text("Restore Purchases")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(subscriptionManager.isLoading || !subscriptionManager.hasOfferings)
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        VStack(spacing: 8) {
            Text(FeatureCatalog.complianceText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Terms of Service") {
                    // Open terms of service
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSelectedPlan() async {
        if let monthlyPackage = subscriptionManager.monthlyPackage,
           let yearlyPackage = subscriptionManager.yearlyPackage {
            // Use RevenueCat packages
            let package = selectedPlan == .monthly ? monthlyPackage : yearlyPackage
            let success = await subscriptionManager.purchase(package: package)
            
            if success {
                dismiss()
            } else if let error = subscriptionManager.errorMessage {
                alertMessage = error
                showingAlert = true
            }
        } else {
            // Fallback to product IDs
            let productId = selectedPlan == .monthly ? 
                RevenueCatConfiguration.ProductIdentifiers.monthly : 
                RevenueCatConfiguration.ProductIdentifiers.yearly
            
            let success = await subscriptionManager.purchase(productId: productId)
            
            if success {
                dismiss()
            } else if let error = subscriptionManager.errorMessage {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private func restorePurchases() async {
        let success = await subscriptionManager.restorePurchases()
        
        if success {
            alertMessage = "Purchases restored successfully!"
            showingAlert = true
            dismiss()
        } else if let error = subscriptionManager.errorMessage {
            alertMessage = error
            showingAlert = true
        }
    }
}

#Preview {
    ProPaywallView()
        .environmentObject(SubscriptionManager.shared)
}
