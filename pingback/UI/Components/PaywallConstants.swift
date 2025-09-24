import Foundation

struct PaywallConstants {
    // MARK: - URLs
    static let privacyURL = "https://getpingback.app/privacy"
    static let termsURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    
    // MARK: - Footer Copy
    static let footerText = "Auto-renewing. Manage in Settings › Apple ID › Subscriptions."
    
    // MARK: - Timeouts
    static let revenueCatTimeout: TimeInterval = 5.0
    static let storeKitTimeout: TimeInterval = 3.0
    
    // MARK: - Product IDs
    static let monthlyProductID = "app.pingback.pingback.pro_monthly"
    static let yearlyProductID = "app.pingback.pingback.pro_yearly"
    
    // MARK: - UI Constants
    static let cornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 50
    static let spacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
    
    // MARK: - Accessibility
    struct Accessibility {
        static let retryButton = "Retry loading subscription options"
        static let restoreButton = "Restore previous purchases"
        static let monthlyButton = "Subscribe to Pro Monthly"
        static let yearlyButton = "Subscribe to Pro Yearly"
        static let privacyLink = "View Privacy Policy"
        static let termsLink = "View Terms of Service"
        static let loadingPrices = "Loading subscription prices"
    }
}
