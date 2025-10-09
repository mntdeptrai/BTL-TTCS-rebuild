import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/task.dart';
import 'add_task_screen.dart'; // Đảm bảo import file này
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _layDanhSachNhiemVu();
  }

  Future<void> _layDanhSachNhiemVu() async {
    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();
      // Lấy employeeId cho mỗi task
      for (var task in tasks) {
        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: task.assignedTo)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          task.employeeId = userDoc.docs.first.data()['employeeId']?.toString() ?? 'N/A';
        }
      }
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
      print('Đã tải ${tasks.length} công việc');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Lỗi tải công việc: $e');
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
            title: Text('Danh Sách Công Việc'),
            actions: [
              if (role == 'Admin' || role == 'Manager')
                IconButton(
                  icon: Icon(Icons.add, color: Colors.black),
                  tooltip: 'Thêm công việc',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManHinhThemNhiemVu()), // Sử dụng constructor
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
              ? Center(child: Text('Chưa có công việc nào được giao'))
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
                      Text('Giao cho: ${task.assignedTo} (ID: ${task.employeeId ?? 'N/A'})'),
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