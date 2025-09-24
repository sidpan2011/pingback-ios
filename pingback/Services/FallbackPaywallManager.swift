import Foundation
import StoreKit
import RevenueCat
import SwiftUI
import Network

@MainActor
class FallbackPaywallManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = true
    @Published var isOffline: Bool = false
    @Published var monthlyPrice: String = "Loading price…"
    @Published var yearlyPrice: String = "Loading price…"
    @Published var monthlyPerMonth: String = ""
    @Published var yearlyPerMonth: String = ""
    @Published var savings: String = ""
    @Published var canContinue: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var isRetrying: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPlan: PlanType = .yearly
    @Published var monthlyAvailable: Bool = false
    @Published var yearlyAvailable: Bool = false
    @Published var monthlyUnavailableReason: String?
    @Published var yearlyUnavailableReason: String?
    @Published var isUsingMockPrices: Bool = false
    
    enum PlanType: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    // MARK: - Private Properties
    private var revenueCatManager = RevenueCatManager.shared
    private var storeKitProducts: [Product] = []
    private var timeoutTask: Task<Void, Never>?
    private var networkMonitor: NWPathMonitor?
    private var networkQueue = DispatchQueue(label: "NetworkMonitor")
    private var hasRevenueCatOfferings: Bool = false
    private var cachedPrices: [String: String] = [:]
    private var isListeningForUpdates: Bool = false
    
    // MARK: - Constants
    private let revenueCatTimeout: TimeInterval = 4.0
    private let storeKitTimeout: TimeInterval = 3.0
    
    // MARK: - Mock Prices (for testing when both RC and SK2 fail)
    private let mockMonthlyPrice = "$4.99"
    private let mockYearlyPrice = "$49.99"
    private let mockYearlyPerMonth = "$4.17"
    private let mockSavings = "Save $10.89"
    
    // MARK: - Initialization
    init() {
        setupNetworkMonitoring()
        Task {
            await loadOfferingsWithFallback()
        }
    }
    
    deinit {
        networkMonitor?.cancel()
        timeoutTask?.cancel()
    }
    
    // MARK: - Public Methods
    func retry() async {
        guard !isRetrying else { return }
        
        isRetrying = true
        errorMessage = nil
        isLoading = true
        
        await loadOfferingsWithFallback()
        
        isRetrying = false
    }
    
    func purchaseSelectedPlan() async -> Bool {
        guard !isPurchasing else { return false }
        
        isPurchasing = true
        errorMessage = nil
        
        // Handle mock purchases for testing
        if isUsingMockPrices {
            // Simulate a successful purchase for testing
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            isPurchasing = false
            errorMessage = "Demo purchase successful! (Testing mode)"
            return true
        }
        
        do {
            // Try RevenueCat first if available
            if hasRevenueCatOfferings {
                if let offerings = revenueCatManager.offerings,
                   let current = offerings.current {
                    let package = selectedPlan == .monthly ? current.monthly : current.annual
                    
                    if let package = package {
                        let success = await revenueCatManager.purchase(package: package)
                        isPurchasing = false
                        return success
                    }
                }
            }
            
            // Fallback to StoreKit2
            guard let product = storeKitProducts.first(where: { $0.id == getProductID(for: selectedPlan) }) else {
                errorMessage = "Product not available"
                isPurchasing = false
                return false
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    isPurchasing = false
                    return true
                }
            case .userCancelled:
                errorMessage = "Purchase cancelled"
            case .pending:
                errorMessage = "Purchase pending approval"
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isPurchasing = false
        return false
    }
    
    func restorePurchases() async -> Bool {
        guard !isPurchasing else { return false }
        
        isPurchasing = true
        errorMessage = nil
        
        // Handle mock restore for testing
        if isUsingMockPrices {
            // Simulate a successful restore for testing
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            isPurchasing = false
            errorMessage = "Demo restore successful! (Testing mode)"
            return true
        }
        
        do {
            // Try RevenueCat first
            if hasRevenueCatOfferings {
                let success = await revenueCatManager.restorePurchases()
                if success {
                    isPurchasing = false
                    return true
                }
            }
            
            // Fallback to StoreKit2
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            isPurchasing = false
            return true
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isPurchasing = false
            return false
        }
    }
    
    // MARK: - Private Methods
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
                if path.status == .satisfied && self?.isOffline == true {
                    // Network came back online, try to fetch fresh data
                    Task {
                        await self?.loadOfferingsWithFallback()
                    }
                }
            }
        }
        networkMonitor?.start(queue: networkQueue)
    }
    
    private func loadOfferingsWithFallback() async {
        isLoading = true
        errorMessage = nil
        
        // Fast path for offline
        if isOffline {
            await showOfflineFallback()
            return
        }
        
        // Start timeout task
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(revenueCatTimeout * 1_000_000_000))
            if !Task.isCancelled {
                await showFallbackIfNeeded()
            }
        }
        
        // Load RevenueCat offerings
        await loadRevenueCatOfferings()
        
        // Load StoreKit2 products in parallel
        await loadStoreKitProducts()
        
        // Cancel timeout if we got offerings
        if hasRevenueCatOfferings {
            timeoutTask?.cancel()
            timeoutTask = nil
        }
        
        isLoading = false
    }
    
    private func showOfflineFallback() async {
        errorMessage = "No internet. Check connection and try again."
        monthlyAvailable = false
        yearlyAvailable = false
        monthlyUnavailableReason = "No internet connection"
        yearlyUnavailableReason = "No internet connection"
        canContinue = false
        isLoading = false
    }
    
    private func showFallbackIfNeeded() async {
        if !hasRevenueCatOfferings && storeKitProducts.isEmpty {
            // Use mock prices for testing when both RC and SK2 fail
            await showMockPrices()
        }
    }
    
    private func showMockPrices() async {
        isUsingMockPrices = true
        monthlyPrice = mockMonthlyPrice
        yearlyPrice = mockYearlyPrice
        monthlyPerMonth = mockMonthlyPrice + "/month"
        yearlyPerMonth = mockYearlyPerMonth + "/month"
        savings = mockSavings
        
        // Make plans available for testing
        monthlyAvailable = true
        yearlyAvailable = true
        monthlyUnavailableReason = nil
        yearlyUnavailableReason = nil
        
        // Show a subtle indicator that we're using mock prices
        errorMessage = "Using demo prices for testing"
        
        updateCanContinue()
    }
    
    private func loadRevenueCatOfferings() async {
        await revenueCatManager.loadOfferings()
        
        if let offerings = revenueCatManager.offerings,
           let current = offerings.current,
           !current.availablePackages.isEmpty {
            hasRevenueCatOfferings = true
            await updatePricesFromRevenueCat(offerings: current)
            await updateAvailabilityFromRevenueCat(offerings: current)
        } else {
            hasRevenueCatOfferings = false
        }
    }
    
    private func loadStoreKitProducts() async {
        do {
            let products = try await Product.products(for: [
                PaywallConstants.monthlyProductID,
                PaywallConstants.yearlyProductID
            ])
            
            storeKitProducts = products
            
            // If we don't have RevenueCat offerings, use StoreKit prices
            if !hasRevenueCatOfferings {
                await updatePricesFromStoreKit()
                await updateAvailabilityFromStoreKit()
            }
        } catch {
            print("StoreKit2 products failed to load: \(error)")
        }
    }
    
    private func updatePricesFromRevenueCat(offerings: Offering) async {
        // Update monthly price
        if let monthlyPackage = offerings.monthly {
            monthlyPrice = monthlyPackage.storeProduct.localizedPriceString
            monthlyPerMonth = monthlyPackage.storeProduct.localizedPriceString + "/month"
            cachedPrices[PaywallConstants.monthlyProductID] = monthlyPrice
        }
        
        // Update yearly price
        if let yearlyPackage = offerings.annual {
            yearlyPrice = yearlyPackage.storeProduct.localizedPriceString
            yearlyPerMonth = revenueCatManager.yearlyPerMonthPriceString ?? ""
            cachedPrices[PaywallConstants.yearlyProductID] = yearlyPrice
        }
        
        // Calculate savings
        if let savingsAmount = revenueCatManager.calculateSavings() {
            savings = "Save \(savingsAmount)"
        }
        
        updateCanContinue()
    }
    
    private func updatePricesFromStoreKit() async {
        let monthlyProduct = storeKitProducts.first { $0.id == PaywallConstants.monthlyProductID }
        let yearlyProduct = storeKitProducts.first { $0.id == PaywallConstants.yearlyProductID }
        
        if let monthly = monthlyProduct {
            monthlyPrice = monthly.displayPrice
            monthlyPerMonth = monthly.displayPrice + "/month"
            cachedPrices[PaywallConstants.monthlyProductID] = monthlyPrice
        }
        
        if let yearly = yearlyProduct {
            yearlyPrice = yearly.displayPrice
            yearlyPerMonth = calculateYearlyPerMonth(price: yearly.price)
            cachedPrices[PaywallConstants.yearlyProductID] = yearlyPrice
        }
        
        // Calculate savings
        if let monthly = monthlyProduct, let yearly = yearlyProduct {
            let monthlyYearlyTotal = monthly.price * 12
            if monthlyYearlyTotal > yearly.price {
                let savingsAmount = monthlyYearlyTotal - yearly.price
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = monthly.priceFormatStyle.currencyCode
                savings = "Save \(formatter.string(from: NSDecimalNumber(decimal: savingsAmount)) ?? "")"
            }
        }
        
        updateCanContinue()
    }
    
    private func updateAvailabilityFromRevenueCat(offerings: Offering) async {
        monthlyAvailable = offerings.monthly != nil
        yearlyAvailable = offerings.annual != nil
        
        if !monthlyAvailable {
            monthlyUnavailableReason = "Temporarily unavailable"
        }
        if !yearlyAvailable {
            yearlyUnavailableReason = "Temporarily unavailable"
        }
    }
    
    private func updateAvailabilityFromStoreKit() async {
        monthlyAvailable = storeKitProducts.contains { $0.id == PaywallConstants.monthlyProductID }
        yearlyAvailable = storeKitProducts.contains { $0.id == PaywallConstants.yearlyProductID }
        
        if !monthlyAvailable {
            monthlyUnavailableReason = "Temporarily unavailable"
        }
        if !yearlyAvailable {
            yearlyUnavailableReason = "Temporarily unavailable"
        }
    }
    
    private func updateCanContinue() {
        canContinue = (selectedPlan == .monthly && monthlyAvailable) || 
                     (selectedPlan == .yearly && yearlyAvailable)
    }
    
    private func calculateYearlyPerMonth(price: Decimal) -> String {
        let perMonth = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: perMonth)) ?? ""
    }
    
    private func getProductID(for plan: PlanType) -> String {
        switch plan {
        case .monthly:
            return PaywallConstants.monthlyProductID
        case .yearly:
            return PaywallConstants.yearlyProductID
        }
    }
    
    private func updateSubscriptionStatus() async {
        // This would typically update your app's subscription status
        // Implementation depends on your app's subscription management
    }
    
    // MARK: - Background Listening
    func startListeningForUpdates() {
        guard !isListeningForUpdates else { return }
        isListeningForUpdates = true
        
        // Listen for RevenueCat updates
        Task {
            while isListeningForUpdates {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if hasRevenueCatOfferings {
                    await loadRevenueCatOfferings()
                }
            }
        }
    }
    
    func stopListeningForUpdates() {
        isListeningForUpdates = false
    }
}
