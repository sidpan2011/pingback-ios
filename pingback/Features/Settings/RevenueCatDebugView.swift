import SwiftUI
import RevenueCat

struct RevenueCatDebugView: View {
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var debugInfo: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                // Connection Status Section
                Section("Connection Status") {
                    HStack {
                        Text("SDK Configured")
                        Spacer()
                        Text(Purchases.isConfigured ? "✅ Yes" : "❌ No")
                            .foregroundColor(Purchases.isConfigured ? .green : .red)
                    }
                    
                    HStack {
                        Text("SDK Connected")
                        Spacer()
                        Text(revenueCatManager.isSDKConnected ? "✅ Yes" : "❌ No")
                            .foregroundColor(revenueCatManager.isSDKConnected ? .green : .red)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(revenueCatManager.connectionStatus)
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = revenueCatManager.errorMessage {
                        VStack(alignment: .leading) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Configuration Section
                Section("Configuration") {
                    HStack {
                        Text("API Key")
                        Spacer()
                        Text(RevenueCatConfiguration.apiKey.prefix(20) + "...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App User ID")
                        Spacer()
                        Text(Purchases.shared.appUserID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Monthly Product ID")
                        Spacer()
                        Text(RevenueCatConfiguration.ProductIdentifiers.monthly)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Yearly Product ID")
                        Spacer()
                        Text(RevenueCatConfiguration.ProductIdentifiers.yearly)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Offerings Section
                Section("Offerings") {
                    if let offerings = revenueCatManager.offerings {
                        HStack {
                            Text("Current Offering")
                            Spacer()
                            Text(offerings.current?.identifier ?? "None")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Available Packages")
                            Spacer()
                            Text("\(offerings.current?.availablePackages.count ?? 0)")
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(Array(offerings.current?.availablePackages ?? []), id: \.identifier) { package in
                            VStack(alignment: .leading) {
                                Text(package.storeProduct.localizedTitle)
                                    .font(.subheadline)
                                Text("ID: \(package.identifier)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Price: \(package.storeProduct.localizedPriceString)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    } else {
                        Text("No offerings loaded")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Customer Info Section
                Section("Customer Info") {
                    if let customerInfo = revenueCatManager.customerInfo {
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(customerInfo.originalAppUserId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Pro Status")
                            Spacer()
                            Text(revenueCatManager.isPro ? "✅ Active" : "❌ Inactive")
                                .foregroundColor(revenueCatManager.isPro ? .green : .red)
                        }
                        
                        HStack {
                            Text("Active Entitlements")
                            Spacer()
                            Text("\(customerInfo.entitlements.active.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        if let managementURL = customerInfo.managementURL {
                            HStack {
                                Text("Management URL")
                                Spacer()
                                Text("Available")
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        Text("No customer info loaded")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Refresh Offerings") {
                        Task {
                            await revenueCatManager.loadOfferings()
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("Refresh Customer Info") {
                        Task {
                            await revenueCatManager.checkSubscriptionStatus()
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("Print Debug Info") {
                        RevenueCatConfiguration.printCustomerInfo()
                    }
                    
                    Button("Test SDK Connection") {
                        RevenueCatConfiguration.testSDKConnection()
                    }
                }
                
                // Debug Log Section
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
            .onAppear {
                Task {
                    isLoading = true
                    await revenueCatManager.loadOfferings()
                    await revenueCatManager.checkSubscriptionStatus()
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    RevenueCatDebugView()
}
