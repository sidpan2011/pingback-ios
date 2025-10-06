import Foundation
import RevenueCat
import SwiftUI

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    
    // Free tier limits
    @Published var followUpsRemaining: Int = 10
    @Published var exportsRemaining: Int = 5
    private let maxFreeFollowUps = 10
    private let maxFreeExports = 5
    
    // MARK: - Singleton
    private static var _shared: SubscriptionManager?
    static var shared: SubscriptionManager {
        if let existing = _shared {
            return existing
        }
        let new = SubscriptionManager()
        _shared = new
        return new
    }
    
    // For testing/preview purposes
    static func reset() {
        _shared = nil
    }
    
    // MARK: - Private Properties
    private var isInitialized = false
    
    // MARK: - Initialization
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

        setupRevenueCat()
        // Initialization is now handled by pingbackApp.swift .task to avoid blocking during init
    }
    
    // MARK: - Public Methods
    
    func initializeSubscriptionState() async {
        guard !isInitialized else { return }
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        
        isInitialized = true
        await loadOfferings()
        await checkSubscriptionStatus()
    }
    
    func loadOfferings() async {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            print("✅ RevenueCat offerings loaded: \(offerings.current?.availablePackages.count ?? 0) packages")
        } catch {
            self.errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            print("❌ RevenueCat offerings failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() async {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            return
        }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements[RevenueCatConfiguration.Entitlements.pro]?.isActive == true
            self.resetFreeTierLimitsIfNeeded()
            
            // Sync subscription status to shared UserDefaults for share extension
            syncSubscriptionStatusToSharedDefaults()
            
            print("✅ RevenueCat customer info loaded for user: \(customerInfo.originalAppUserId)")
            print("   - Pro status: \(isPro)")
            print("   - Active entitlements: \(customerInfo.entitlements.active.keys)")
        } catch {
            self.errorMessage = "Failed to check subscription status: \(error.localizedDescription)"
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
            self.isPro = customerInfo.entitlements[RevenueCatConfiguration.Entitlements.pro]?.isActive == true
            syncSubscriptionStatusToSharedDefaults()
            isLoading = false
            print("✅ Purchase successful: \(package.storeProduct.productIdentifier)")
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
            print("❌ Purchase failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func purchase(productId: String) async -> Bool {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // First get the product, then purchase it
            let products = try await withCheckedThrowingContinuation { continuation in
                Purchases.shared.getProducts([productId]) { products in
                    continuation.resume(returning: products)
                }
            }
            guard let product = products.first else {
                errorMessage = "Product not found"
                isLoading = false
                return false
            }
            let (_, customerInfo, _) = try await Purchases.shared.purchase(product: product)
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements[RevenueCatConfiguration.Entitlements.pro]?.isActive == true
            syncSubscriptionStatusToSharedDefaults()
            isLoading = false
            print("✅ Purchase successful: \(productId)")
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
            print("❌ Purchase failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        // Skip if in preview mode or RevenueCat not configured
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" && Purchases.isConfigured else {
            print("⚠️ Restore purchases skipped - Preview mode or RevenueCat not configured")
            return false
        }
        
        print("🔄 Starting restore purchases process...")
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            
            // Log Apple ID information
            print("📱 Apple ID: \(customerInfo.originalAppUserId)")
            print("📊 Active entitlements: \(customerInfo.entitlements.active.keys)")
            print("📊 All entitlements: \(customerInfo.entitlements.all.keys)")
            
            let wasPro = self.isPro
            self.isPro = customerInfo.entitlements[RevenueCatConfiguration.Entitlements.pro]?.isActive == true
            syncSubscriptionStatusToSharedDefaults()
            isLoading = false
            
            // Check if any purchases were actually restored
            if !wasPro && self.isPro {
                print("✅ Restore purchases successful - Pro subscription restored for Apple ID: \(customerInfo.originalAppUserId)")
                return true
            } else if wasPro && self.isPro {
                print("✅ Restore purchases successful - Pro subscription already active for Apple ID: \(customerInfo.originalAppUserId)")
                return true
            } else {
                // No purchases found to restore
                errorMessage = "No purchases found for Apple ID: \(customerInfo.originalAppUserId)"
                print("ℹ️ Restore purchases completed - No purchases found for Apple ID: \(customerInfo.originalAppUserId)")
                return false
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
            print("❌ Restore purchases failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }
    
    // MARK: - Free Tier Management
    
    /// Calculate the actual count of follow-ups created this month from Core Data (excluding deleted ones)
    func calculateCurrentMonthFollowUpCount() async -> Int {
        guard !isPro else { return 0 } // Pro users have unlimited, return 0 for remaining calculation
        
        do {
            let calendar = Calendar.current
            let now = Date()
            
            // Get the start of current month
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            
            // Create predicate for follow-ups created this month AND not deleted
            let predicate = NSPredicate(format: "createdAt >= %@ AND deletedAt == nil", startOfMonth as NSDate)
            
            // Count follow-ups from Core Data
            let count = try CoreDataStack.shared.count(entityType: CDFollowUp.self, predicate: predicate)
            
            print("📊 SubscriptionManager: Calculated \(count) active follow-ups created this month (excluding deleted)")
            return count
            
        } catch {
            print("❌ SubscriptionManager: Failed to calculate follow-up count: \(error)")
            return 0
        }
    }
    
    /// Update the remaining count based on actual Core Data count
    func updateFollowUpCountFromCoreData() async {
        guard !isPro else {
            followUpsRemaining = maxFreeFollowUps // Reset to max for Pro users
            syncFollowUpCountToSharedDefaults()
            return
        }
        
        let currentCount = await calculateCurrentMonthFollowUpCount()
        followUpsRemaining = max(0, maxFreeFollowUps - currentCount)
        
        print("📊 SubscriptionManager: Updated remaining count: \(followUpsRemaining) (used: \(currentCount)/\(maxFreeFollowUps))")
        syncFollowUpCountToSharedDefaults()
    }
    
    func decrementFollowUpCount() throws {
        guard !isPro else { return } // Pro users have unlimited
        if followUpsRemaining > 0 {
            followUpsRemaining -= 1
            syncFollowUpCountToSharedDefaults()
        } else {
            throw SubscriptionError.usageLimitExceeded("follow-ups")
        }
    }
    
    func decrementExportCount() throws {
        guard !isPro else { return } // Pro users have unlimited
        if exportsRemaining > 0 {
            exportsRemaining -= 1
        } else {
            throw SubscriptionError.usageLimitExceeded("exports")
        }
    }
    
    /// Increment follow-up count when a follow-up is deleted (gives back a slot)
    func incrementFollowUpCount() {
        guard !isPro else { return } // Pro users have unlimited
        if followUpsRemaining < maxFreeFollowUps {
            followUpsRemaining += 1
            syncFollowUpCountToSharedDefaults()
            print("📊 SubscriptionManager: Incremented follow-up count due to deletion. Remaining: \(followUpsRemaining)")
        }
    }
    
    /// Recalculate and update follow-up count from Core Data (call this after deletions)
    func recalculateFollowUpCount() async {
        await updateFollowUpCountFromCoreData()
    }
    
    /// Handle bulk deletion of follow-ups (for cleanup operations)
    func handleBulkDeletion(deletedCount: Int) async {
        guard !isPro else { return } // Pro users have unlimited
        
        // For bulk deletions, we can optimize by just adding to the remaining count
        // instead of recalculating from Core Data
        let newRemaining = min(maxFreeFollowUps, followUpsRemaining + deletedCount)
        followUpsRemaining = newRemaining
        syncFollowUpCountToSharedDefaults()
        
        print("📊 SubscriptionManager: Handled bulk deletion of \(deletedCount) follow-ups. Remaining: \(followUpsRemaining)")
    }
    
    private func resetFreeTierLimitsIfNeeded() {
        // This is a simplified reset. In a real app, you'd persist these and reset monthly.
        // For now, we'll just ensure they are at max if Pro, or if they were previously Pro.
        if isPro {
            followUpsRemaining = maxFreeFollowUps
            exportsRemaining = maxFreeExports
        } else {
            // If not Pro, ensure they are not above max if they were previously Pro
            followUpsRemaining = min(followUpsRemaining, maxFreeFollowUps)
            exportsRemaining = min(exportsRemaining, maxFreeExports)
        }
        syncFollowUpCountToSharedDefaults()
        
        // Update count from Core Data after subscription status change
        Task {
            await updateFollowUpCountFromCoreData()
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
        customerInfo?.entitlements[RevenueCatConfiguration.Entitlements.pro]?.expirationDate
    }
    
    // Check if subscription is in trial period
    var isInTrialPeriod: Bool {
        customerInfo?.entitlements[RevenueCatConfiguration.Entitlements.pro]?.willRenew == true && 
        customerInfo?.entitlements[RevenueCatConfiguration.Entitlements.pro]?.periodType == .trial
    }
    
    // Get subscription period type
    var subscriptionPeriodType: PeriodType? {
        customerInfo?.entitlements[RevenueCatConfiguration.Entitlements.pro]?.periodType
    }
    
    // MARK: - Private Methods
    
    private func syncSubscriptionStatusToSharedDefaults() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            print("❌ Failed to access app group UserDefaults")
            return
        }
        
        appGroupDefaults.set(isPro, forKey: "isProUser")
        syncFollowUpCountToSharedDefaults()
        appGroupDefaults.synchronize()
        print("✅ Synced subscription status to shared defaults: \(isPro)")
    }
    
    private func syncFollowUpCountToSharedDefaults() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            print("❌ Failed to access app group UserDefaults")
            return
        }
        
        appGroupDefaults.set(followUpsRemaining, forKey: "followUpsRemaining")
        print("✅ Synced follow-up count to shared defaults: \(followUpsRemaining)")
    }
    
    private func syncFollowUpCountFromSharedDefaults() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            print("❌ Failed to access app group UserDefaults")
            return
        }
        
        let sharedCount = appGroupDefaults.integer(forKey: "followUpsRemaining")
        if sharedCount > 0 {
            followUpsRemaining = sharedCount
            print("✅ Synced follow-up count from shared defaults: \(followUpsRemaining)")
        }
    }
    
    private func setupRevenueCat() {
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
}

// MARK: - PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements[RevenueCatConfiguration.Entitlements.pro]?.isActive == true
            self.resetFreeTierLimitsIfNeeded()
            self.syncSubscriptionStatusToSharedDefaults()
            print("🔄 RevenueCat delegate: Pro status updated to \(isPro)")
        }
    }
}

// MARK: - Error Types
enum SubscriptionError: Error, LocalizedError {
    case usageLimitExceeded(String)
    
    var errorDescription: String? {
        switch self {
        case .usageLimitExceeded(let feature):
            return "You've reached your monthly limit for \(feature). Upgrade to Pro for unlimited use!"
        }
    }
}