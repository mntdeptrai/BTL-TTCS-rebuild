// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static int _id = 1000;

  static Future<void> initialize() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          print("Clicked: ${details.payload}");
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo nhiệm vụ',
      description: 'Thông báo nhiệm vụ mới',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        final notification = message.notification;
        final data = message.data;

        String title = notification?.title ?? data['title'] ?? 'Nhiệm vụ mới';
        String body = notification?.body ?? data['body'] ?? 'Bạn được giao nhiệm vụ mới';

        await _show(title, body, data['taskId']);
      } catch (e) {
        print("Lỗi show notification: $e"); // Log để debug nếu crash
      }
    });
  }

  static Future<void> _show(String title, String body, String? taskId) async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'high_importance_channel',
      'Thông báo nhiệm vụ',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
    );

    await _plugin.show(
      _id++,
      title,
      body,
      const NotificationDetails(android: android),
      payload: taskId,
    );
  }
}