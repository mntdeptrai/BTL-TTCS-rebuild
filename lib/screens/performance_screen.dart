import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
  List<Map<String, String>> _allUsers = []; // Danh sách tất cả nhân viên
  bool _isLoading = true;
  Map<String, Map<String, int>> _userStats = {};
  String _timeFilter = 'all'; // all, week, month
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      final tasks = await apiService.layNhiemVu();
      final users = await apiService.layDanhSachNguoiDung();
      setState(() {
        _tasks = tasks;
        _allUsers = users;
        _isLoading = false;
      });
      _calculateUserStats();
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  void _calculateUserStats() {
    final Map<String, Map<String, int>> stats = {};
    final now = DateTime.now();
    DateTime? startDate, endDate;

    // Tính start/end cho week và month
    if (_timeFilter == 'week') {
      final weekday = now.weekday;
      startDate = now.subtract(Duration(days: weekday - 1)); // Thứ Hai
      endDate = startDate.add(Duration(days: 6)); // Chủ Nhật
    } else if (_timeFilter == 'month') {
      startDate = DateTime(now.year, now.month, 1); // Ngày 1 tháng
      endDate = DateTime(now.year, now.month + 1, 0); // Ngày cuối tháng
    }

    // Khởi tạo stats cho tất cả nhân viên
    for (var user in _allUsers) {
      final username = user['username']!;
      stats[username] = {'completed': 0, 'pending': 0, 'total': 0};
    }

    // Tính thống kê cho các nhiệm vụ trong khoảng thời gian
    for (var task in _tasks) {
      final taskDate = task.dueDate;
      bool include = _timeFilter == 'all' ||
          (taskDate.isAfter(startDate!) && taskDate.isBefore(endDate!.add(Duration(days: 1))));
      if (include) {
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

    print('Debug - Filter: $_timeFilter, start: $startDate, end: $endDate, stats: $stats');
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
          DropdownButton<String>(
            value: _timeFilter,
            items: [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'week', child: Text('Tuần này')),
              DropdownMenuItem(value: 'month', child: Text('Tháng này')),
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
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userStats.isEmpty
          ? Center(child: Text('Chưa có dữ liệu thống kê'))
          : ListView.builder(
        itemCount: _allUsers.length, // Hiển thị tất cả nhân viên
        itemBuilder: (context, index) {
          final userMap = _allUsers[index];
          final username = userMap['username']!;
          final fullName = userMap['fullName'] ?? username; // Sử dụng fullName, fallback là username
          final stats = _userStats[username] ?? {'completed': 0, 'pending': 0, 'total': 0};
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Nhân viên: $fullName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              subtitle: Text(
                'Tổng: ${stats['total']} | Hoàn thành: ${stats['completed']} | Chưa hoàn thành: ${stats['pending']} ($_timeFilter)',
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          height: 200,
                          child: SfCircularChart(
                            title: ChartTitle(
                              text: 'Tỷ lệ hoàn thành của $fullName ($_timeFilter)',
                              textStyle: TextStyle(fontSize: 16),
                            ),
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                            series: <CircularSeries>[
                              PieSeries<ChartData, String>(
                                dataSource: [
                                  ChartData(
                                    'Đã hoàn thành',
                                    stats['completed']!,
                                    Colors.green.shade400,
                                  ),
                                  ChartData(
                                    'Chưa hoàn thành',
                                    stats['pending']!,
                                    Colors.red.shade400,
                                  ),
                                ],
                                xValueMapper: (ChartData data, _) => data.category,
                                yValueMapper: (ChartData data, _) => data.value,
                                pointColorMapper: (ChartData data, _) => data.color,
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                  textStyle: TextStyle(fontSize: 12),
                                ),
                                enableTooltip: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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