# App Logos Setup Instructions

This document explains how to add your custom app logos to replace the Apple system icons in the follow-up creation flow.

## Folder Structure Created

I've created the following folder structure in your Assets.xcassets:

```
Assets.xcassets/
└── AppLogos/
    ├── WhatsAppLogo.appiconset/
    │   ├── Contents.json
    │   ├── whatsapp_logo.png (1x)
    │   ├── whatsapp_logo@2x.png (2x)
    │   └── whatsapp_logo@3x.png (3x)
    ├── TelegramLogo.appiconset/
    │   ├── Contents.json
    │   ├── telegram_logo.png (1x)
    │   ├── telegram_logo@2x.png (2x)
    │   └── telegram_logo@3x.png (3x)
    ├── SMSLogo.appiconset/
    │   ├── Contents.json
    │   ├── sms_logo.png (1x)
    │   ├── sms_logo@2x.png (2x)
    │   └── sms_logo@3x.png (3x)
    ├── EmailLogo.appiconset/
    │   ├── Contents.json
    │   ├── email_logo.png (1x)
    │   ├── email_logo@2x.png (2x)
    │   └── email_logo@3x.png (3x)
    ├── InstagramLogo.appiconset/
    │   ├── Contents.json
    │   ├── instagram_logo.png (1x)
    │   ├── instagram_logo@2x.png (2x)
    │   └── instagram_logo@3x.png (3x)
    └── OtherLogo.appiconset/
        ├── Contents.json
        ├── other_logo.png (1x)
        ├── other_logo@2x.png (2x)
        └── other_logo@3x.png (3x)
```

## How to Add Your Logo Images

### Step 1: Prepare Your Images
For each app, you need to create 3 versions of your logo:
- **1x**: 32x32 pixels (for standard resolution displays)
- **2x**: 64x64 pixels (for Retina displays)
- **3x**: 96x96 pixels (for Retina HD displays)

### Step 2: Add Images to Xcode
1. Open your project in Xcode
2. Navigate to `Assets.xcassets` → `AppLogos`
3. For each logo set (WhatsAppLogo, TelegramLogo, SMSLogo, EmailLogo, InstagramLogo, OtherLogo):
   - Drag and drop your 1x image onto the 1x slot
   - Drag and drop your 2x image onto the 2x slot
   - Drag and drop your 3x image onto the 3x slot

### Step 3: Verify the Setup
The app will automatically use your custom logos once the images are added. The system will fall back to Apple's SF Symbols if the custom logos are not found.

## What's Been Updated

I've updated the following components to use your custom logos:

1. **FollowUpRow** - The main follow-up list items now show custom app logos
2. **AddFollowUpView** - The app selection in the add follow-up flow uses custom logos
3. **QuickAddView** - The quick add picker uses custom logos
4. **AppLogoView** - A reusable component that handles both custom logos and system icons

## Technical Details

The `AppLogoView` component automatically:
- Uses custom logos when available (based on `app.hasCustomLogo` property)
- Falls back to SF Symbols when custom logos are not found
- Applies proper sizing and corner radius for a polished look
- Maintains aspect ratio and proper scaling

## Logo Specifications

- **Format**: PNG with transparency support
- **Shape**: Square (will be automatically rounded)
- **Background**: Transparent or solid color
- **Style**: Should be recognizable at small sizes (32x32 to 96x96)

## Testing

Once you've added the logo images:
1. Build and run the app
2. Create a new follow-up
3. Select different apps to see your custom logos
4. Check the follow-up list to see logos in action

The app will show your custom logos everywhere Apple system icons were previously used for app selection and display.