import SwiftUI
import RevenueCat

struct RevenueCatUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Unlock all premium features and take your productivity to the next level")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", title: "Unlimited Follow-ups", description: "Create as many follow-ups as you need")
                    FeatureRow(icon: "bell.fill", title: "Advanced Notifications", description: "Customize notification timing and frequency")
                    FeatureRow(icon: "chart.bar.fill", title: "Analytics & Insights", description: "Track your follow-up success rates")
                    FeatureRow(icon: "icloud.fill", title: "Cloud Sync", description: "Sync across all your devices")
                    FeatureRow(icon: "paintbrush.fill", title: "Custom Themes", description: "Personalize your app experience")
                    FeatureRow(icon: "headphones", title: "Priority Support", description: "Get help when you need it most")
                }
                .padding(.horizontal)
                
                // Pricing Cards
                if subscriptionManager.hasOfferings {
                    VStack(spacing: 16) {
                        if let monthly = subscriptionManager.monthlyPackage {
                            PricingCard(
                                package: monthly,
                                isSelected: selectedPackage?.identifier == monthly.identifier,
                                isPopular: false
                            ) {
                                selectedPackage = monthly
                            }
                        }
                        
                        if let yearly = subscriptionManager.yearlyPackage {
                            PricingCard(
                                package: yearly,
                                isSelected: selectedPackage?.identifier == yearly.identifier,
                                isPopular: true
                            ) {
                                selectedPackage = yearly
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Purchase Button
                if let package = selectedPackage {
                    Button(action: {
                        Task {
                            isPurchasing = true
                            let success = await subscriptionManager.purchase(package: package)
                            isPurchasing = false
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text("Start Free Trial")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing || subscriptionManager.isLoading)
                    .padding(.horizontal)
                }
                
                // Restore Purchases
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
                .foregroundColor(.blue)
                .padding(.bottom, 20)
                
                // Terms and Privacy
                VStack(spacing: 8) {
                    Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        Button("Terms of Service") {
                            if let url = URL(string: "https://www.revenuecat.com/terms") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("Privacy Policy") {
                            if let url = URL(string: "https://www.revenuecat.com/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
        .onAppear {
            if selectedPackage == nil {
                selectedPackage = subscriptionManager.yearlyPackage ?? subscriptionManager.monthlyPackage
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let package: Package
    let isSelected: Bool
    let isPopular: Bool
    let onTap: () -> Void
    
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if isPopular {
                                Text("POPULAR")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(package.storeProduct.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if package.packageType == .annual {
                            Text("per year")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("per month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if package.packageType == .annual, let monthlyPrice = subscriptionManager.monthlyPriceString {
                    Text("\(subscriptionManager.yearlyPerMonthPriceString ?? "")/month")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RevenueCatUpgradeView()
}
