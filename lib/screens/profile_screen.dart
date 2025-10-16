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
        if (user != null) {
          setState(() {
            _username = user.username;
            _fullName = user.fullName ?? '';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userId != null && _phoneController.text.isNotEmpty) {
      try {
        await _authService.capNhatProfile(
            _userId!, _username!, _phoneController.text);
        setState(() {
          _phoneNumber = _phoneController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật profile thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
    }
  }

  Future<void> _changePassword() async {
    final currentUser = _authService.layNguoiDungHienTai();
    if (currentUser != null) {
      final oldPasswordController = TextEditingController();
      final newPasswordController = TextEditingController();
      final confirmPasswordController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (newPasswordController.text == confirmPasswordController.text) {
                  try {
                    await _authService.doiMatKhau(
                        currentUser.email!, newPasswordController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đổi mật khẩu thành công')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mật khẩu mới không khớp')),
                  );
                }
              },
              child: Text('Xác nhận'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy người dùng hiện tại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ Sơ'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade200,
                      child: Text(
                        _fullName != null && _fullName!.isNotEmpty
                            ? _fullName![0]
                            : '?',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _fullName ?? 'Không có tên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tên đăng nhập: $_username',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vai trò: $_currentRole',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: Icon(Icons.save),
              label: Text('Cập nhật Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _changePassword,
              icon: Icon(Icons.lock),
              label: Text('Đổi mật khẩu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}