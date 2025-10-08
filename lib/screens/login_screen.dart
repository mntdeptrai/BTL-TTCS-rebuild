import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'task_list_screen.dart';
import '../utils/error_handler.dart';

class ManHinhDangNhap extends StatefulWidget {
  @override
  _ManHinhDangNhapState createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _authService = AuthService();
  final _identifierController = TextEditingController(); // Dùng cho đăng nhập
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // Trường riêng cho username
  final _emailController = TextEditingController();   // Trường riêng cho email
  final _phoneController = TextEditingController();   // Trường riêng cho phone
  final _confirmPasswordController = TextEditingController(); // Trường xác nhận mật khẩu
  bool _isLogin = true;
  bool _isLoading = false;

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _identifierController.clear();
      _passwordController.clear();
      _usernameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_isLogin) {
        final user = await _authService.dangNhap(_identifierController.text, _passwordController.text);
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManHinhDanhSachNhiemVu()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại')),
          );
        }
      } else {
        // Kiểm tra mật khẩu và xác nhận mật khẩu
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mật khẩu và xác nhận mật khẩu không khớp')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final user = await _authService.dangKy(
          _usernameController.text,
          _emailController.text, // Sử dụng email từ trường riêng
          _passwordController.text,
          'Employee', // Mặc định role là Employee
          _phoneController.text,
        );
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManHinhDanhSachNhiemVu()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thất bại')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isLogin) ...[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Tên đăng nhập'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              TextField(
                controller: _identifierController,
                decoration: InputDecoration(labelText: 'Tên đăng nhập/Email/SĐT'),
                keyboardType: TextInputType.text,
              ),
            ],
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            if (!_isLogin)
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
                obscureText: true,
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký'),
            ),
            TextButton(
              onPressed: _switchMode,
              child: Text(_isLogin ? 'Chuyển sang Đăng Ký' : 'Chuyển sang Đăng Nhập'),
            ),
          ],
        ),
      ),
    );
  }
}