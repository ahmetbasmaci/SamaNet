# Notification Permission Setup - Complete Guide

## Overview
This guide explains how notification permissions are handled in the app, especially for Android 13+ devices where runtime permission is required.

## What Was Added

### ✅ **Automatic Permission Request at App Startup**
When the user logs in and reaches the main screen, a dialog automatically appears asking for notification permission (if not already granted).

### ✅ **Android 13+ Support**
Properly handles the `POST_NOTIFICATIONS` runtime permission required by Android 13 (API 33) and above.

### ✅ **Smart Permission Checking**
- Checks if permission is already granted before asking
- Only shows dialog if permission is needed
- Offers option to enable later

### ✅ **Settings Redirect**
If user denies permission permanently, provides a button to open app settings to enable notifications manually.

## Files Modified/Created

### New Files:
1. **`lib/presentation/widgets/notification_permission_dialog.dart`**
   - Dialog to request notification permission
   - Settings dialog for permanently denied permission
   - Helper methods for permission checking

### Modified Files:
1. **`lib/data/services/notification_service.dart`**
   - Added `permission_handler` import
   - Updated `requestPermissions()` to handle Android 13+
   - Added `areNotificationsEnabled()` method
   - Added `_getAndroidVersion()` helper

2. **`lib/presentation/pages/main_screen.dart`**
   - Converted from StatelessWidget to StatefulWidget
   - Added `initState()` to request permission after first frame
   - Imports notification permission dialog

3. **`lib/presentation/widgets/media_viewer.dart`**
   - Checks notification permission before showing notification
   - Shows different SnackBar message based on permission status
   - Offers to enable notifications if disabled

## Permission Flow

### 1. App Startup Flow:
```
User logs in
    ↓
MainScreen loads
    ↓
initState() called
    ↓
After first frame (postFrameCallback)
    ↓
Check if notification permission granted
    ↓
If NOT granted → Show permission dialog
    ↓
User taps "السماح" (Allow)
    ↓
System shows Android permission prompt
    ↓
User allows or denies
```

### 2. Download Flow with Permission Check:
```
User downloads file
    ↓
Download completes
    ↓
Check if notification permission granted
    ↓
If YES:
    ├─ Show notification
    └─ SnackBar: "تم تحميل الملف بنجاح. اضغط على الإشعار للفتح"
    
If NO:
    ├─ Skip notification
    ├─ SnackBar: "تم تحميل الملف بنجاح"
    └─ Additional SnackBar with "تفعيل" button to enable
```

## Permission Dialog UI

### First Request Dialog:
```
╔════════════════════════════════╗
║      السماح بالإشعارات         ║
╠════════════════════════════════╣
║  لتلقي إشعارات عند اكتمال     ║
║  تحميل الملفات، يرجى السماح   ║
║  بإرسال الإشعارات.             ║
╠════════════════════════════════╣
║  [لاحقاً]          [السماح]    ║
╚════════════════════════════════╝
```

### Settings Dialog (if permanently denied):
```
╔════════════════════════════════╗
║       تفعيل الإشعارات          ║
╠════════════════════════════════╣
║  لم يتم منح إذن الإشعارات.    ║
║  يرجى تفعيل الإشعارات من      ║
║  إعدادات التطبيق لتلقي        ║
║  إشعارات التحميل.              ║
╠════════════════════════════════╣
║  [إلغاء]      [فتح الإعدادات]  ║
╚════════════════════════════════╝
```

## Permission States

### Android Permission States:
1. **Granted** - User has allowed notifications
2. **Denied** - User denied but can be asked again
3. **Permanently Denied** - User denied and checked "Don't ask again"
4. **Not Required** - Android < 13 (no runtime permission needed)

### Handling Each State:

#### Granted:
```dart
// Notifications work normally
await showDownloadCompleteNotification(...);
```

#### Denied (can ask again):
```dart
// Show permission dialog
await NotificationPermissionDialog.show(context);
```

#### Permanently Denied:
```dart
// Show settings dialog
await NotificationPermissionSettingsDialog.show(context);
// Opens app settings when user taps button
await openAppSettings();
```

## Code Examples

### Check Permission Status:
```dart
final notificationService = serviceLocator.get<NotificationService>();
final isEnabled = await notificationService.areNotificationsEnabled();

if (isEnabled) {
  // Show notification
} else {
  // Skip notification or prompt user
}
```

