import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // BƯỚC 1: TẠO NOTIFICATION CHANNEL (BẮT BUỘC CHO ANDROID 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel_id', // ID phải trùng với _showNotification
      'Thông Báo Nhiệm Vụ',
      description: 'Thông báo về nhiệm vụ mới và sắp hết hạn',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // BƯỚC 2: KHỞI TẠO LOCAL NOTIFICATION
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: android);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          print('Nhấn thông báo: ${response.payload}');
          // TODO: Điều hướng đến TaskDetailScreen
        }
      },
    );

    // BƯỚC 3: YÊU CẦU QUYỀN
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // BƯỚC 4: LẤY TOKEN
    final token = await _messaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('FCM Token: $token');
    }

    // BƯỚC 5: XỬ LÝ KHI NHẬN THÔNG BÁO (APP ĐANG MỞ)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // BƯỚC 6: KHI MỞ TỪ THÔNG BÁO
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Mở từ thông báo: ${message.data}');
    });
  }

  // HIỂN THỊ THÔNG BÁO
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel_id', // PHẢI TRÙNG VỚI CHANNEL ID
      'Thông Báo Nhiệm Vụ',
      channelDescription: 'Thông báo về nhiệm vụ mới',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Nhiệm Vụ Mới',
      message.notification?.body ?? 'Bạn có một nhiệm vụ mới!',
      details,
      payload: message.data['taskId'],
    );
  }

  // LƯU TOKEN VÀO FIRESTORE
  static Future<void> saveTokenToFirestore(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }
}