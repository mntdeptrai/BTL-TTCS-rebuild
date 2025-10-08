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
            _usernameController.text = user.username ?? '';
            _phoneController.text = user.phoneNumber ?? '';
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
    if (_userId != null) {
      try {
        await _authService.capNhatProfile(_userId!, _usernameController.text, _phoneController.text);
        print('Đã cập nhật profile');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật profile thành công')));
      } catch (e) {
        print('Lỗi cập nhật profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
      }
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
          children: [
            Icon(Icons.person, size: 50),
            Text('Vai trò: $_currentRole', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Số điện thoại'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: Icon(Icons.save, color: Colors.black), // Đổi màu sang đen
              label: Text('Cập nhật Profile'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _changePassword,
              icon: Icon(Icons.lock, color: Colors.black), // Đổi màu sang đen
              label: Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}