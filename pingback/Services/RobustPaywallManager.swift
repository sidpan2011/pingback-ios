import Foundation
import StoreKit
import RevenueCat
import SwiftUI

@MainActor
class RobustPaywallManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = true
    @Published var isRetrying: Bool = false
    @Published var errorMessage: String?
    @Published var monthlyPrice: String = "Loading price…"
    @Published var yearlyPrice: String = "Loading price…"
    @Published var monthlyPerMonth: String = ""
    @Published var yearlyPerMonth: String = ""
    @Published var savings: String = ""
    @Published var canPurchase: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var showFallback: Bool = false
    
    // MARK: - Private Properties
    private var revenueCatManager = RevenueCatManager.shared
    private var storeKitProducts: [Product] = []
    private var timeoutTask: Task<Void, Never>?
    private var hasRevenueCatOfferings: Bool = false
    
    // MARK: - Initialization
    init() {
        Task {
            await loadOfferingsWithTimeout()
        }
    }
    
    // MARK: - Public Methods
    func retry() async {
        guard !isRetrying else { return }
        
        isRetrying = true
        errorMessage = nil
        showFallback = false
        
        await loadOfferingsWithTimeout()
        
        isRetrying = false
    }
    
    func purchaseMonthly() async -> Bool {
        return await performPurchase(productID: PaywallConstants.monthlyProductID)
    }
    
    func purchaseYearly() async -> Bool {
        return await performPurchase(productID: PaywallConstants.yearlyProductID)
    }
    
    func restorePurchases() async -> Bool {
        guard !isPurchasing else { return false }
        
        isPurchasing = true
        errorMessage = nil
        
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
    private func loadOfferingsWithTimeout() async {
        isLoading = true
        showFallback = false
        
        // Start timeout task
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(PaywallConstants.revenueCatTimeout * 1_000_000_000))
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
    
    private func loadRevenueCatOfferings() async {
        await revenueCatManager.loadOfferings()
        
        if let offerings = revenueCatManager.offerings,
           let current = offerings.current,
           !current.availablePackages.isEmpty {
            hasRevenueCatOfferings = true
            await updatePricesFromRevenueCat()
            canPurchase = true
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
                canPurchase = !products.isEmpty
            }
        } catch {
            print("StoreKit2 products failed to load: \(error)")
        }
    }
    
    private func updatePricesFromRevenueCat() async {
        guard let offerings = revenueCatManager.offerings,
              let current = offerings.current else { return }
        
        // Update monthly price
        if let monthlyPackage = current.monthly {
            monthlyPrice = monthlyPackage.storeProduct.localizedPriceString
            monthlyPerMonth = monthlyPackage.storeProduct.localizedPriceString + "/month"
        }
        
        // Update yearly price
        if let yearlyPackage = current.annual {
            yearlyPrice = yearlyPackage.storeProduct.localizedPriceString
            yearlyPerMonth = revenueCatManager.yearlyPerMonthPriceString ?? ""
        }
        
        // Calculate savings
        if let savingsAmount = revenueCatManager.calculateSavings() {
            savings = "Save \(savingsAmount)"
        }
    }
    
    private func updatePricesFromStoreKit() async {
        let monthlyProduct = storeKitProducts.first { $0.id == PaywallConstants.monthlyProductID }
        let yearlyProduct = storeKitProducts.first { $0.id == PaywallConstants.yearlyProductID }
        
        if let monthly = monthlyProduct {
            monthlyPrice = monthly.displayPrice
            monthlyPerMonth = monthly.displayPrice + "/month"
        }
        
        if let yearly = yearlyProduct {
            yearlyPrice = yearly.displayPrice
            yearlyPerMonth = calculateYearlyPerMonth(price: yearly.price)
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
    }
    
    private func calculateYearlyPerMonth(price: Decimal) -> String {
        let perMonth = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: perMonth)) ?? ""
    }
    
    private func showFallbackIfNeeded() async {
        if !hasRevenueCatOfferings && storeKitProducts.isEmpty {
            showFallback = true
            canPurchase = false
        }
    }
    
    private func performPurchase(productID: String) async -> Bool {
        guard !isPurchasing else { return false }
        
        isPurchasing = true
        errorMessage = nil
        
        do {
            // Try RevenueCat first if available
            if hasRevenueCatOfferings {
                if let offerings = revenueCatManager.offerings,
                   let current = offerings.current {
                    let package = current.availablePackages.first { package in
                        package.storeProduct.productIdentifier == productID
                    }
                    
                    if let package = package {
                        let success = await revenueCatManager.purchase(package: package)
                        isPurchasing = false
                        return success
                    }
                }
            }
            
            // Fallback to StoreKit2
            guard let product = storeKitProducts.first(where: { $0.id == productID }) else {
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
    
    private func updateSubscriptionStatus() async {
        // This would typically update your app's subscription status
        // Implementation depends on your app's subscription management
    }
}
