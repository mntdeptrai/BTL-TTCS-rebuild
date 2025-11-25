import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static int _id = 1000;

  static Future<void> initialize() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          print("Thông báo được bấm – Task ID: ${details.payload}");
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo nhiệm vụ',
      description: 'Thông báo khi có nhiệm vụ mới hoặc sắp hết hạn',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final data = message.data;

      String title = notification?.title ?? data['title'] ?? 'Nhiệm vụ mới';
      String body = notification?.body ?? data['body'] ?? 'Bạn được giao một nhiệm vụ mới';

      final String? taskId = data['taskId']?.toString();

      await showNotification(title: title, body: body, taskId: taskId);
    });
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'high_importance_channel',
      'Thông báo nhiệm vụ',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      ticker: 'Nhiệm vụ mới',
    );

    const NotificationDetails details = NotificationDetails(android: android);

    await _plugin.show(
      _id++,
      title,
      body,
      details,
      payload: taskId,
    );
  }
}