import SwiftUI
import RevenueCat

struct RevenueCatSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var showingCancelConfirmation = false
    @State private var showingRestoreAlert = false
    @State private var restoreSuccess = false
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    private var secondaryColor: Color {
        themeManager.secondaryColor
    }
    
    var body: some View {
        NavigationView {
            List {
                if subscriptionManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else if let errorMessage = subscriptionManager.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await subscriptionManager.loadOfferings()
                        }
                    }
                    .listRowBackground(Color.clear)
                } else if subscriptionManager.isPro {
                    ActiveSubscriptionSection()
                } else {
                    SubscriptionPlansSection()
                }
                
                if !subscriptionManager.isPro {
                    RestorePurchasesSection()
                }
                
                SupportSection()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Restore") {
                    Task {
                        restoreSuccess = await subscriptionManager.restorePurchases()
                    }
                }
            } message: {
                Text("Restore your previous purchases to regain access to Pro features.")
            }
            .alert(restoreSuccess ? "Success" : "No Purchases Found", 
                   isPresented: .constant(restoreSuccess || subscriptionManager.errorMessage?.contains("restore") == true)) {
                Button("OK") { }
            } message: {
                Text(restoreSuccess ? "Your purchases have been restored successfully!" : "No previous purchases found to restore.")
            }
        }
    }
    
    // MARK: - Active Subscription Section
    @ViewBuilder
    private func ActiveSubscriptionSection() -> some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Plan Active")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let expirationDate = subscriptionManager.subscriptionExpirationDate {
                        Text("Expires \(expirationDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if subscriptionManager.isInTrialPeriod {
                        Text("Trial Period")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Subscription Plans Section
    @ViewBuilder
    private func SubscriptionPlansSection() -> some View {
        Section {
            if let offerings = subscriptionManager.offerings?.current {
                ForEach(Array(offerings.availablePackages), id: \.identifier) { package in
                    SubscriptionPlanRow(package: package)
                }
            } else {
                Text("No subscription plans available")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Choose Your Plan")
        } footer: {
            if let savings = subscriptionManager.calculateSavings() {
                Text("Save \(savings) per year with the annual plan!")
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Restore Purchases Section
    @ViewBuilder
    private func RestorePurchasesSection() -> some View {
        Section {
            Button("Restore Purchases") {
                showingRestoreAlert = true
            }
            .foregroundColor(primaryColor)
        } footer: {
            Text("Already have a subscription? Restore your purchases to regain access to Pro features.")
        }
    }
    
    // MARK: - Support Section
    @ViewBuilder
    private func SupportSection() -> some View {
        Section {
            Button("Billing Support") {
                if let url = URL(string: "https://support.revenuecat.com") {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(primaryColor)
            
            Button("Privacy Policy") {
                if let url = URL(string: "https://www.revenuecat.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(primaryColor)
            
            Button("Terms of Service") {
                if let url = URL(string: "https://www.revenuecat.com/terms") {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(primaryColor)
        } header: {
            Text("Support")
        }
    }
}

// MARK: - Subscription Plan Row
struct SubscriptionPlanRow: View {
    let package: RevenueCat.Package
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var isPurchasing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(package.storeProduct.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if package.packageType == .annual, let monthlyPrice = subscriptionManager.monthlyPriceString {
                    Text("\(subscriptionManager.yearlyPerMonthPriceString ?? "")/month")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                    Text(package.storeProduct.localizedPriceString)
                    .font(.headline)
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
            
            Button(action: {
                Task {
                    isPurchasing = true
                    let success = await subscriptionManager.purchase(package: package)
                    isPurchasing = false
                }
            }) {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Subscribe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || subscriptionManager.isLoading)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    // Create a simple preview that doesn't rely on complex initialization
    NavigationView {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Plan")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Monthly Subscription")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$9.99")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("per month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Subscribe") {
                        // Preview action
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Choose Your Plan")
            }
            
            Section {
                Button("Restore Purchases") {
                    // Preview action
                }
                .foregroundColor(.primary)
            } footer: {
                Text("Already have a subscription? Restore your purchases to regain access to Pro features.")
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}
