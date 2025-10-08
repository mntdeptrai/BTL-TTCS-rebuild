import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, String>> _users = []; // Thay đổi thành Map để lưu họ tên và ID
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final userDetails = await _apiService.layDanhSachNguoiDung();
      print('Đã tải ${userDetails.length} người dùng');
      setState(() {
        _users = userDetails;
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
        print('Lỗi thêm nhiệm vụ: $e');
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