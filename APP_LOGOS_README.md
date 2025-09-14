# App Logos Setup Guide

## 📁 Folder Structure
The app logos are stored in: `pingback/Assets.xcassets/AppLogos.xcassets/`

## 🖼️ Required Logo Files

For each app, you need to add PNG files in the respective folders:

### WhatsApp
- **Folder**: `pingback/Assets.xcassets/AppLogos.xcassets/whatsapp.imageset/`
- **Files needed**:
  - `whatsapp.png` (1x - 32x32px)
  - `whatsapp@2x.png` (2x - 64x64px)  
  - `whatsapp@3x.png` (3x - 96x96px)

### Telegram
- **Folder**: `pingback/Assets.xcassets/AppLogos.xcassets/telegram.imageset/`
- **Files needed**:
  - `telegram.png` (1x - 32x32px)
  - `telegram@2x.png` (2x - 64x64px)
  - `telegram@3x.png` (3x - 96x96px)

### Email
- **Folder**: `pingback/Assets.xcassets/AppLogos.xcassets/email.imageset/`
- **Files needed**:
  - `email.png` (1x - 32x32px)
  - `email@2x.png` (2x - 64x64px)
  - `email@3x.png` (3x - 96x96px)

### SMS
- **Folder**: `pingback/Assets.xcassets/AppLogos.xcassets/sms.imageset/`
- **Files needed**:
  - `sms.png` (1x - 32x32px)
  - `sms@2x.png` (2x - 64x64px)
  - `sms@3x.png` (3x - 96x96px)

### Other
- **Folder**: `pingback/Assets.xcassets/AppLogos.xcassets/other.imageset/`
- **Files needed**:
  - `other.png` (1x - 32x32px)
  - `other@2x.png` (2x - 64x64px)
  - `other@3x.png` (3x - 96x96px)

## 📋 Instructions

1. **Get the app logos** in PNG format (square, transparent background recommended)
2. **Resize them** to the required dimensions:
   - 1x: 32×32 pixels
   - 2x: 64×64 pixels  
   - 3x: 96×96 pixels
3. **Name them correctly** using the exact filenames listed above
4. **Place them** in the corresponding `.imageset` folders
5. **Build the app** - logos will automatically appear!

## 🔄 Fallback System

- ✅ **If logo exists**: Shows the custom PNG logo
- 🔄 **If logo missing**: Falls back to SF Symbol icons
- 🎯 **No crashes**: App works regardless of missing logos

## 🎨 Logo Guidelines

- **Format**: PNG with transparent background
- **Style**: Official app logos work best
- **Shape**: Square aspect ratio preferred
- **Quality**: High resolution for crisp display

## 🚀 Adding New Apps

To add a new app:

1. Add the case to `AppKind` enum in `Models/FollowUp.swift`
2. Create a new `.imageset` folder in `AppLogos.xcassets/`
3. Add the `Contents.json` file (copy from existing ones)
4. Add your PNG files with the correct naming

## 🔧 Technical Details

- Uses `UIImage(named:)` to check if logo exists
- Automatically falls back to SF Symbols if missing
- Logos are bundled with the app for optimal performance
- Supports all iOS screen densities (1x, 2x, 3x)

---

**Ready to add your logos!** Just drop the PNG files in the folders and build the app. 🎉
