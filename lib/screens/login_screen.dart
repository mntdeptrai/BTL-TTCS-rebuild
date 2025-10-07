import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'task_list_screen.dart';

class ManHinhDangNhap extends StatefulWidget {
  @override
  _ManHinhDangNhapState createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _authService = AuthService();
  String _errorMessage = '';
  bool _isLogin = true;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      _errorMessage = '';
    });
    try {
      if (_isLogin) {
        final user = await _authService.dangNhap(
          _identifierController.text,
          _passwordController.text,
        );
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManHinhDanhSachNhiemVu()),
          );
        } else {
          setState(() {
            _errorMessage = 'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra lại.';
          });
        }
      } else {
        final user = await _authService.dangKy(
          _identifierController.text,
          _passwordController.text,
          'Employee',
          _identifierController.text,
        );
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManHinhDanhSachNhiemVu()),
          );
        } else {
          setState(() {
            _errorMessage = 'Đăng ký thất bại. Vui lòng kiểm tra lại.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập, Email, hoặc Số điện thoại',
                hintText: 'Nhập username, email, hoặc số điện thoại (9-10 số)',
              ),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = '';
                });
              },
              child: Text(_isLogin
                  ? 'Chưa có tài khoản? Đăng ký'
                  : 'Đã có tài khoản? Đăng nhập'),
            ),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}