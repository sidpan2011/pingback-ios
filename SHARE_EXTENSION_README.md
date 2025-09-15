# Pingback Share Extension

The Pingback Share Extension allows users to quickly create follow-ups from shared content in other apps. This document explains how to test and use the share extension.

## Features

- **Text-Only Input**: Accepts plain text content from other apps
- **URL Detection**: Automatically extracts URLs from shared text
- **Source App Detection**: Identifies the app the content was shared from
- **Contact Detection**: Attempts to extract contact/chat names (best effort)
- **Silent Creation**: Creates follow-ups in the background without opening the main app
- **App Groups**: Uses shared data storage so main app sees new follow-ups immediately

## Configuration

### App Groups
The extension uses the app group `group.app.pingback.shared` to share data with the main app. Both targets must be configured with this app group entitlement.

### Supported Content Types
- Plain text (`public.plain-text`)
- URLs (`public.url`) 
- Web URLs (limited to 1)

## Testing the Share Extension

### Method 1: From Other Apps
1. Open any app with shareable text content (Messages, Notes, Safari, etc.)
2. Select text or tap the share button
3. Look for "Pingback" in the share sheet
4. Tap "Pingback" to open the share extension
5. Review the content and tap "Post" to create the follow-up
6. The extension will show "Added to Pingback ✓" and dismiss automatically

### Method 2: Debug Mode (Simulator/Device)
1. Set a breakpoint in `ShareViewController.viewDidLoad()`
2. Trigger the share extension from another app
3. In the debugger console, call: `po self.loadTestContent()`
4. Continue execution to see test content loaded
5. Tap "Post" to test the creation flow

### Method 3: Simulator Testing
1. Open Safari in the simulator
2. Navigate to any webpage with text
3. Select some text and tap "Share"
4. Choose "Pingback" from the share sheet
5. Test the flow end-to-end

## Expected Behavior

### Successful Flow
1. Extension opens with "Add to Pingback" title
2. Shared text appears in the text view
3. User can edit the text if needed
4. Tapping "Post" creates the follow-up
5. Title changes to "Added to Pingback ✓"
6. Extension dismisses after 0.5 seconds
7. Main app shows the new follow-up when next opened

### Error Handling
- Invalid/empty content: Post button remains disabled
- Creation failure: Shows error alert with retry option
- Network/storage issues: Graceful error handling with user feedback

## Follow-Up Data Structure

Created follow-ups include:
- **Title**: First 100 characters of shared text
- **Notes**: Full shared text content
- **Source App**: Human-readable app name (e.g., "WhatsApp", "Messages")
- **Source Bundle ID**: Technical bundle identifier
- **Contact**: Extracted contact name (if available)
- **URL**: First URL found in text (if any)
- **Due Date**: 24 hours from creation (default)
- **Type**: "DO" (default action type)
- **Status**: "open"

## Debugging

### Debug Logs
In DEBUG builds, the extension logs detailed information:
```
📥 ShareExtension: Loaded content
   - Text length: 156
   - Source: WhatsApp
   - Contact: John Doe
   - URL: https://example.com

📤 ShareExtension: Processing share
   - Text: Hey, can you follow up on the project status? https://example.com/project...
   - Source: WhatsApp (com.whatsapp.WhatsApp)
   - Contact: John Doe
   - URL: https://example.com/project

✅ ShareExtension: Follow-up created successfully
```

### Common Issues

**Extension doesn't appear in share sheet:**
- Check that the extension target is included in the build
- Verify Info.plist activation rules are correct
- Ensure the sharing app supports the content types we accept

**Follow-up not appearing in main app:**
- Check that both app and extension use the same app group
- Verify Core Data model is accessible to both targets
- Ensure SharedCoreDataStack is properly configured

**Content not loading:**
- Check that the sharing app provides the expected content types
- Verify ShareExtensionHelpers.extractText() is working
- Test with different source apps

## Supported Source Apps

The extension recognizes and provides friendly names for:
- **Messaging**: WhatsApp, Messages, Messenger, Telegram, Discord, Slack, Teams
- **Email**: Mail, Gmail, Outlook  
- **Browsers**: Safari, Chrome, Firefox
- **Notes**: Notes, Evernote, Notion
- **Social**: Twitter, Facebook, LinkedIn, Instagram, Reddit

Unknown apps will show their bundle identifier or a generic name.

## Privacy & Security

- Extension only requests App Groups entitlement
- No network access or external API calls
- Content processing happens locally
- Shared data stored securely in app group container
- No sensitive data logged in production builds

## Performance

- Lightweight processing optimized for share extensions
- Text content limited to 5000 characters to prevent memory issues
- Background Core Data operations for non-blocking UI
- Quick dismissal (0.5s) for good user experience
- Timeout handling for long operations
