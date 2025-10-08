import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  String? _userId;
  String? _username;
  String? _fullName;
  String? _phoneNumber;
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  String _currentRole = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _currentRole = prefs.getString('role') ?? 'Employee';
    if (_userId != null) {
      try {
        final user = await _authService.layThongTinNguoiDung(_userId!);
        print('Đã tải profile: $user');
        if (user != null) {
          setState(() {
            _username = user.username;
            _fullName = user.fullName ?? ''; // Sử dụng fullName từ User model
            _phoneNumber = user.phoneNumber;
            _phoneController.text = _phoneNumber ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Lỗi tải profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userId != null && _phoneController.text.isNotEmpty) {
      try {
        await _authService.capNhatProfile(_userId!, _username!, _phoneController.text);
        setState(() {
          _phoneNumber = _phoneController.text;
        });
        print('Đã cập nhật profile');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật profile thành công')));
      } catch (e) {
        print('Lỗi cập nhật profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập số điện thoại')));
    }
  }

  Future<void> _changePassword() async {
    final currentUser = _authService.layNguoiDungHienTai();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tìm thấy người dùng hiện tại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person, size: 50),
            Text('Vai trò: $_currentRole', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Tên đăng nhập: $_username', style: TextStyle(fontSize: 16)), // Chỉ đọc
            SizedBox(height: 10),
            Text('Họ và tên: $_fullName', style: TextStyle(fontSize: 16)), // Chỉ đọc
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: Icon(Icons.save, color: Colors.black),
              label: Text('Cập nhật Profile'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _changePassword,
              icon: Icon(Icons.lock, color: Colors.black),
              label: Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}