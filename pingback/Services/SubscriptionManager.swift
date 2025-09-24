import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let productIds = ["app.pingback.pingback.pro_monthly", "app.pingback.pingback.pro_yearly"]
    
    init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            self.products = storeProducts.sorted { $0.id < $1.id }
        } catch {
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == "app.pingback.pingback.pro_monthly" || transaction.productID == "app.pingback.pingback.pro_yearly" {
                    isPro = true
                    return
                }
            }
        }
        isPro = false
    }
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    isLoading = false
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
        
        isLoading = false
        return false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Helper to get monthly product
    var monthlyProduct: Product? {
        products.first { $0.id == "app.pingback.pingback.pro_monthly" }
    }
    
    // Helper to get yearly product
    var yearlyProduct: Product? {
        products.first { $0.id == "app.pingback.pingback.pro_yearly" }
    }
    
    // Calculate savings for yearly vs monthly
    func calculateSavings() -> String? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else { return nil }
        
        let monthlyPrice = monthly.price
        let yearlyPrice = yearly.price
        let monthlyYearlyTotal = monthlyPrice * 12
        
        if monthlyYearlyTotal > yearlyPrice {
            let savings = monthlyYearlyTotal - yearlyPrice
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = monthly.priceFormatStyle.currencyCode
            return formatter.string(from: NSDecimalNumber(decimal: savings))
        }
        
        return nil
    }
}
