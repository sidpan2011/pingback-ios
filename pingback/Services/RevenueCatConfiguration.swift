import Foundation
import RevenueCat

struct RevenueCatConfiguration {
    // MARK: - API Keys
    // Replace these with your actual RevenueCat API keys
    static let apiKey = "appl_OzNHcJvGHXZuyTcabvbKhxqJLRe" // Replace with your RevenueCat API key
    
    // MARK: - Product Identifiers
    // These should match your App Store Connect product IDs
    struct ProductIdentifiers {
        static let monthly = "pro.monthly"
        static let yearly = "pro.yearly"
    }
    
    // MARK: - Entitlement Identifiers
    // These should match your RevenueCat dashboard entitlement IDs
    struct Entitlements {
        static let pro = "pro"
    }
    
    // MARK: - Offering Identifiers
    // These should match your RevenueCat dashboard offering IDs
    struct Offerings {
        static let defaultOffering = "default"
    }
    
    // MARK: - Configuration
    static func configure() {
        // Set up RevenueCat with the API key
        Purchases.configure(withAPIKey: apiKey)
        
        // Configure logging level
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
        
        // Set up user attributes (optional)
        // You can set user attributes for analytics and personalization
        // Purchases.shared.setAttributes(["$email": "user@example.com"])
    }
    
    // MARK: - User Management
    static func setUserID(_ userID: String) {
        Purchases.shared.logIn(userID) { customerInfo, created, error in
            if let error = error {
                print("Error logging in user: \(error.localizedDescription)")
            } else {
                print("User logged in successfully. Created: \(created)")
            }
        }
    }
    
    static func logOut() {
        Purchases.shared.logOut { customerInfo, error in
            if let error = error {
                print("Error logging out user: \(error.localizedDescription)")
            } else {
                print("User logged out successfully")
            }
        }
    }
    
    // MARK: - Analytics
    static func setUserAttributes(_ attributes: [String: String]) {
        for (key, value) in attributes {
            Purchases.shared.setAttributes([key: value])
        }
    }
    
    // MARK: - Debugging
    static func printCustomerInfo() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                print("Error getting customer info: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                print("Customer Info:")
                print("- User ID: \(customerInfo.originalAppUserId)")
                print("- Active Entitlements: \(customerInfo.entitlements.active.keys)")
                print("- All Entitlements: \(customerInfo.entitlements.all.keys)")
                print("- Active Subscriptions: \(customerInfo.activeSubscriptions)")
                print("- Non Subscription Transactions: \(customerInfo.nonSubscriptionTransactions.count)")
            }
        }
    }
}
