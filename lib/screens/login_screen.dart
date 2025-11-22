import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../screens/task_list_screen.dart';

class ManHinhDangNhap extends StatefulWidget {
  @override
  _ManHinhDangNhapState createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _identifierController.clear();
      _passwordController.clear();
      _usernameController.clear();
      _emailController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      _confirmPasswordController.clear();
      _controller.reset();
      _controller.forward();
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          final user = await _authService.dangNhap(_identifierController.text, _passwordController.text);
          if (user != null) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => TaskListScreen(),
                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng nhập thất bại')));
          }
        } else {
          if (_passwordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mật khẩu không khớp')));
            return;
          }
          final user = await _authService.dangKy(
            _usernameController.text,
            _emailController.text,
            _fullNameController.text,
            _passwordController.text,
            'Employee',
            _phoneController.text,
          );
          if (user != null) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => TaskListScreen(),
                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng ký thất bại')));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_login.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white.withValues(alpha: 0.95),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 60, color: Colors.blue.shade900),
                            SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                _isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                                key: ValueKey(_isLogin),
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ),
                            SizedBox(height: 16),
                            // PHẦN FORM ĐÃ ĐƯỢC KHÔI PHỤC
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: _isLogin
                                  ? Column(
                                key: ValueKey('login'),
                                children: [
                                  TextFormField(
                                    controller: _identifierController,
                                    decoration: InputDecoration(
                                      labelText: 'Email/Tên đăng nhập/SĐT',
                                      prefixIcon: Icon(Icons.verified_user),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập thông tin' : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu',
                                      prefixIcon: Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                                  ),
                                ],
                              )
                                  : Column(
                                key: ValueKey('register'),
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Tên đăng nhập',
                                      prefixIcon: Icon(Icons.person),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _fullNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Họ và tên',
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Vui lòng nhập email';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email không hợp lệ';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Số điện thoại',
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu',
                                      prefixIcon: Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Xác nhận mật khẩu',
                                      prefixIcon: Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                                      if (v != _passwordController.text) return 'Mật khẩu không khớp';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            _isLoading
                                ? CircularProgressIndicator()
                                : ScaleTransition(
                              scale: _scaleAnimation,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_isLogin ? Icons.login : Icons.person_add),
                                    SizedBox(width: 8),
                                    Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextButton(
                              onPressed: _switchMode,
                              child: Text(
                                _isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}