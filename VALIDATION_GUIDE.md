# End-to-End Sharing Validation Guide

This guide validates the single source-app resolver implementation with structured logging and consistent data persistence.

## Implementation Summary

✅ **Single Detection Path**: All app detection now goes through `ShareExtensionHelpers.smartAppDetection()` only
✅ **Structured Logging**: Added `event=ShareResolve` and `event=SharePersist` log lines
✅ **Consistent Persistence**: SharedDataManager uses exact bundle ID mapping without re-deriving
✅ **Deprecated Legacy Methods**: Old detection methods are marked deprecated and disabled
✅ **Unit Tests**: Created ShareExtensionResolverTests for regression protection

## Validation Steps

### 1. Single Detection Path Verification ✅

**What Changed:**
- `ShareViewController` now uses only `ShareExtensionHelpers.smartAppDetection()`
- Removed multi-step detection fallbacks
- Disabled legacy methods: `getSourceBundleId()`, `detectSourceAppFromContent()`, `getBundleId()`

**Verification:**
- Check Xcode console for deprecation warnings if legacy methods are called
- All app detection should show single `event=ShareResolve` log line

### 2. Structured Logging ✅

**Log Format:**
```
event=ShareResolve app=<name> bundle=<id> confidence=<source> textLen=<n> url=<string> contact=<string>
event=SharePersist id=<uuid> snippet=<prefix40> app=<name> bundle=<id> url=<string> contact=<string>
```

**Confidence Sources:**
- `context.bundleId`: Extension context provided bundle ID
- `title`: Found in NSExtensionItem title
- `userInfo`: Found in NSExtensionItem userInfo
- `heuristic.url`: Detected from URL patterns (wa.me, instagram.com, t.me)
- `heuristic.text`: Detected from text content
- `heuristic.pattern`: WhatsApp message export pattern
- `heuristic.genericUrl`: Generic HTTP URL → Safari
- `none`: Unknown/fallback case

### 3. Manual Testing Protocol

#### 3.1 Smoke Tests from Real Apps

**Test each app and capture console logs:**

1. **WhatsApp**
   - Share a message: "Hey, can you call me back?"
   - Expected: `app=WhatsApp bundle=com.whatsapp.WhatsApp confidence=context.bundleId`

2. **Telegram** 
   - Share a message: "Check this out"
   - Expected: `app=Telegram bundle=com.telegram.Telegram confidence=context.bundleId`

3. **Instagram**
   - Share a post/story
   - Expected: `app=Instagram bundle=com.instagram.app confidence=context.bundleId`

4. **Safari**
   - Share a URL: "https://example.com"
   - Expected: `app=Safari bundle=com.apple.mobilesafari confidence=context.bundleId`

5. **Mail**
   - Share email content
   - Expected: `app=Mail bundle=com.apple.mobilemail confidence=context.bundleId`

#### 3.2 Edge Cases Testing

**Test these scenarios:**

1. **Plain text without URLs**
   - Text: "Good morning"
   - Expected: `confidence=none` unless app context is available

2. **Text with instagram.com (no http prefix)**
   - Text: "Check instagram.com/user/post"
   - Expected: `app=Instagram confidence=heuristic.url`

3. **Short message**
   - Text: "Ok"
   - Expected: Depends on source app context

4. **WhatsApp export pattern**
   - Text: "John, [Sep 15, 2025 at 3:32 PM] Hello there"
   - Expected: `app=WhatsApp confidence=heuristic.pattern`

5. **Multi-line chat export**
   - Text with multiple lines and timestamps
   - Expected: Should not misclassify unless clear indicators

#### 3.3 Bundle ID Mapping Verification

**Confirm these exact mappings:**
- `com.whatsapp.WhatsApp` → `AppKind.whatsapp` → "WhatsApp"
- `com.telegram.Telegram` → `AppKind.telegram` → "Telegram"  
- `com.instagram.app` → `AppKind.instagram` → "Instagram"
- `com.apple.MobileSMS` → `AppKind.sms` → "SMS"
- `com.apple.mobilemail` → `AppKind.email` → "Mail"
- `unknown` → `AppKind.other` → "Other"

### 4. Core Data Verification

**After each share, check the main app:**

1. Open Pingback app
2. Go to home screen
3. Find the latest FollowUp entry
4. Verify fields match console logs:
   - `snippet` matches SharePersist snippet
   - `app` matches resolved app name
   - `contactLabel` matches contact (or "Unknown" if none)
   - `url` matches extracted URL (if any)

**Console Check:**
Look for SharedDataManager logs:
```
🔍 SharedDataManager: === PRECISE BUNDLE ID MAPPING ===
✅ SharedDataManager: Exact match - WhatsApp
```

### 5. UI Verification

**In FollowUp list:**
1. Correct app icon appears (WhatsApp, Telegram, Instagram logos)
2. App name is displayed correctly
3. URLs are tappable links
4. No "Other" unless truly unknown
5. Contact names display properly

### 6. Testing Commands

**Build and run:**
```bash
xcodebuild build -project pingback.xcodeproj -scheme pingback -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

**Run resolver tests:**
```bash
# Unit tests are in Tests/ShareExtensionResolverTests.swift
# Run via Xcode or add to CI pipeline
```

### 7. Exit Criteria

**Pass if ALL true:**

✅ Every manual share shows single resolver path in logs
✅ Consistent (appName, bundleId) in Core Data and UI  
✅ No incorrect WhatsApp defaults
✅ Instagram/Telegram detected when expected
✅ Unknown cases labeled "Unknown App / unknown" with `confidence=none`
✅ No post-save mutation of app data
✅ Bundle ID mappings are consistent
✅ Structured logs capture all required fields
✅ UI displays correct app icons and names

### 8. Troubleshooting

**Common Issues:**

1. **Multiple detection paths**: Check for deprecated method warnings
2. **Inconsistent mapping**: Verify SharedDataManager uses exact bundle IDs
3. **Missing logs**: Ensure DEBUG build configuration
4. **Wrong app icons**: Check AppKind mapping in FollowUp.swift
5. **Re-derived data**: Verify SharedDataManager doesn't call legacy methods

**Debug Console Filters:**
- `event=ShareResolve` - App detection results
- `event=SharePersist` - Persistence data
- `SharedDataManager: === PRECISE BUNDLE ID MAPPING ===` - Mapping logic
- `DEPRECATED:` - Legacy method usage warnings

### 9. Known Limitations

- Extension context bundle ID may not always be available (iOS privacy)
- Contact extraction is limited by iOS share extension capabilities  
- Some apps may not provide clear identification signals
- Heuristic detection is conservative to avoid false positives

### 10. Next Steps

- Add more test cases to ShareExtensionResolverTests.swift
- Monitor real-world usage for edge cases
- Consider adding telemetry for detection confidence rates
- Optimize heuristics based on user feedback
