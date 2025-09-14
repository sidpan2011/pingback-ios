import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var showingCancelConfirmation = false
    
    private var subscriptionStatus: SubscriptionStatus {
        if subscriptionManager.isPro {
            return .active
        } else {
            return .expired
        }
    }
    
    enum SubscriptionStatus {
        case active
        case cancelled
        case expired
        
        var title: String {
            switch self {
            case .active: return "Active Subscription"
            case .cancelled: return "Cancelled Subscription"
            case .expired: return "No Active Subscription"
            }
        }
        
        var color: Color {
            switch self {
            case .active: return .green
            case .cancelled: return .orange
            case .expired: return .red
            }
        }
    }
    
    // Removed theme color overrides for instant theme switching
    
    var body: some View {
        List {
                // Status Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscriptionStatus.title)
                                .foregroundColor(.primary)
                            
                           
                        }
                        
                        Spacer()
                         Text("Pro Plan")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        
                        // Circle()
                        //     .fill(subscriptionStatus.color)
                        //     .frame(width: 12, height: 12)
                    }
                    // .padding(.vertical, 8)
                }
                
                // Plan Details
                Section("Plan Details") {
                    HStack {
                        Text("Plan")
                        Spacer()
                        Text("Pro")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        Text(subscriptionManager.monthlyPriceString ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    
                    if let expirationDate = subscriptionManager.subscriptionExpirationDate {
                        HStack {
                            Text("Next Billing")
                            Spacer()
                            Text(expirationDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Text("•••• 1234")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions
                Section {
                    if subscriptionStatus == .active {
                        Button("Manage Subscription") {
                            // Open App Store subscription management
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Button("Cancel Subscription") {
                            showingCancelConfirmation = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Subscribe to Pro") {
                            // This would open the subscription flow
                            // You can navigate to RevenueCatSubscriptionView here
                        }
                        .foregroundColor(.green)
                    }
                }
                
                // Help Section
                Section {
                    Button("Billing Support") {
                        if let url = URL(string: "https://support.revenuecat.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Support")
                } footer: {
                    Text("Need help with your subscription? Contact our support team or restore your purchases.")
                }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
            .alert("Cancel Subscription", isPresented: $showingCancelConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Manage in App Store") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("To cancel your subscription, please manage it through the App Store. You'll lose access to Pro features at the end of your current billing period.")
            }
    }
}

#Preview {
    SubscriptionView()
}
