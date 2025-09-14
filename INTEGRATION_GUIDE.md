# RevenueCat Integration Guide

## Overview
This guide explains how to integrate the RevenueCat subscription system into your Pingback app.

## Files Added/Modified

### New Files
1. **`RevenueCatManager.swift`** - Main subscription management class
2. **`RevenueCatConfiguration.swift`** - Configuration and settings
3. **`RevenueCatSubscriptionView.swift`** - Full-featured subscription UI
4. **`RevenueCatUpgradeView.swift`** - Upgrade prompt UI
5. **`REVENUECAT_SETUP.md`** - Complete setup instructions

### Modified Files
1. **`pingbackApp.swift`** - Added RevenueCat initialization
2. **`SubscriptionView.swift`** - Updated to use RevenueCat

## Quick Start

### 1. Add RevenueCat SDK
1. Open your Xcode project
2. Go to File → Add Package Dependencies
3. Enter: `https://github.com/RevenueCat/purchases-ios.git`
4. Select version 4.0.0 or later

### 2. Configure API Key
1. Open `RevenueCatConfiguration.swift`
2. Replace `"your_revenuecat_api_key_here"` with your actual API key
3. Update product IDs to match your App Store Connect products

### 3. Update Product IDs
In `RevenueCatConfiguration.swift`, update:
```swift
struct ProductIdentifiers {
    static let monthly = "pro.monthly"  // Your monthly product ID
    static let yearly = "pro.yearly"    // Your yearly product ID
}
```

### 4. Update Entitlement ID
In `RevenueCatConfiguration.swift`, update:
```swift
struct Entitlements {
    static let pro = "pro"  // Your entitlement ID from RevenueCat dashboard
}
```

## Usage Examples

### Check Subscription Status
```swift
@StateObject private var subscriptionManager = RevenueCatManager.shared

// Check if user has pro access
if subscriptionManager.isPro {
    // Show pro features
} else {
    // Show upgrade prompt
}
```

### Show Upgrade View
```swift
.sheet(isPresented: $showingUpgrade) {
    RevenueCatUpgradeView()
}
```

### Show Subscription Management
```swift
.sheet(isPresented: $showingSubscription) {
    RevenueCatSubscriptionView()
}
```

### Handle Purchase
```swift
Task {
    if let package = subscriptionManager.monthlyPackage {
        let success = await subscriptionManager.purchase(package: package)
        if success {
            // Handle successful purchase
        }
    }
}
```

### Restore Purchases
```swift
Task {
    let success = await subscriptionManager.restorePurchases()
    if success {
        // Handle successful restore
    }
}
```

## Key Features

### RevenueCatManager
- **ObservableObject** - Automatically updates UI when subscription status changes
- **Real-time updates** - Receives subscription changes from RevenueCat
- **Error handling** - Comprehensive error handling for all purchase flows
- **Convenience properties** - Easy access to pricing, packages, and status

### RevenueCatSubscriptionView
- **Complete subscription management** - View, purchase, and manage subscriptions
- **Error handling** - User-friendly error messages
- **Restore purchases** - Built-in restore functionality
- **Support links** - Direct links to billing support

### RevenueCatUpgradeView
- **Beautiful upgrade UI** - Professional upgrade prompt
- **Feature highlights** - Showcase pro features
- **Pricing comparison** - Clear pricing options
- **Free trial support** - Handle free trial flows

## Testing

### Sandbox Testing
1. Create sandbox test users in App Store Connect
2. Sign out of App Store on your device
3. Sign in with sandbox test user
4. Test purchases in your app

### StoreKit Configuration
1. Create StoreKit configuration file in Xcode
2. Add your products with test data
3. Select configuration in scheme run options

## Production Deployment

### Final Checklist
- [ ] API key configured correctly
- [ ] Product IDs match App Store Connect
- [ ] Entitlement ID matches RevenueCat dashboard
- [ ] Tested with sandbox users
- [ ] Tested restore purchases
- [ ] Error handling tested

### App Store Review
- RevenueCat handles receipt validation automatically
- No additional server-side code needed
- Ensure all subscription flows work correctly

## Troubleshooting

### Common Issues
1. **"Product not available"** - Check product IDs and App Store Connect setup
2. **"Purchase failed"** - Verify API key and entitlement configuration
3. **"No offerings available"** - Check offerings setup in RevenueCat dashboard

### Debug Mode
Enable debug logging:
```swift
Purchases.logLevel = .debug
```

## Support
- [RevenueCat Documentation](https://docs.revenuecat.com)
- [RevenueCat Support](https://support.revenuecat.com)
- [iOS In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)

## Next Steps
1. Complete RevenueCat dashboard setup
2. Update configuration with your API key
3. Test with sandbox users
4. Deploy to production
5. Monitor subscription metrics
