import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_detail_screen.dart';
import 'models/task.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

// Background handler – BẮT BUỘC top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  await AuthService.refreshTokenOnLaunch(); // Cập nhật FCM token ngay khi mở app

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  runApp(MyApp(initialMessage: initialMessage));
}

class MyApp extends StatelessWidget {
  final RemoteMessage? initialMessage;
  const MyApp({Key? key, this.initialMessage}) : super(key: key);

  static Future<void> openTaskFromNotification(BuildContext context, String taskId) async {
    if (!context.mounted) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhiệm vụ không tồn tại hoặc đã bị xóa')),
        );
        return;
      }

      final task = Task.fromJson(doc.data()!, doc.id);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => TaskListScreen()),
              (route) => false,
        );

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
        }
      } else {
        await prefs.setString('pending_task_id', taskId);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
              (route) => false,
        );
      }
    } catch (e) {
      print("Lỗi mở task từ thông báo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Nhiệm Vụ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: SplashHandler(initialMessage: initialMessage),
    );
  }
}

class SplashHandler extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const SplashHandler({Key? key, this.initialMessage}) : super(key: key);

  @override
  State<SplashHandler> createState() => _SplashHandlerState();
}

class _SplashHandlerState extends State<SplashHandler> {
  @override
  void initState() {
    super.initState();

    if (widget.initialMessage != null) {
      final taskId = widget.initialMessage!.data['taskId']?.toString();
      if (taskId != null && taskId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            MyApp.openTaskFromNotification(context, taskId);
          }
        });
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final taskId = message.data['taskId']?.toString();
      if (taskId != null && taskId.isNotEmpty && mounted) {
        MyApp.openTaskFromNotification(context, taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final pendingTaskId = prefs.getString('pending_task_id');

    if (userId != null && userId.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TaskListScreen()),
      );

      if (pendingTaskId != null) {
        await Future.delayed(const Duration(milliseconds: 600));

        try {
          final doc = await FirebaseFirestore.instance.collection('tasks').doc(pendingTaskId).get();
          if (doc.exists && mounted) {
            final task = Task.fromJson(doc.data()!, doc.id);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
              );
            }
            await prefs.remove('pending_task_id');
          }
        } catch (e) {
          print("Lỗi mở pending task: $e");
        }
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải ứng dụng...'),
          ],
        ),
      ),
    );
  }
}