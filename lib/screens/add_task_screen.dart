import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';

class ManHinhThemNhiemVu extends StatefulWidget {
  @override
  _ManHinhThemNhiemVuState createState() => _ManHinhThemNhiemVuState();
}

class _ManHinhThemNhiemVuState extends State<ManHinhThemNhiemVu> {
  final _apiService = ApiService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  String _selectedAssignee = '';
  List<Map<String, String>> _users = [];
  bool _isLoadingUsers = true;
  String _currentRole = '';

  @override
  void initState() {
    super.initState();
    _loadUsersAndRole();
  }

  Future<void> _loadUsersAndRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentRole = prefs.getString('role') ?? 'Employee';
      final userDetails = await _apiService.layDanhSachNguoiDung();

      // Lọc danh sách người dùng dựa trên vai trò
      final filteredUsers = <Map<String, String>>[];
      for (var user in userDetails) {
        final userRole = await _apiService.layVaiTroCuaNguoiDung(user['username']!);
        if (_currentRole == 'Admin' && userRole != 'Admin') {
          filteredUsers.add(user); // Admin thấy Manager và Employee
        } else if (_currentRole == 'Manager' && userRole == 'Employee') {
          filteredUsers.add(user); // Manager chỉ thấy Employee
        }
      }

      print('Đã tải ${filteredUsers.length} người dùng phù hợp');
      setState(() {
        _users = filteredUsers;
        _isLoadingUsers = false;
        if (_users.isNotEmpty) _selectedAssignee = _users.first['username']!;
      });
    } catch (e) {
      print('Lỗi tải người dùng: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _themNhiemVu() async {
    if (_titleController.text.isNotEmpty && _selectedAssignee.isNotEmpty) {
      try {
        await _apiService.themNhiemVu(
          _titleController.text,
          _descriptionController.text,
          _dueDate,
          _selectedAssignee,
        );
        print('Đã thêm nhiệm vụ cho: $_selectedAssignee');
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tiêu đề và chọn nhân viên')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm Nhiệm Vụ')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Tiêu đề'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
            ListTile(
              title: Text('Ngày đến hạn: ${DateFormatter.formatDate(_dueDate)}'),
              trailing: Icon(Icons.calendar_today, color: Colors.black),
              onTap: _selectDueDate,
            ),
            if (_isLoadingUsers)
              CircularProgressIndicator()
            else
              DropdownButton<String>(
                hint: Text('Chọn nhân viên'),
                value: _selectedAssignee.isNotEmpty ? _selectedAssignee : null,
                items: _users.map((Map<String, String> user) {
                  return DropdownMenuItem<String>(
                    value: user['username'],
                    child: Text('${user['fullName']} (ID: ${user['employeeId']})'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAssignee = newValue ?? '';
                  });
                },
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _themNhiemVu,
              icon: Icon(Icons.add, color: Colors.black),
              label: Text('Thêm Nhiệm Vụ'),
            ),
          ],
        ),
      ),
    );
  }
}