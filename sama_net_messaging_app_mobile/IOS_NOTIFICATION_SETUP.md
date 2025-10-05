# iOS Notification Setup Guide

## Required iOS Configuration

### 1. Info.plist Configuration (Optional - for better descriptions)

If you want to customize notification permission messages, add these to your `ios/Runner/Info.plist`:

```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 2. Capabilities (Optional - for background notifications)

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Background Modes"
6. Enable "Background fetch" and "Remote notifications"

### 3. Permission Handling

The app will automatically request notification permissions on iOS when the app starts. No additional code needed!

```dart
// Already handled in service_locator.dart
await notificationService.initialize();
await notificationService.requestPermissions();
```

### 4. Testing on iOS

**Important**: Notifications may not work properly in iOS Simulator. Always test on a real device.

#### Test Steps:
1. Install app on real iOS device
2. When app first opens, allow notifications when prompted
3. Download a file
4. Check notification appears
5. Tap notification → file should open

#### If notifications don't appear:
1. Go to iOS Settings → [Your App Name] → Notifications
2. Enable "Allow Notifications"
3. Enable "Banners" or "Alerts"
4. Enable "Sounds" and "Badges"

### 5. File Provider Setup (Optional)

For opening files in other apps, iOS automatically handles this through UIDocumentInteractionController. No additional setup needed!

### 6. App Groups (Optional - for notification extensions)

If you later want to add notification extensions or widgets:

1. In Xcode, enable App Groups capability
2. Add a group: `group.[your.bundle.id]`
3. Use the same group in your extension

## Build Instructions

### Debug Build:
```bash
flutter build ios --debug
```

### Release Build:
```bash
flutter build ios --release
```

### Run on Device:
```bash
flutter run -d [device-id]
```

## Common iOS Issues

### Issue 1: Notification permissions not showing
**Solution**: Delete app and reinstall. Permissions only prompt once.

### Issue 2: File won't open
**Solution**: Make sure the file type has an associated app installed.

### Issue 3: Notification shows but doesn't open file
**Solution**: Check console logs for errors. Ensure file path is correct.

## iOS Notification Behavior

### When App is:
- **Foreground**: Notification shows as banner at top
- **Background**: Notification shows in notification center
- **Closed**: Notification shows in notification center
- **Tapped**: App opens and file opens automatically

### Notification Persistence:
- Notifications stay in notification center until dismissed
- Tapping opens the file
- Swiping dismisses the notification

## iOS File Opening

### Supported Locations:
- App Documents directory
- App Library directory
- Shared containers

### File Viewers:
iOS will use:
- **PDFs**: Native PDF viewer or installed PDF apps
- **Images**: Photos app or image viewers
- **Videos**: Native video player
- **Documents**: Pages, Word, or other document apps

## Debugging on iOS

### Enable Debug Logging:
```dart
// In notification_service.dart, add:
print('Notification tapped with payload: ${response.payload}');
```

### View Logs:
```bash
flutter logs
```

Or in Xcode:
1. Window → Devices and Simulators
2. Select your device
3. View Device Logs

## Production Checklist

- [ ] Test on real iOS device (not simulator)
- [ ] Verify notification permissions work
- [ ] Test all file types can be opened
- [ ] Test with app in foreground, background, and closed
- [ ] Verify notification sounds work
- [ ] Test Arabic text displays correctly in notifications
- [ ] Check notification badges update correctly

## Notes

- iOS automatically handles notification channels (no need for Android-style channels)
- Notification sound uses system default
- Badge numbers can be set but are optional
- iOS users can customize notification settings per app
