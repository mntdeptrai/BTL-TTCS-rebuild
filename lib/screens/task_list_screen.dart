import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';
import 'performance_screen.dart';
import '../utils/date_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManHinhDanhSachNhiemVu extends StatefulWidget {
  @override
  _ManHinhDanhSachNhiemVuState createState() => _ManHinhDanhSachNhiemVuState();
}

class _ManHinhDanhSachNhiemVuState extends State<ManHinhDanhSachNhiemVu> with TickerProviderStateMixin {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, completed, pending
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  Timer? _debounceTimer;
  String? _currentUsername; // Lưu username hiện tại
  String? _currentRole; // Lưu vai trò hiện tại

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _searchController.addListener(_onSearchChanged);
    _loadUserData(); // Lấy vai trò và username
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('username');
      _currentRole = prefs.getString('role') ?? 'Employee';
    });
    _layDanhSachNhiemVu();
  }

  Future<void> _layDanhSachNhiemVu() async {
    if (_currentRole == null || _currentUsername == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();
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
      // Lọc nhiệm vụ dựa trên vai trò
      List<Task> filteredTasks = [];
      if (_currentRole == 'Manager') {
        filteredTasks = tasks.where((task) =>
        task.assignedTo == _currentUsername || (task.createdBy != null && task.createdBy == _currentUsername)
        ).toList();
      } else if (_currentRole == 'Admin') {
        filteredTasks = tasks; // Admin thấy tất cả
      } else {
        filteredTasks = tasks.where((task) => task.assignedTo == _currentUsername).toList(); // Employee chỉ thấy nhiệm vụ của mình
      }
      setState(() {
        _tasks = filteredTasks;
        _isLoading = false;
      });
      // Tạo animations cho từng task
      _slideAnimations = List.generate(
        _tasks.length,
            (index) => Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        )),
      );
      _animationController.forward(from: 0.0);
      _filterTasks();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải nhiệm vụ: $e')),
      );
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(seconds: 2), () {
      _filterTasks();
      _updateAnimations();
      _animationController.forward(from: 0.0);
    });
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((task) {
        final matchesSearch = task.title.toLowerCase().contains(query) ||
            task.assignedTo.toLowerCase().contains(query);
        if (_filterStatus == 'all') return matchesSearch;
        if (_filterStatus == 'completed') return matchesSearch && task.isCompleted;
        return matchesSearch && !task.isCompleted;
      }).toList();
    });
  }

  void _updateAnimations() {
    _slideAnimations = List.generate(
      _filteredTasks.length,
          (index) => Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
    );
  }

  Future<void> _markAsRead(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isRead': true,
      });
      setState(() {
        final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex].isRead = true;
        }
        _filterTasks();
        _updateAnimations();
        _animationController.forward(from: 0.0);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
      );
    }
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
        return Scaffold(
          appBar: AppBar(
            title: Text('Danh Sách Nhiệm Vụ'),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              if (role == 'Admin' || role == 'Manager')
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManHinhThemNhiemVu()),
                    ).then((_) => _layDanhSachNhiemVu());
                  },
                  tooltip: 'Thêm nhiệm vụ',
                ),
              IconButton(
                icon: Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                tooltip: 'Hồ sơ',
              ),
              IconButton(
                icon: Icon(Icons.bar_chart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PerformanceScreen()),
                  );
                },
                tooltip: 'Thống kê',
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: _dangXuat,
                tooltip: 'Đăng xuất',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm nhiệm vụ...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                        DropdownMenuItem(value: 'pending', child: Text('Chưa hoàn thành')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                          _filterTasks();
                          _updateAnimations();
                          _animationController.forward(from: 0.0);
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredTasks.isEmpty
                    ? Center(child: Text('Chưa có nhiệm vụ nào được giao'))
                    : ListView.builder(
                  itemCount: _filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = _filteredTasks[index];
                    return SlideTransition(
                      position: _slideAnimations[index],
                      child: Dismissible(
                        key: Key(task.id),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                            ),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: role == 'Admin'
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        onDismissed: (direction) async {
                          await _firestore
                              .collection('tasks')
                              .doc(task.id)
                              .delete();
                          setState(() {
                            _tasks.remove(task);
                            _filterTasks();
                            _updateAnimations();
                            _animationController.forward(from: 0.0);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã xóa nhiệm vụ')),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: task.isCompleted
                              ? Colors.green.shade50
                              : task.isRead
                              ? Colors.red.shade50
                              : Colors.white,
                          child: ListTile(
                            leading: Icon(
                              task.isCompleted ? Icons.check_circle : Icons.pending,
                              color: task.isCompleted ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: task.isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.description != null)
                                  Text(
                                    task.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text('Đến hạn: ${DateFormatter.formatDate(task.dueDate)}'),
                                Text('Giao cho: ${task.assignedTo} (ID: ${task.employeeId ?? 'N/A'})'),
                              ],
                            ),
                            onTap: () {
                              _markAsRead(task.id);
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      TaskDetailScreen(task: task),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              ).then((_) => _layDanhSachNhiemVu());
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final Function(String) markAsRead;

  TaskSearchDelegate(this.tasks, this.markAsRead);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = tasks.where((task) =>
    task.title.toLowerCase().contains(query.toLowerCase()) ||
        task.assignedTo.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text('Giao cho: ${task.assignedTo}'),
          onTap: () {
            markAsRead(task.id);
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = tasks.where((task) =>
    task.title.toLowerCase().contains(query.toLowerCase()) ||
        task.assignedTo.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final task = suggestions[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text('Giao cho: ${task.assignedTo}'),
          onTap: () {
            markAsRead(task.id);
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
            );
          },
        );
      },
    );
  }
}