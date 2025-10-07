import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_handler.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    if (_userId != null) {
      try {
        final userDoc = await _authService._firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          setState(() {
            _usernameController.text = userDoc['username'] ?? '';
            _phoneController.text = userDoc['phoneNumber'] ?? '';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userId != null) {
      try {
        await _authService.capNhatProfile(_userId!, _usernameController.text, _phoneController.text);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật profile thành công')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
      }
    }
  }

  Future<void> _changePassword() async {
    final currentUser = _authService._auth.currentUser;
    if (currentUser != null) {
      final newPasswordController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Đổi mật khẩu'),
          content: TextField(
            controller: newPasswordController,
            decoration: InputDecoration(labelText: 'Mật khẩu mới'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _authService.doiMatKhau(currentUser.email!, newPasswordController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đổi mật khẩu thành công')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
                }
              },
              child: Text('Xác nhận'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.person, size: 50), // Thay CircleAvatar bằng Icon
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Số điện thoại'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Cập nhật Profile'),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}