import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart'; // ĐÃ THÊM: Khởi tạo thông báo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BƯỚC 1: KHỞI TẠO FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // BƯỚC 2: KHỞI TẠO HỆ THỐNG THÔNG BÁO (FCM + LOCAL NOTIFICATION)
  await NotificationService.initialize();

  // BƯỚC 3: CHẠY ỨNG DỤNG
  runApp(const UngDungQuanLyNhiemVu());
}

class UngDungQuanLyNhiemVu extends StatelessWidget {
  const UngDungQuanLyNhiemVu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Nhiệm Vụ',
      debugShowCheckedModeBanner: false, // Ẩn banner debug
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        useMaterial3: true, // Bật Material 3 cho UI hiện đại
      ),
      home:  ManHinhDangNhap(),
    );
  }
}