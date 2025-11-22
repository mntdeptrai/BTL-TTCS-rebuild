import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart'; // THÊM: Firebase Messaging
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance; // THÊM

  // Đăng nhập với identifier (email, username, hoặc phone)
  Future<User?> dangNhap(String identifier, String password) async {
    try {
      print('Đang cố gắng đăng nhập với identifier: $identifier');

      // Tìm tài khoản dựa trên identifier
      QuerySnapshot userQuery;
      if (isEmail(identifier)) {
        print('Đăng nhập bằng email: $identifier');
        userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: identifier)
            .limit(1)
            .get();
      } else if (isPhoneNumber(identifier)) {
        print('Đăng nhập bằng số điện thoại: $identifier');
        userQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: identifier)
            .limit(1)
            .get();
      } else {
        print('Đăng nhập bằng username: $identifier');
        userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isEmpty) {
        print('Không tìm thấy tài khoản với identifier: $identifier');
        return null;
      }

      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      final userId = userQuery.docs.first.id;
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        print('Email không tồn tại cho tài khoản: $identifier');
        return null;
      }

      // Thử đăng nhập với email và mật khẩu
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user!.uid != userId) {
        print('UID không khớp với tài khoản');
        return null;
      }

      final user = User(
        id: userId,
        username: userData['username'],
        fullName: userData['fullName'],
        employeeId: userData['employeeId'],
        role: userData['role'],
        phoneNumber: userData['phoneNumber'],
      );

      print('Đăng nhập thành công với identifier: $identifier, user: $user');

      // LƯU THÔNG TIN VÀO SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', user.role ?? 'Employee');
      await prefs.setString('userId', user.id);
      await prefs.setString('username', user.username);

      // THÊM: Lưu FCM Token vào Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        print('Đã lưu FCM Token cho user $userId: $token');
      }

      return user;
    } catch (e) {
      print('Lỗi đăng nhập chi tiết: $e');
      return null;
    }
  }

  // Đăng ký với username, email, fullName, password, role, và phone
  Future<User?> dangKy(String username, String email, String fullName, String password, String role, String phoneNumber) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Tạo ID nhân viên ngẫu nhiên (1000 - 9999)
      final random = Random();
      final employeeId = (1000 + random.nextInt(9000)).toString();

      final user = User(
        id: userCredential.user!.uid,
        username: username,
        fullName: fullName,
        employeeId: employeeId,
        role: role,
        phoneNumber: phoneNumber,
      );

      // Lưu thông tin người dùng vào Firestore
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'username': user.username,
        'fullName': user.fullName,
        'employeeId': user.employeeId,
        'role': user.role,
        'phoneNumber': user.phoneNumber,
        'email': email,
      });

      // LƯU THÔNG TIN VÀO SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', user.role);
      await prefs.setString('userId', user.id);
      await prefs.setString('username', user.username);

      // THÊM: Lưu FCM Token vào Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.id).update({
          'fcmToken': token,
        });
        print('Đã lưu FCM Token cho user mới ${user.id}: $token');
      }

      return user;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return null;
    }
  }

  // Cập nhật profile
  Future<void> capNhatProfile(String userId, String username, String phoneNumber) async {
    await _firestore.collection('users').doc(userId).update({
      'username': username,
      'phoneNumber': phoneNumber,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('username', username);
  }

  // Đổi mật khẩu
  Future<void> doiMatKhau(String email, String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // Lấy thông tin người dùng
  Future<User?> layThongTinNguoiDung(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return User(
          id: userDoc.id,
          username: userDoc['username'],
          fullName: userDoc['fullName'],
          employeeId: userDoc['employeeId'],
          role: userDoc['role'],
          phoneNumber: userDoc['phoneNumber'],
        );
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      return null;
    }
  }

  // Lấy người dùng hiện tại
  fb.User? layNguoiDungHienTai() {
    return _auth.currentUser;
  }

  // Kiểm tra xem chuỗi có phải là email
  bool isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  // Kiểm tra xem chuỗi có phải là số điện thoại (giản lược)
  bool isPhoneNumber(String input) {
    final phoneRegex = RegExp(r'^\d{9,10}$');
    return phoneRegex.hasMatch(input);
  }

  // Đăng xuất
  Future<void> dangXuat() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('username');
  }
}