import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/notification_service.dart';
import '../../core/di/service_locator.dart';

/// Dialog to request notification permissions
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('السماح بالإشعارات'),
      content: const Text(
        'لتلقي إشعارات عند اكتمال تحميل الملفات، يرجى السماح بإرسال الإشعارات.',
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('لاحقاً'),
        ),
        ElevatedButton(
          onPressed: () async {
            final notificationService = serviceLocator.get<NotificationService>();
            final granted = await notificationService.requestPermissions();
            if (context.mounted) {
              Navigator.of(context).pop(granted);
            }
          },
          child: const Text('السماح'),
        ),
      ],
    );
  }

  /// Show the permission dialog
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationPermissionDialog(),
    );
    return result ?? false;
  }

  /// Check and request notification permission if needed
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    final notificationService = serviceLocator.get<NotificationService>();
    
    // Check if already granted
    final isEnabled = await notificationService.areNotificationsEnabled();
    if (isEnabled) {
      return; // Already granted, no need to ask
    }

    // Show dialog to request permission
    await show(context);
  }
}

/// Show settings dialog when permission is permanently denied
class NotificationPermissionSettingsDialog extends StatelessWidget {
  const NotificationPermissionSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تفعيل الإشعارات'),
      content: const Text(
        'لم يتم منح إذن الإشعارات. يرجى تفعيل الإشعارات من إعدادات التطبيق لتلقي إشعارات التحميل.',
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            await openAppSettings();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('فتح الإعدادات'),
        ),
      ],
    );
  }

  /// Show the settings dialog
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const NotificationPermissionSettingsDialog(),
    );
  }
}
