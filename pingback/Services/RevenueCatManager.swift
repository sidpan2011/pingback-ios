import Foundation
import RevenueCat
import SwiftUI

@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSDKConnected: Bool = false
    @Published var connectionStatus: String = "Checking..."
    
    private static var _shared: RevenueCatManager?
    static var shared: RevenueCatManager {
        if let existing = _shared {
            return existing
        }
        let new = RevenueCatManager()
        _shared = new
        return new
    }
    
    // For testing/preview purposes
    static func reset() {
        _shared = nil
    }
    
    private override init() {
        super.init()
        
        // Check if we're in preview mode first
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview mode - set default state without configuring RevenueCat
            self.isLoading = false
            self.isPro = false
            self.offerings = nil
            self.customerInfo = nil
            self.errorMessage = nil
            return
        }
        
        configureRevenueCat()
        Task {
            await loadOfferings()
            await checkSubscriptionStatus()
        }
    }
    
    private func configureRevenueCat() {
        // Skip RevenueCat configuration in preview mode
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return
        }
        
        // Only configure if not already configured
        guard !Purchases.isConfigured else {
            return
        }
        
        // Configure RevenueCat with your API key
        Purchases.configure(withAPIKey: RevenueCatConfiguration.apiKey)
        
        // Set up logging for debugging
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        // Set up delegate to handle customer info updates
        Purchases.shared.delegate = self
    }
    
    func loadOfferings() async {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            isLoading = false
            connectionStatus = "Preview mode or SDK not configured"
            return
        }
        
        isLoading = true
        errorMessage = nil
        connectionStatus = "Loading offerings..."
        
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            self.isSDKConnected = true
            self.connectionStatus = "Connected ✅"
            print("✅ RevenueCat offerings loaded: \(offerings.current?.availablePackages.count ?? 0) packages")
        } catch {
            self.errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            self.isSDKConnected = false
            self.connectionStatus = "Failed to load offerings ❌"
            print("❌ RevenueCat offerings failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() async {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            connectionStatus = "Preview mode or SDK not configured"
            return
        }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements["pro"]?.isActive == true
            self.isSDKConnected = true
            print("✅ RevenueCat customer info loaded for user: \(customerInfo.originalAppUserId)")
            print("   - Pro status: \(isPro)")
            print("   - Active entitlements: \(customerInfo.entitlements.active.keys)")
        } catch {
            self.errorMessage = "Failed to check subscription status: \(error.localizedDescription)"
            self.isSDKConnected = false
            print("❌ RevenueCat customer info failed: \(error.localizedDescription)")
        }
    }
    
    func purchase(package: Package) async -> Bool {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements["pro"]?.isActive == true
            isLoading = false
            return true
        } catch {
            if let revenueCatError = error as? RevenueCat.ErrorCode {
                switch revenueCatError {
                case .purchaseCancelledError:
                    errorMessage = "Purchase was cancelled"
                case .storeProblemError:
                    errorMessage = "There was a problem with the App Store"
                case .purchaseNotAllowedError:
                    errorMessage = "Purchase not allowed"
                case .purchaseInvalidError:
                    errorMessage = "Purchase is invalid"
                default:
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            isLoading = false
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements["pro"]?.isActive == true
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Convenience Properties
    
    var monthlyPackage: Package? {
        offerings?.current?.monthly
    }
    
    var yearlyPackage: Package? {
        offerings?.current?.annual
    }
    
    var monthlyPriceString: String? {
        monthlyPackage?.storeProduct.localizedPriceString
    }
    
    var yearlyPriceString: String? {
        yearlyPackage?.storeProduct.localizedPriceString
    }
    
    var yearlyPerMonthPriceString: String? {
        guard let yearly = yearlyPackage else { return nil }
        let perMonth = NSDecimalNumber(decimal: yearly.storeProduct.price)
            .dividing(by: NSDecimalNumber(value: 12))
            .decimalValue
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: perMonth))
    }
    
    var hasOfferings: Bool {
        offerings?.current != nil
    }
    
    // Calculate savings for yearly vs monthly
    func calculateSavings() -> String? {
        guard let monthly = monthlyPackage, let yearly = yearlyPackage else { return nil }
        
        let monthlyTotal = NSDecimalNumber(decimal: monthly.storeProduct.price)
            .multiplying(by: NSDecimalNumber(value: 12))
        let yearlyPrice = NSDecimalNumber(decimal: yearly.storeProduct.price)
        let diff = monthlyTotal.subtracting(yearlyPrice)
        guard diff.doubleValue > 0 else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: diff)
    }
    
    // Get subscription expiration date
    var subscriptionExpirationDate: Date? {
        customerInfo?.entitlements["pro"]?.expirationDate
    }
    
    // Check if subscription is in trial period
    var isInTrialPeriod: Bool {
        customerInfo?.entitlements["pro"]?.willRenew == true && 
        customerInfo?.entitlements["pro"]?.periodType == .trial
    }
    
    // Get subscription period type
    var subscriptionPeriodType: PeriodType? {
        customerInfo?.entitlements["pro"]?.periodType
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements["pro"]?.isActive == true
        }
    }
}

