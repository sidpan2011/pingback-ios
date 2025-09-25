import Foundation
import RevenueCat

struct RevenueCatConfiguration {
    // MARK: - API Keys
    // Replace these with your actual RevenueCat API keys
    static let apiKey = "appl_OzNHcJvGHXZuyTcabvbKhxqJLRe" // Replace with your RevenueCat API key
    
    // MARK: - Product Identifiers
    // These should match your App Store Connect product IDs
    struct ProductIdentifiers {
        static let monthly = "app.pingback.pingback.pro_monthly"
        static let yearly = "app.pingback.pingback.pro_yearly"
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
        // Only configure if not already configured
        guard !Purchases.isConfigured else {
            print("🔵 RevenueCat already configured")
            return
        }
        
        // Set up RevenueCat with the API key
        Purchases.configure(withAPIKey: apiKey)
        
        // Configure logging level
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
        
        // Verify SDK is configured
        print("🔵 RevenueCat SDK configured: \(Purchases.isConfigured)")
        print("🔵 RevenueCat API Key: \(apiKey)")
        print("🔵 RevenueCat App User ID: \(Purchases.shared.appUserID)")
        
        // Set up user attributes (optional)
        // You can set user attributes for analytics and personalization
        // Purchases.shared.setAttributes(["$email": "user@example.com"])
    }
    
    // MARK: - SDK Connection Testing
    static func testSDKConnection() {
        print("🔵 Testing RevenueCat SDK connection...")
        
        // Test 1: Check if we can get customer info
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                print("❌ RevenueCat connection failed: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                print("✅ RevenueCat connected successfully!")
                print("   - User ID: \(customerInfo.originalAppUserId)")
                print("   - Active entitlements: \(customerInfo.entitlements.active.keys)")
                print("   - Management URL: \(customerInfo.managementURL?.absoluteString ?? "None")")
            }
        }
        
        // Test 2: Try to load offerings
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                print("❌ Failed to load offerings: \(error.localizedDescription)")
            } else if let offerings = offerings {
                print("✅ Offerings loaded successfully!")
                print("   - Current offering: \(offerings.current?.identifier ?? "None")")
                print("   - Available packages: \(offerings.current?.availablePackages.count ?? 0)")
                
                // Print package details
                offerings.current?.availablePackages.forEach { package in
                    print("   - Package: \(package.identifier) (\(package.storeProduct.localizedTitle))")
                }
            }
        }
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
            Purchases.shared.attribution.setAttributes([key: value])
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
                print("- Non Subscription Transactions: \(customerInfo.nonSubscriptions.count)")
            }
        }
    }
}
