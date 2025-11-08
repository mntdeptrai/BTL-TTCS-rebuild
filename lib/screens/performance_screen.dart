import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';

class PerformanceScreen extends StatefulWidget {
  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  List<Map<String, String>> _allUsers = [];
  List<Map<String, String>> _displayUsers = []; // Danh sách hiển thị theo quyền
  bool _isLoading = true;
  Map<String, Map<String, int>> _userStats = {};
  String _timeFilter = 'all'; // all, week, month
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _currentUsername;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserRoleAndData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('username');
    _currentRole = prefs.getString('role') ?? 'Employee';

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();
      final users = await apiService.layDanhSachNguoiDung();

      setState(() {
        _tasks = tasks;
        _allUsers = users;
        _isLoading = false;
      });

      // Lọc danh sách hiển thị theo quyền
      if (_currentRole == 'Employee') {
        _displayUsers = users.where((u) => u['username'] == _currentUsername).toList();
      } else {
        _displayUsers = users; // Admin & Manager thấy tất cả
      }

      _calculateUserStats();
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _calculateUserStats() {
    final Map<String, Map<String, int>> stats = {};
    final now = DateTime.now();
    DateTime? startDate, endDate;

    if (_timeFilter == 'week') {
      final weekday = now.weekday;
      startDate = now.subtract(Duration(days: weekday - 1));
      endDate = startDate.add(Duration(days: 6));
    } else if (_timeFilter == 'month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }

    // Khởi tạo stats cho các user được phép xem
    for (var user in _displayUsers) {
      final username = user['username']!;
      stats[username] = {'completed': 0, 'pending': 0, 'total': 0};
    }

    for (var task in _tasks) {
      final taskDate = task.dueDate;
      final isInRange = _timeFilter == 'all' ||
          (startDate != null && endDate != null && taskDate.isAfter(startDate) && taskDate.isBefore(endDate.add(Duration(days: 1))));

      if (isInRange && _displayUsers.any((u) => u['username'] == task.assignedTo)) {
        final user = task.assignedTo;
        if (stats.containsKey(user)) {
          stats[user]!['total'] = (stats[user]!['total'] ?? 0) + 1;
          if (task.isCompleted) {
            stats[user]!['completed'] = (stats[user]!['completed'] ?? 0) + 1;
          } else {
            stats[user]!['pending'] = (stats[user]!['pending'] ?? 0) + 1;
          }
        }
      }
    }

    setState(() {
      _userStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống Kê Hiệu Suất'),
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
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _timeFilter,
              underline: SizedBox(),
              icon: Icon(Icons.filter_list, color: Colors.white),
              items: [
                DropdownMenuItem(value: 'all', child: Text('Tất cả', style: TextStyle(color: Colors.black87))),
                DropdownMenuItem(value: 'week', child: Text('Tuần này', style: TextStyle(color: Colors.black87))),
                DropdownMenuItem(value: 'month', child: Text('Tháng này', style: TextStyle(color: Colors.black87))),
              ],
              onChanged: (value) {
                setState(() {
                  _timeFilter = value!;
                  _calculateUserStats();
                  _animationController.reset();
                  _animationController.forward();
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _displayUsers.isEmpty
          ? Center(child: Text('Không có dữ liệu thống kê'))
          : _userStats.isEmpty
          ? Center(child: Text('Chưa có nhiệm vụ nào trong khoảng thời gian này'))
          : ListView.builder(
        itemCount: _displayUsers.length,
        itemBuilder: (context, index) {
          final userMap = _displayUsers[index];
          final username = userMap['username']!;
          final fullName = userMap['fullName'] ?? username;
          final stats = _userStats[username] ?? {'completed': 0, 'pending': 0, 'total': 0};

          final completed = stats['completed']!;
          final pending = stats['pending']!;
          final total = stats['total']!;
          final rate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

          return Card(
            elevation: 5,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(fullName[0], style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(
                fullName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              subtitle: Text(
                'Tổng: $total | Hoàn thành: $completed | Chưa: $pending | Tỷ lệ: $rate%',
                style: TextStyle(fontSize: 14),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      height: 220,
                      child: SfCircularChart(
                        title: ChartTitle(
                          text: 'Hiệu suất của $fullName ($_timeFilter)',
                          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        legend: Legend(isVisible: true, position: LegendPosition.bottom),
                        series: <CircularSeries>[
                          PieSeries<ChartData, String>(
                            dataSource: [
                              ChartData('Hoàn thành', completed, Colors.green.shade500),
                              ChartData('Chưa hoàn thành', pending, Colors.red.shade400),
                            ],
                            xValueMapper: (data, _) => data.category,
                            yValueMapper: (data, _) => data.value,
                            pointColorMapper: (data, _) => data.color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            enableTooltip: true,
                            explode: true,
                            explodeIndex: completed > pending ? 0 : 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChartData {
  final String category;
  final int value;
  final Color color;
  ChartData(this.category, this.value, this.color);
}