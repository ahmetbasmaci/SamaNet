import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

/// Service for handling local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _lastDownloadedFilePath;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      await openFile(response.payload!);
    }
  }

  /// Request notification permissions (iOS and Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need to request notification permission
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true; // Android < 13 doesn't require runtime permission
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // This is a workaround to get Android version
      // We'll use permission_handler which internally checks the version
      return 33; // Assume Android 13+ for safety, will request permission
    } catch (e) {
      return 33; // Default to requiring permission
    }
  }

  /// Check if notification permission is granted
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // For iOS, we can't check without requesting, so assume granted
      return true;
    }
    return true;
  }

  /// Show download complete notification
  Future<void> showDownloadCompleteNotification({
    required String fileName,
    required String filePath,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _lastDownloadedFilePath = filePath;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'File Downloads',
      channelDescription: 'Notifications for completed file downloads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique notification ID
      'تم تحميل الملف',
      'تم تحميل $fileName بنجاح. اضغط للفتح',
      notificationDetails,
      payload: filePath,
    );
  }

  /// Show download progress notification (optional)
  Future<void> showDownloadProgressNotification({
    required String fileName,
    required int progress,
    required int id,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_progress_channel',
      'Download Progress',
      channelDescription: 'Shows download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'جاري التحميل',
      'تحميل $fileName ($progress%)',
      notificationDetails,
    );
  }

  /// Cancel download progress notification
  Future<void> cancelDownloadProgressNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Open a file using the system default app
  Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        // Handle different result types
        print('Failed to open file: ${result.message}');
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  /// Get the last downloaded file path
  String? get lastDownloadedFilePath => _lastDownloadedFilePath;
}
