# RevenueCat Setup Guide for Pingback

This guide will help you set up RevenueCat for subscription management in your iOS app.

## Prerequisites

1. **RevenueCat Account**: Sign up at [RevenueCat Dashboard](https://app.revenuecat.com)
2. **App Store Connect Account**: For creating in-app purchases
3. **Xcode 15+**: For iOS development

## Step 1: RevenueCat Dashboard Setup

### 1.1 Create a New Project
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Click "Create New Project"
3. Enter project name: "Pingback"
4. Select platform: iOS

### 1.2 Configure App
1. In your project, click "Add App"
2. Enter your app's bundle identifier (e.g., `com.yourcompany.pingback`)
3. Select "iOS" as platform
4. Copy the generated API key

### 1.3 Create Products
1. Go to "Products" section
2. Click "Create Product"
3. Create two products:
   - **Monthly Subscription**: `pro.monthly`
   - **Yearly Subscription**: `pro.yearly`

### 1.4 Create Entitlements
1. Go to "Entitlements" section
2. Click "Create Entitlement"
3. Create entitlement: `pro`
4. Attach both products to this entitlement

### 1.5 Create Offerings
1. Go to "Offerings" section
2. Click "Create Offering"
3. Name: "default"
4. Add both packages:
   - Monthly package with `pro.monthly` product
   - Annual package with `pro.yearly` product

## Step 2: App Store Connect Setup

### 2.1 Create In-App Purchases
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "Features" → "In-App Purchases"
4. Create two auto-renewable subscriptions:
   - **Monthly**: `pro.monthly` (e.g., $4.99/month)
   - **Yearly**: `pro.yearly` (e.g., $49.99/year)

### 2.2 Configure Subscription Groups
1. Create a subscription group (e.g., "Pro Features")
2. Add both subscriptions to this group
3. Set up subscription levels and pricing

## Step 3: Xcode Configuration

### 3.1 Add RevenueCat SDK
1. Open your Xcode project
2. Go to File → Add Package Dependencies
3. Enter URL: `https://github.com/RevenueCat/purchases-ios.git`
4. Select version 4.0.0 or later
5. Add to your target

### 3.2 Update API Key
1. Open `RevenueCatConfiguration.swift`
2. Replace `"your_revenuecat_api_key_here"` with your actual API key from step 1.2

### 3.3 Update Product IDs
1. Ensure product IDs in `RevenueCatConfiguration.swift` match your App Store Connect products:
   ```swift
   struct ProductIdentifiers {
       static let monthly = "pro.monthly"  // Must match App Store Connect
       static let yearly = "pro.yearly"    // Must match App Store Connect
   }
   ```

### 3.4 Update Entitlement ID
1. Ensure entitlement ID matches your RevenueCat dashboard:
   ```swift
   struct Entitlements {
       static let pro = "pro"  // Must match RevenueCat dashboard
   }
   ```

## Step 4: Testing

### 4.1 Sandbox Testing
1. Create sandbox test users in App Store Connect
2. Sign out of App Store on your device
3. Sign in with sandbox test user
4. Test purchases in your app

### 4.2 StoreKit Configuration (Simulator)
1. Create a StoreKit configuration file in Xcode
2. Add your products with test data
3. Select the configuration in your scheme's run options

## Step 5: Integration

### 5.1 Update Subscription Views
Replace your existing subscription views with the new RevenueCat-based ones:
- Use `RevenueCatSubscriptionView` instead of `SubscriptionView`
- The new view automatically handles:
  - Product loading
  - Purchase flow
  - Subscription status
  - Error handling
  - Restore purchases

### 5.2 Check Subscription Status
Use the `RevenueCatManager` to check subscription status:
```swift
@StateObject private var subscriptionManager = RevenueCatManager.shared

// Check if user has pro access
if subscriptionManager.isPro {
    // Show pro features
}
```

## Step 6: Production Deployment

### 6.1 Final Checks
1. Verify API key is correct
2. Test with real App Store purchases
3. Ensure all product IDs match
4. Test restore purchases functionality

### 6.2 App Store Review
1. Submit your app for review
2. RevenueCat handles receipt validation automatically
3. No additional server-side code needed

## Troubleshooting

### Common Issues

1. **"Product not available"**
   - Check product IDs match App Store Connect
   - Ensure products are approved and available
   - Verify sandbox testing setup

2. **"Purchase failed"**
   - Check RevenueCat API key
   - Verify entitlement configuration
   - Test with sandbox users

3. **"No offerings available"**
   - Check offerings configuration in RevenueCat dashboard
   - Verify products are attached to offerings
   - Ensure API key has correct permissions

### Debug Mode
Enable debug logging by setting:
```swift
Purchases.logLevel = .debug
```

## Support

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [RevenueCat Support](https://support.revenuecat.com)
- [iOS In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)

## Files Created/Modified

- `RevenueCatManager.swift` - Main subscription management
- `RevenueCatConfiguration.swift` - Configuration settings
- `RevenueCatSubscriptionView.swift` - Updated subscription UI
- `pingbackApp.swift` - App initialization with RevenueCat
- `Package.swift` - RevenueCat dependency

## Next Steps

1. Complete the RevenueCat dashboard setup
2. Update the API key in `RevenueCatConfiguration.swift`
3. Test with sandbox users
4. Deploy to production
5. Monitor subscription metrics in RevenueCat dashboard
