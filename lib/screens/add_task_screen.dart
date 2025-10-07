import 'package:flutter/material.dart';
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
  List<String> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _apiService.layDanhSachNguoiDung();
    setState(() {
      _users = users;
      if (_users.isNotEmpty) _selectedAssignee = _users.first;
    });
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
      await _apiService.themNhiemVu(
        _titleController.text,
        _descriptionController.text,
        _dueDate,
        _selectedAssignee,
      );
      Navigator.pop(context);
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
              trailing: Icon(Icons.calendar_today),
              onTap: _selectDueDate,
            ),
            DropdownButton<String>(
              hint: Text('Chọn nhân viên'),
              value: _selectedAssignee.isNotEmpty ? _selectedAssignee : null,
              items: _users.map((String user) {
                return DropdownMenuItem<String>(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedAssignee = newValue ?? '';
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _themNhiemVu,
              child: Text('Thêm Nhiệm Vụ'),
            ),
          ],
        ),
      ),
    );
  }
}