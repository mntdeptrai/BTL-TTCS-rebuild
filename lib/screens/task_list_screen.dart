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
import 'package:firebase_messaging/firebase_messaging.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with TickerProviderStateMixin {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  late AnimationController _animationController;
  List<Animation<Offset>> _slideAnimations = [];
  Timer? _debounceTimer;
  String? _currentUsername;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _searchController.addListener(_onSearchChanged);
    _loadUserData();

    // FCM: Khi app đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification?.body ?? 'Bạn có nhiệm vụ mới!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue.shade700,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _refreshTasks();
      }
    });

    // FCM: Khi nhấn thông báo (app background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final taskId = message.data['taskId'];
      if (taskId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              task: Task(
                id: taskId,
                title: message.data['type'] == 'due_soon' ? 'Sắp hết hạn!' : 'Nhiệm vụ mới',
                description: '',
                dueDate: DateTime.now(),
                assignedTo: '',
                createdBy: '',
                isCompleted: false,
                isRead: false,
              ),
            ),
          ),
        ).then((_) => _refreshTasks());
      }
    });
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
    await _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    await _layDanhSachNhiemVu();
  }

  Future<void> _layDanhSachNhiemVu() async {
    if (_currentRole == null || _currentUsername == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();

      for (var task in tasks) {
        if (task.isOverdue && !task.isCompleted) {
          await _firestore.collection('tasks').doc(task.id).update({'isCompleted': false});
          task.isCompleted = false;
        }

        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: task.assignedTo)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          task.employeeId = userDoc.docs.first.data()['employeeId']?.toString() ?? 'N/A';
        }
      }

      List<Task> filteredTasks = [];
      if (_currentRole == 'Manager') {
        filteredTasks = tasks.where((t) => t.assignedTo == _currentUsername || t.createdBy == _currentUsername).toList();
      } else if (_currentRole == 'Admin') {
        filteredTasks = tasks;
      } else {
        filteredTasks = tasks.where((t) => t.assignedTo == _currentUsername).toList();
      }

      setState(() {
        _tasks = filteredTasks;
        _isLoading = false;
      });

      _filterTasks();
      _updateAnimations();
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải nhiệm vụ: $e')));
      }
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(seconds: 1), () {
      _filterTasks();
      _updateAnimations();
      _animationController.forward(from: 0.0);
    });
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((task) {
        final matchesSearch = task.title.toLowerCase().contains(query) || task.assignedTo.toLowerCase().contains(query);
        if (_filterStatus == 'all') return matchesSearch;
        if (_filterStatus == 'completed') return matchesSearch && task.isCompleted;
        return matchesSearch && !task.isCompleted;
      }).toList();
    });
  }

  void _updateAnimations() {
    _slideAnimations = List.generate(
      _filteredTasks.length,
          (i) => Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Interval(i * 0.1, 1.0, curve: Curves.easeOut)),
      ),
    );
  }

  Future<void> _markAsRead(String taskId) async {
    if (!mounted) return;
    try {
      await _firestore.collection('tasks').doc(taskId).update({'isRead': true});
      setState(() {
        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) _tasks[taskIndex].isRead = true;
        _filterTasks();
        _updateAnimations();
        _animationController.forward(from: 0.0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')));
      }
    }
  }

  Future<void> _dangXuat() async {
    await _authService.dangXuat();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManHinhDangNhap()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final role = snapshot.data!.getString('role') ?? 'Employee';

        return Scaffold(
          appBar: AppBar(
            title: Text('Danh Sách Nhiệm Vụ'),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
            actions: [
              if (role == 'Admin' || role == 'Manager')
                IconButton(icon: Icon(Icons.add_circle_outline), onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhThemNhiemVu())).then((_) => _refreshTasks());
                }, tooltip: 'Thêm nhiệm vụ'),
              IconButton(icon: Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())), tooltip: 'Hồ sơ'),
              IconButton(icon: Icon(Icons.bar_chart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerformanceScreen())), tooltip: 'Thống kê'),
              IconButton(icon: Icon(Icons.logout), onPressed: _dangXuat, tooltip: 'Đăng xuất'),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(hintText: 'Tìm kiếm...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                      onChanged: (v) {
                        setState(() {
                          _filterStatus = v!;
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
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  color: Colors.blue.shade700,
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredTasks.isEmpty
                      ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: constraints.maxHeight,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_late, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Chưa có nhiệm vụ nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  )
                      : ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      if (index >= _slideAnimations.length || index >= _filteredTasks.length) return SizedBox.shrink();
                      final task = _filteredTasks[index];
                      final animation = _slideAnimations[index];

                      return SlideTransition(
                        position: animation,
                        child: Dismissible(
                          key: Key(task.id),
                          background: Container(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: role == 'Admin' ? DismissDirection.endToStart : DismissDirection.none,
                          onDismissed: (_) async {
                            await _firestore.collection('tasks').doc(task.id).delete();
                            setState(() {
                              _tasks.remove(task);
                              _filterTasks();
                              _updateAnimations();
                              _animationController.forward(from: 0.0);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa nhiệm vụ')));
                          },
                          child: Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: task.isCompleted
                                ? Colors.green.shade50
                                : (task.isOverdue && !task.isCompleted)
                                ? Colors.red.shade50
                                : Colors.white,
                            child: ListTile(
                              leading: Icon(task.isCompleted ? Icons.check_circle : Icons.pending, color: task.isCompleted ? Colors.green : Colors.red),
                              title: Text(task.title, style: TextStyle(fontWeight: task.isRead ? FontWeight.normal : FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null) Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Hạn: ${DateFormatter.formatDate(task.dueDate)}'),
                                  if (task.isOverdue && !task.isCompleted) Text('QUÁ HẠN', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('Giao cho: ${task.assignedTo} (ID: ${task.employeeId ?? 'N/A'})'),
                                ],
                              ),
                              onTap: () {
                                _markAsRead(task.id);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => TaskDetailScreen(task: task),
                                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                                  ),
                                ).then((_) => _refreshTasks());
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}