# Pingback

A productivity app for managing follow-ups and reminders.

## App Store Submission

### Export Compliance

This app is configured for App Store submission with the following encryption compliance settings:

- **ITSAppUsesNonExemptEncryption = NO** is set on all targets (main app and Share Extension)
- We do not implement standard or proprietary encryption algorithms in-app; we rely on Apple's OS
- All networking uses HTTPS/TLS through Apple's system networking and third-party services
- We use only Apple's Keychain for secure storage
- No custom cryptography libraries (OpenSSL, libsodium, etc.) are included
- No App Transport Security (ATS) exceptions are configured

**App Store Connect Answer:** When asked about encryption usage during submission, select **"None of the algorithms mentioned above."**

This configuration allows the app to bypass export compliance requirements as we only use Apple's standard encryption and third-party services over secure connections.

## Architecture

The app uses:
- SwiftUI for the user interface
- Core Data for local data persistence
- RevenueCat for subscription management
- Apple's native frameworks (Foundation, StoreKit, etc.)
- Share Extension for system integration

## Development

### Requirements
- iOS 18.5+
- Xcode 16.4+
- Swift 5.0+

### Third-Party Dependencies
- RevenueCat SDK (for subscription management)

All dependencies use HTTPS for network communication and do not implement custom encryption.
