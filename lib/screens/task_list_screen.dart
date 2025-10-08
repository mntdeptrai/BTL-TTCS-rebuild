import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../utils/date_formatter.dart';

class ManHinhDanhSachNhiemVu extends StatefulWidget {
  @override
  _ManHinhDanhSachNhiemVuState createState() => _ManHinhDanhSachNhiemVuState();
}

class _ManHinhDanhSachNhiemVuState extends State<ManHinhDanhSachNhiemVu> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _layDanhSachNhiemVu();
  }

  Future<void> _layDanhSachNhiemVu() async {
    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
      print('Đã tải ${tasks.length} nhiệm vụ');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Lỗi tải nhiệm vụ: $e');
    }
  }

  Future<void> _chuyenTrangThaiNhiemVu(String taskId, bool isCompleted) async {
    final apiService = ApiService();
    await apiService.capNhatNhiemVu(taskId, !isCompleted);
    _layDanhSachNhiemVu();
  }

  Future<void> _dangXuat() async {
    await _authService.dangXuat();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ManHinhDangNhap()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data!.getString('role') ?? 'Employee';
        print('Vai trò hiện tại: $role');
        return Scaffold(
          appBar: AppBar(
            title: Text('Danh Sách Nhiệm Vụ'),
            actions: [
              if (role == 'Admin' || role == 'Manager')
                IconButton(
                  icon: Icon(Icons.add, color: Colors.black),
                  tooltip: 'Thêm nhiệm vụ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManHinhThemNhiemVu()),
                    ).then((_) => _layDanhSachNhiemVu());
                  },
                ),
              IconButton(
                icon: Icon(Icons.person, color: Colors.black),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.black),
                tooltip: 'Đăng xuất',
                onPressed: _dangXuat,
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? Center(child: Text('Chưa có nhiệm vụ nào được giao'))
              : ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null) Text(task.description!),
                      Text('Đến hạn: ${DateFormatter.formatDate(task.dueDate)}'),
                      Text('Giao cho: ${task.assignedTo}'),
                    ],
                  ),
                  trailing: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) =>
                        _chuyenTrangThaiNhiemVu(task.id, task.isCompleted),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}