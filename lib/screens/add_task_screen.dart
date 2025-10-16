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
  final _formKey = GlobalKey<FormState>();
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
      final filteredUsers = <Map<String, String>>[];
      for (var user in userDetails) {
        final userRole = await _apiService.layVaiTroCuaNguoiDung(user['username']!);
        if (_currentRole == 'Admin' && userRole != 'Admin') {
          filteredUsers.add(user);
        } else if (_currentRole == 'Manager' && userRole == 'Employee') {
          filteredUsers.add(user);
        }
      }
      setState(() {
        _users = filteredUsers;
        _isLoadingUsers = false;
        if (_users.isNotEmpty) _selectedAssignee = _users.first['username']!;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải người dùng: $e')),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _themNhiemVu() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.themNhiemVu(
          _titleController.text,
          _descriptionController.text,
          _dueDate,
          _selectedAssignee,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm nhiệm vụ thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm nhiệm vụ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm Nhiệm Vụ'),
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Ngày đến hạn: ${DateFormatter.formatDate(_dueDate)}',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Icon(Icons.calendar_today, color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _selectDueDate,
              ),
              SizedBox(height: 16),
              _isLoadingUsers
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Chọn nhân viên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedAssignee.isNotEmpty ? _selectedAssignee : null,
                items: _users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['username'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(user['fullName']![0]),
                          backgroundColor: Colors.blue.shade200,
                        ),
                        SizedBox(width: 8),
                        Text('${user['fullName']} (ID: ${user['employeeId']})'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignee = value ?? '';
                  });
                },
                validator: (value) =>
                value == null ? 'Vui lòng chọn nhân viên' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _themNhiemVu,
                icon: Icon(Icons.add),
                label: Text('Thêm Nhiệm Vụ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}