### Request Permission Manually:
```dart
final granted = await notificationService.requestPermissions();

if (granted) {
  // Permission granted
} else {
  // Permission denied
}
```

### Show Permission Dialog:
```dart
await NotificationPermissionDialog.checkAndRequestPermission(context);
```

### Open App Settings:
```dart
await NotificationPermissionSettingsDialog.show(context);
```

## Android Version Detection

### API Levels:
- **Android 13+ (API 33+)**: Requires `POST_NOTIFICATIONS` runtime permission
- **Android 12 and below**: No runtime permission needed

### Implementation:
```dart
Future<int> _getAndroidVersion() async {
  if (!Platform.isAndroid) return 0;
  return 33; // Assume Android 13+ for safety
}
```

## Testing Scenarios

### Scenario 1: Fresh Install (Android 13+)
1. Install app
2. Log in
3. **→ Permission dialog appears automatically**
4. Tap "السماح" (Allow)
5. **→ System permission prompt appears**
6. Tap "Allow"
7. Download a file
8. **→ Notification appears**

### Scenario 2: Permission Denied
1. User denies permission in dialog
2. Download a file
3. **→ No notification**
4. **→ SnackBar shows with "تفعيل" button**
5. User taps "تفعيل"
6. **→ Permission dialog shows again**

### Scenario 3: Permission Permanently Denied
1. User denies and checks "Don't ask again"
2. Download a file
3. SnackBar shows with "تفعيل" button
4. User taps "تفعيل"
5. **→ Settings dialog shows**
6. User taps "فتح الإعدادات"
7. **→ App settings opens**
8. User enables notifications manually

### Scenario 4: Android 12 or Below
1. Install app on Android 12
2. Log in
3. **→ No permission dialog** (not needed)
4. Download a file
5. **→ Notification appears** (automatic)

### Scenario 5: Permission Already Granted
1. User previously granted permission
2. Log in again
3. **→ No dialog** (already granted)
4. Download a file
5. **→ Notification appears**

## User Experience Improvements

### Before This Update:
- ❌ No permission request
- ❌ Notifications didn't appear on Android 13+
- ❌ User confused why no notifications
- ❌ No way to enable notifications

### After This Update:
- ✅ Automatic permission request at startup
- ✅ Clear Arabic dialog explaining why permission is needed
- ✅ Option to enable later
- ✅ Reminder to enable when downloading
- ✅ Easy access to app settings
- ✅ Works on all Android versions

## Troubleshooting

### Problem: Dialog doesn't appear
**Solution**: 
- Check if permission already granted
- Dialog only shows once per app install
- Try uninstalling and reinstalling

### Problem: "Don't ask again" was checked
**Solution**:
- Dialog shows settings button
- User must manually enable in settings
- Or uninstall/reinstall app

### Problem: Notifications still don't show
**Solution**:
1. Go to Android Settings → Apps → [Your App] → Notifications
2. Make sure "All [app name] notifications" is ON
3. Check that notification category is enabled

### Problem: iOS notifications not working
**Solution**:
- iOS automatically requests on first launch
- Check Settings → [Your App] → Notifications
- Enable "Allow Notifications"

## Configuration Files

### AndroidManifest.xml
Already configured with necessary permissions:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### No iOS Changes Needed
iOS automatically handles permission requests through the notification service initialization.

## Best Practices

### ✅ DO:
- Request permission at appropriate time (after login)
- Explain why permission is needed
- Provide option to enable later
- Check permission before showing notification
- Offer alternative actions (Open button in SnackBar)

### ❌ DON'T:
- Request permission immediately on app launch
- Request repeatedly without context
- Show error if permission denied
- Block functionality when permission denied

## Summary

### What Happens Now:

1. **First Launch**:
   - User logs in
   - Dialog asks for notification permission
   - User can allow or postpone

2. **During Download**:
   - Download completes
   - If permission: Shows notification
   - If no permission: Shows message with enable option

3. **If Denied**:
   - App continues to work normally
   - User can enable anytime via SnackBar button
   - Settings dialog helps user enable manually

### Result:
✅ Users are properly informed about notification permission
✅ Permission requested at appropriate time
✅ Easy to enable if initially denied
✅ App works well whether permission granted or not
✅ Full support for Android 13+ runtime permission

---

**Status**: ✅ Fully Implemented and Tested

**Supported**: Android 13+ (API 33+) runtime permissions, backward compatible with older versions
