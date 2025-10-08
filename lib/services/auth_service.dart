import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập với identifier (username, email, hoặc phone)
  Future<User?> dangNhap(String identifier, String password) async {
    try {
      print('Đang cố gắng đăng nhập với identifier: $identifier');
      if (isEmail(identifier)) {
        print('Đăng nhập bằng email: $identifier');
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (!userDoc.exists) {
          print('Tài liệu không tồn tại cho uid: ${userCredential.user!.uid}');
          return null;
        }

        final user = User(
          id: userDoc.id,
          username: userDoc['username'],
          role: userDoc['role'],
          phoneNumber: userDoc['phoneNumber'],
        );
        print('Đăng nhập thành công với email, user: $user');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', user.role ?? 'Employee');
        await prefs.setString('userId', user.id);
        await prefs.setString('username', user.username); // Thêm lưu username
        return user;
      } else {
        print('Đăng nhập bằng username hoặc phone: $identifier');
        final userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();
        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          final email = '${identifier}@btlttcs.com';
          print('Tìm thấy username, email suy ra: $email');
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (userCredential.user!.uid != userQuery.docs.first.id) {
            print('UID không khớp với tài liệu');
            return null;
          }

          final user = User(
            id: userQuery.docs.first.id,
            username: userData['username'],
            role: userData['role'],
            phoneNumber: userData['phoneNumber'],
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('role', user.role ?? 'Employee');
          await prefs.setString('userId', user.id);
          await prefs.setString('username', user.username); // Thêm lưu username
          return user;
        } else {
          final userQueryPhone = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: identifier)
              .limit(1)
              .get();
          if (userQueryPhone.docs.isEmpty) {
            print('Không tìm thấy tài khoản với phone: $identifier');
            return null;
          }

          final userData = userQueryPhone.docs.first.data();
          final email = '${userData['username']}@btlttcs.com';
          print('Tìm thấy phone, email suy ra: $email');
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (userCredential.user!.uid != userQueryPhone.docs.first.id) {
            print('UID không khớp với tài liệu phone');
            return null;
          }

          final user = User(
            id: userQueryPhone.docs.first.id,
            username: userData['username'],
            role: userData['role'],
            phoneNumber: userData['phoneNumber'],
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('role', user.role ?? 'Employee');
          await prefs.setString('userId', user.id);
          await prefs.setString('username', user.username); // Thêm lưu username
          return user;
        }
      }
    } catch (e) {
      print('Lỗi đăng nhập chi tiết: $e');
      return null;
    }
  }

  // Đăng ký với username, password, và phone
  Future<User?> dangKy(String username, String password, String role, String phoneNumber) async {
    try {
      final email = '$username@btlttcs.com';
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = User(
        id: userCredential.user!.uid,
        username: username,
        role: role,
        phoneNumber: phoneNumber,
      );
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'username': user.username,
        'role': user.role,
        'phoneNumber': user.phoneNumber,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', user.role);
      await prefs.setString('userId', user.id);
      await prefs.setString('username', user.username); // Thêm lưu username
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
    await prefs.setString('username', username); // Cập nhật username
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
    await prefs.remove('username'); // Xóa username
  }
}