import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(UngDungQuanLyNhiemVu());
}

class UngDungQuanLyNhiemVu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Nhiệm Vụ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ManHinhDangNhap(),
    );
  }
}