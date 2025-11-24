// lib/screens/add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ManHinhThemNhiemVu extends StatefulWidget {
  const ManHinhThemNhiemVu({Key? key}) : super(key: key);

  @override
  _ManHinhThemNhiemVuState createState() => _ManHinhThemNhiemVuState();
}

class _ManHinhThemNhiemVuState extends State<ManHinhThemNhiemVu> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Deadline có giờ phút (mặc định +1 ngày)
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

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
        if (_users.isNotEmpty && _selectedAssignee.isEmpty) {
          _selectedAssignee = _users.first['username']!;
        }
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải người dùng: $e')),
      );
    }
  }

  // CHỌN NGÀY + GIỜ + PHÚT – GIỮ NGUYÊN GIAO DIỆN CŨ
  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );

    if (pickedTime != null) {
      setState(() {
        _dueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _themNhiemVu() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.themNhiemVu(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _dueDate, // ĐÃ CÓ GIỜ PHÚT
          _selectedAssignee,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm nhiệm vụ thành công')),
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
        title: const Text('Thêm Nhiệm Vụ'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tiêu đề
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // NGÀY + GIỜ – GIỮ NGUYÊN GIAO DIỆN CŨ, CHỈ THÊM GIỜ PHÚT
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(
                  'Ngày đến hạn: ${DateFormat('dd/MM/yyyy – HH:mm').format(_dueDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.keyboard_arrow_down),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 16),

              // Chọn nhân viên
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedAssignee.isNotEmpty ? _selectedAssignee : null,
                decoration: InputDecoration(
                  labelText: 'Chọn nhân viên',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['username'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.shade200,
                          child: Text(
                            user['fullName']?[0] ?? '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                validator: (value) => value == null ? 'Vui lòng chọn nhân viên' : null,
              ),
              const SizedBox(height: 30),

              // Nút thêm
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _themNhiemVu,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm Nhiệm Vụ', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}