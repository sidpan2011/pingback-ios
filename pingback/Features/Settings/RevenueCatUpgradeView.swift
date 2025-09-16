import SwiftUI
import RevenueCat

struct RevenueCatUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = RevenueCatManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Feature carousel
    struct Feature: Identifiable { 
        let id = UUID()
        let title: String
        let subtitle: String
        let symbol: String
    }
    
    private let features: [Feature] = [
        .init(title: "Unlimited Follow-ups", subtitle: "Create as many follow-ups as you need", symbol: "infinity"),
        .init(title: "Advanced Notifications", subtitle: "Customize notification timing and frequency", symbol: "bell.badge.fill"),
        .init(title: "Analytics & Insights", subtitle: "Track your follow-up success rates", symbol: "chart.bar.fill"),
        .init(title: "Cloud Sync", subtitle: "Sync across all your devices", symbol: "icloud.fill"),
        .init(title: "Custom Themes", subtitle: "Personalize your app experience", symbol: "paintbrush.fill"),
        .init(title: "Priority Support", subtitle: "Get help when you need it most", symbol: "headphones")
    ]
    @State private var featureIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: Feature carousel
                    TabView(selection: $featureIndex) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 16) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 80))
                                    .foregroundColor(.primary)

                                Text(item.title)
                                    .font(.title3).bold()
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .tag(index)
                        }
                    }
                    .frame(height: 260)
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .tint(.secondary)

                    // MARK: Billing options (side‑by‑side cards)
                    if subscriptionManager.isLoading {
                        ProgressView("Loading plans...")
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if let errorMessage = subscriptionManager.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Unable to load plans")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task {
                                    await subscriptionManager.loadOfferings()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding()
                    } else if subscriptionManager.hasOfferings {
                        HStack(spacing: 16) {
                            if let yearly = subscriptionManager.yearlyPackage {
                                PlanOptionCard(
                                    title: "Pay Yearly",
                                    priceText: yearly.storeProduct.localizedPriceString,
                                    subText: "billed yearly",
                                    isSelected: selectedPackage?.identifier == yearly.identifier,
                                    saveBadge: subscriptionManager.calculateSavings(),
                                    primaryColor: .primary,
                                    onTap: { selectedPackage = yearly }
                                )
                            }

                            if let monthly = subscriptionManager.monthlyPackage {
                                PlanOptionCard(
                                    title: "Pay Monthly",
                                    priceText: monthly.storeProduct.localizedPriceString,
                                    subText: "billed monthly",
                                    isSelected: selectedPackage?.identifier == monthly.identifier,
                                    saveBadge: nil,
                                    primaryColor: .primary,
                                    onTap: { selectedPackage = monthly }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No plans available")
                                .font(.headline)
                            Text("Please check your internet connection and try again")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await subscriptionManager.loadOfferings()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding()
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100) // leave room for sticky button
            }
            .navigationTitle("Pro Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .topBarLeading) { 
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundColor(.primary)
                } 
            }
            .safeAreaInset(edge: .bottom) { stickyCTA }
            .alert("Error", isPresented: $showingAlert) { 
                Button("OK") {} 
            } message: { 
                Text(alertMessage) 
            }
            .onAppear {
                print("🔵 RevenueCatUpgradeView: View appeared")
                print("🔵 RevenueCat isLoading: \(subscriptionManager.isLoading)")
                print("🔵 RevenueCat hasOfferings: \(subscriptionManager.hasOfferings)")
                print("🔵 RevenueCat errorMessage: \(subscriptionManager.errorMessage ?? "None")")
                print("🔵 RevenueCat connectionStatus: \(subscriptionManager.connectionStatus)")
                
                Task {
                    print("🔵 Loading offerings...")
                    await subscriptionManager.loadOfferings()
                    print("🔵 After loading - hasOfferings: \(subscriptionManager.hasOfferings)")
                    print("🔵 After loading - monthlyPackage: \(subscriptionManager.monthlyPackage?.identifier ?? "nil")")
                    print("🔵 After loading - yearlyPackage: \(subscriptionManager.yearlyPackage?.identifier ?? "nil")")
                }
                if selectedPackage == nil {
                    selectedPackage = subscriptionManager.yearlyPackage ?? subscriptionManager.monthlyPackage
                }
            }
            .onChange(of: subscriptionManager.hasOfferings) { hasOfferings in
                if hasOfferings && selectedPackage == nil {
                    selectedPackage = subscriptionManager.yearlyPackage ?? subscriptionManager.monthlyPackage
                }
            }
        }
    }
    
    // MARK: Sticky footer button
    private var stickyCTA: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: handleContinue) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPurchasing || subscriptionManager.isLoading || selectedPackage == nil)
            .overlay(
                Group {
                    if isPurchasing || subscriptionManager.isLoading { 
                        ProgressView().tint(Color(UIColor.systemBackground)) 
                    }
                }
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: Actions
    private func handleContinue() {
        guard let package = selectedPackage else {
            alertMessage = "Please select a plan"
            showingAlert = true
            return
        }
        Task { await purchase(package) }
    }

    private func purchase(_ package: Package) async {
        isPurchasing = true
        let success = await subscriptionManager.purchase(package: package)
        isPurchasing = false
        if success {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            dismiss()
        } else if let error = subscriptionManager.errorMessage { 
            alertMessage = error
            showingAlert = true 
        }
    }
}

// MARK: - Plan card
private struct PlanOptionCard: View {
    let title: String
    let priceText: String
    let subText: String
    let isSelected: Bool
    let saveBadge: String?
    let primaryColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(priceText)
                            .font(.system(size: 32, weight: .bold))
                            .minimumScaleFactor(0.8)
                        Spacer()
                        if isSelected { 
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(primaryColor) 
                        }
                    }
                    Text(subText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
                        )
                )

                if let save = saveBadge, !save.isEmpty {
                    Text("Save \(save)")
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(primaryColor)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RevenueCatUpgradeView()
}
