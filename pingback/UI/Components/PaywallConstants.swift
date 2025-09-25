import Foundation

struct PaywallConstants {
    // MARK: - URLs
    static let privacyURL = "https://getpingback.app/privacy"
    static let termsURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    
    // MARK: - Footer Copy
    static let footerText = "Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage your subscription and turn off auto-renewal by going to your Account Settings after purchase."
    
    // MARK: - UI Constants
    static let cornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 50
    static let spacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
    
    // MARK: - Accessibility
    struct Accessibility {
        static let restoreButton = "Restore previous purchases"
        static let monthlyButton = "Subscribe to Pro Monthly"
        static let yearlyButton = "Subscribe to Pro Yearly"
        static let privacyLink = "View Privacy Policy"
        static let termsLink = "View Terms of Service"
    }
}
