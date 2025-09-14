import SwiftUI
import StoreKit

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    // Removed themeManager dependency for instant theme switching
    @StateObject private var subscriptionManager = SubscriptionManager()

    // The only choice in this screen is billing cadence for the Pro plan
    enum SubscriptionType: String, CaseIterable { case monthly = "Monthly", yearly = "Yearly" }
    @State private var selectedSubscription: SubscriptionType = .yearly
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Feature carousel
    struct Feature: Identifiable { let id = UUID(); let title: String; let subtitle: String; let symbol: String }
    private let features: [Feature] = [
        .init(title: "More projects for more productivity", subtitle: "Create up to 300 personal projects", symbol: "folder.fill"),
        .init(title: "Smart reminders", subtitle: "Never miss a follow‑up again", symbol: "bell.badge.fill"),
        .init(title: "Priority support", subtitle: "Get help faster when you need it", symbol: "bolt.fill")
    ]
    @State private var featureIndex: Int = 0
    
    // Removed theme color overrides for instant theme switching

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
                    HStack(spacing: 16) {
                        PlanOptionCard(
                            title: "Pay Yearly",
                            priceText: subscriptionManager.yearlyProduct?.displayPrice ?? "—",
                            subText: yearlySubText,
                            isSelected: selectedSubscription == .yearly,
                            saveBadge: subscriptionManager.calculateSavings(),
                            primaryColor: .primary,
                            onTap: { selectedSubscription = .yearly }
                        )

                        PlanOptionCard(
                            title: "Pay Monthly",
                            priceText: subscriptionManager.monthlyProduct?.displayPrice ?? "—",
                            subText: "billed monthly",
                            isSelected: selectedSubscription == .monthly,
                            saveBadge: nil,
                            primaryColor: .primary,
                            onTap: { selectedSubscription = .monthly }
                        )
                    }
                    .frame(maxWidth: .infinity)

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
            .alert("Error", isPresented: $showingAlert) { Button("OK") {} } message: { Text(alertMessage) }
            .task {
                await subscriptionManager.loadProducts()
                if subscriptionManager.yearlyProduct != nil { selectedSubscription = .yearly }
                else if subscriptionManager.monthlyProduct != nil { selectedSubscription = .monthly }
            }
        }
    }

    private var yearlySubText: String {
        if subscriptionManager.yearlyProduct != nil { return "billed yearly" }
        return "—"
    }

    // MARK: Sticky footer button
    private var stickyCTA: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: handleContinue) {
                Text("Continue")
                    .font(.headline).bold()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(.primary)
                    .cornerRadius(8)
            }
            .disabled(subscriptionManager.isLoading)
            .overlay(
                Group {
                    if subscriptionManager.isLoading { ProgressView().tint(.secondary) }
                }
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: Actions
    private func handleContinue() {
        let product: Product?
        switch selectedSubscription {
        case .monthly: product = subscriptionManager.monthlyProduct
        case .yearly:  product = subscriptionManager.yearlyProduct
        }
        guard let product else {
            alertMessage = "Product not available"
            showingAlert = true
            return
        }
        Task { await purchase(product) }
    }

    private func purchase(_ product: Product) async {
        let success = await subscriptionManager.purchase(product)
        if success {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            dismiss()
        } else if let error = subscriptionManager.errorMessage { alertMessage = error; showingAlert = true }
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
                        if isSelected { Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundColor(primaryColor) }
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
    UpgradeView()
        .environmentObject(ThemeManager.shared)
}