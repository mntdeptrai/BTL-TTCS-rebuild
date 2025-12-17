import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/main.dart'; // Đảm bảo import đúng file main.dart
import '../lib/firebase_options.dart'; // Sửa đường dẫn import thành ../lib/firebase_options.dart

void main() {
  // Khởi tạo Firebase cho test
  setupFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Khởi tạo Firebase trước khi chạy test
    await setupFirebase();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the login screen is displayed.
    expect(find.text('Đăng Nhập'), findsOneWidget); // Kiểm tra tiêu đề AppBar
    expect(find.byType(TextField), findsNWidgets(2)); // Kiểm tra 2 TextField (identifier và password)
    expect(find.text('Đăng Ký'), findsOneWidget); // Kiểm tra nút Đăng Ký

    // Simulate tapping the "Đăng Ký" button and trigger a frame.
    await tester.tap(find.text('Đăng Ký'));
    await tester.pump();

    // Verify that the screen switches to registration mode.
    expect(find.text('Đăng Ký'), findsNWidgets(2)); // Tiêu đề và nút
    expect(find.text('Đăng Nhập'), findsOneWidget); // Nút chuyển sang đăng nhập
  });
}