// lib/services/auth_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  // Singleton
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ================================== ĐĂNG NHẬP ==================================
  Future<User?> dangNhap(String identifier, String password) async {
    try {
      QuerySnapshot snapshot;
      if (_isEmail(identifier)) {
        snapshot = await _firestore.collection('users').where('email', isEqualTo: identifier).limit(1).get();
      } else if (_isPhoneNumber(identifier)) {
        snapshot = await _firestore.collection('users').where('phoneNumber', isEqualTo: identifier).limit(1).get();
      } else {
        snapshot = await _firestore.collection('users').where('username', isEqualTo: identifier).limit(1).get();
      }

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final userId = doc.id;
      final email = data['email'] as String?;
      if (email == null) return null;

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = User.fromMap(data, userId);

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('userId', user.id),
        prefs.setString('username', user.username),
        prefs.setString('role', user.role ?? 'Employee'),
      ]);

      // CẬP NHẬT FCM TOKEN MỚI SAU KHI ĐĂNG NHẬP
      await _updateFcmToken(user.id);
      await prefs.remove('pending_task_id');

      print('Đăng nhập thành công: ${user.username}');
      return user;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return null;
    }
  }

  // ================================== ĐĂNG KÝ ==================================
  Future<User?> dangKy({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required String role,
    required String phoneNumber,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;

      final employeeId = (1000 + Random().nextInt(9000)).toString();

      final user = User(
        id: uid,
        username: username,
        fullName: fullName,
        employeeId: employeeId,
        role: role,
        phoneNumber: phoneNumber,
      );

      await _firestore.collection('users').doc(uid).set({
        ...user.toMap(),
        'email': email,
      });

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('userId', uid),
        prefs.setString('username', username),
        prefs.setString('role', role),
      ]);

      // CẬP NHẬT FCM TOKEN SAU KHI ĐĂNG KÝ
      await _updateFcmToken(uid);

      return user;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return null;
    }
  }

  // ================================== CẬP NHẬT FCM TOKEN ==================================
  Future<void> _updateFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM Token đã được cập nhật cho user: $userId');
      }
    } catch (e) {
      print('Lỗi cập nhật FCM token: $e');
    }
  }

  // Gọi khi app khởi động (nên gọi ở main.dart hoặc splash screen)
  static Future<void> refreshTokenOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      await AuthService()._updateFcmToken(userId);
    }
  }

  // ================================== ĐĂNG XUẤT – ĐÃ FIX HOÀN TOÀN ==================================
  Future<void> dangXuat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      // 1. XÓA FCM TOKEN TRONG FIRESTORE (QUAN TRỌNG NHẤT – NGĂN NHẬN THÔNG BÁO SAU KHI LOGOUT)
      if (currentUserId != null) {
        await _firestore.collection('users').doc(currentUserId).update({
          'fcmToken': FieldValue.delete(),
        }).catchError((e) => print('Không thể xóa token: $e'));
      }

      // 2. XÓA TOKEN KHỎI THIẾT BỊ (FCM sẽ tạo token mới khi login lại)
      await FirebaseMessaging.instance.deleteToken();

      // 3. Đăng xuất Firebase Auth
      await _auth.signOut();

      // 4. Xóa toàn bộ dữ liệu local
      await prefs.clear();

      print('Đăng xuất thành công + đã dọn sạch FCM token');
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      // Dù có lỗi vẫn cố signOut và clear dữ liệu
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // ================================== CÁC HÀM KHÁC ==================================
  Future<void> capNhatProfile(String userId, String username, String phoneNumber) async {
    await _firestore.collection('users').doc(userId).update({
      'username': username,
      'phoneNumber': phoneNumber,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> doiMatKhau(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<User?> layThongTinNguoiDung(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  fb.User? get currentUser => _auth.currentUser;

  // Helper
  bool _isEmail(String s) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(s);
  bool _isPhoneNumber(String s) => RegExp(r'^\d{9,11}$').hasMatch(s);
}