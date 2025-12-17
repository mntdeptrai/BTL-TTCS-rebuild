import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' as main_app;
import '../models/task.dart';
import '../screens/task_detail_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static int _id = 1000;

  static Future<void> initialize() async {
    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings =
    InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          await handleNotificationClick(response.payload!);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo nhiệm vụ',
      description: 'Thông báo khi có nhiệm vụ mới, sắp hết hạn hoặc hoàn thành',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final data = message.data;

      String title = notification?.title ?? data['title'] ?? 'Thông báo';
      String body = notification?.body ?? data['body'] ?? 'Bạn có thông báo mới';

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

  static Future<void> handleNotificationClick(String taskId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (!doc.exists) {
        debugPrint('Nhiệm vụ không tồn tại: $taskId');
        return;
      }

      final task = Task.fromJson(doc.data()!, doc.id);

      final navigatorKey = main_app.MyApp.navigatorKey;


      if (navigatorKey.currentContext == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_task_id', taskId);
        return;
      }

      if (navigatorKey.currentContext!.mounted) {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xử lý click thông báo: $e');
    }
  }
}