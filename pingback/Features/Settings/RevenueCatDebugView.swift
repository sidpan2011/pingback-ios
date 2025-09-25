import SwiftUI
import RevenueCat

struct RevenueCatDebugView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var debugInfo: [String] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("RevenueCat Status") {
                    DebugRow(title: "SDK Configured", value: "\(Purchases.isConfigured)")
                    DebugRow(title: "Is Loading", value: "\(subscriptionManager.isLoading)")
                    DebugRow(title: "Has Offerings", value: "\(subscriptionManager.hasOfferings)")
                    DebugRow(title: "Is Pro", value: "\(subscriptionManager.isPro)")
                    if let error = subscriptionManager.errorMessage {
                        DebugRow(title: "Error", value: error)
                    }
                }
                
                Section("Offerings") {
                    DebugRow(title: "Current Offering", value: subscriptionManager.offerings?.current?.identifier ?? "None")
                    DebugRow(title: "Available Packages", value: "\(subscriptionManager.offerings?.current?.availablePackages.count ?? 0)")
                    
                    if let packages = subscriptionManager.offerings?.current?.availablePackages {
                        ForEach(packages, id: \.identifier) { package in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Package: \(package.identifier)")
                                    .font(.headline)
                                Text("Product ID: \(package.storeProduct.productIdentifier)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Title: \(package.storeProduct.localizedTitle)")
                                    .font(.caption)
                                Text("Price: \(package.storeProduct.localizedPriceString)")
                                    .font(.caption)
                                Text("Type: \(package.packageType.debugDescription)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("Product Configuration") {
                    DebugRow(title: "Monthly Product ID", value: RevenueCatConfiguration.ProductIdentifiers.monthly)
                    DebugRow(title: "Yearly Product ID", value: RevenueCatConfiguration.ProductIdentifiers.yearly)
                    DebugRow(title: "Pro Entitlement", value: RevenueCatConfiguration.Entitlements.pro)
                }
                
                Section("Convenience Properties") {
                    DebugRow(title: "Monthly Package", value: subscriptionManager.monthlyPackage?.identifier ?? "nil")
                    DebugRow(title: "Yearly Package", value: subscriptionManager.yearlyPackage?.identifier ?? "nil")
                    DebugRow(title: "Monthly Price", value: subscriptionManager.monthlyPriceString ?? "nil")
                    DebugRow(title: "Yearly Price", value: subscriptionManager.yearlyPriceString ?? "nil")
                    DebugRow(title: "Savings", value: subscriptionManager.calculateSavings() ?? "nil")
                }
                
                Section("Actions") {
                    Button("Reload Offerings") {
                        Task {
                            await subscriptionManager.loadOfferings()
                        }
                    }
                    
                    Button("Test SDK Connection") {
                        RevenueCatConfiguration.testSDKConnection()
                    }
                    
                    Button("Print Customer Info") {
                        RevenueCatConfiguration.printCustomerInfo()
                    }
                }
                
                if !debugInfo.isEmpty {
                    Section("Debug Log") {
                        ForEach(debugInfo, id: \.self) { info in
                            Text(info)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("RevenueCat Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            Task {
                await subscriptionManager.loadOfferings()
            }
        }
    }
}

struct DebugRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    RevenueCatDebugView()
}