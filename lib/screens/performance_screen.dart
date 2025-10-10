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

class _PerformanceScreenState extends State<PerformanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;
  Map<String, Map<String, int>> _userStats = {}; // Thống kê theo từng user: {assignedTo: {completed: x, pending: y, total: z}}

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
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
      setState(() {
        _tasks = tasks;
        _calculateUserStats(tasks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải nhiệm vụ: $e')),
      );
    }
  }

  void _calculateUserStats(List<Task> tasks) {
    final Map<String, Map<String, int>> stats = {};
    for (var task in tasks) {
      final user = task.assignedTo;
      stats.putIfAbsent(user, () => {'completed': 0, 'pending': 0, 'total': 0});
      stats[user]!['total'] = (stats[user]!['total'] ?? 0) + 1;
      if (task.isCompleted) {
        stats[user]!['completed'] = (stats[user]!['completed'] ?? 0) + 1;
      } else {
        stats[user]!['pending'] = (stats[user]!['pending'] ?? 0) + 1;
      }
    }
    setState(() {
      _userStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thống Kê Hiệu Suất Cá Nhân')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userStats.isEmpty
          ? Center(child: Text('Chưa có dữ liệu thống kê'))
          : ListView.builder(
        itemCount: _userStats.length,
        itemBuilder: (context, index) {
          final user = _userStats.keys.elementAt(index);
          final stats = _userStats[user]!;
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhân viên: $user',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Tổng nhiệm vụ: ${stats['total']}'),
                  Text('Đã hoàn thành: ${stats['completed']}'),
                  Text('Chưa hoàn thành: ${stats['pending']}'),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      title: ChartTitle(text: 'Tỷ lệ hoàn thành của $user'),
                      legend: Legend(isVisible: true),
                      series: <CircularSeries>[
                        PieSeries<ChartData, String>(
                          dataSource: [
                            ChartData('Đã hoàn thành', stats['completed']!, Colors.green),
                            ChartData('Chưa hoàn thành', stats['pending']!, Colors.red),
                          ],
                          xValueMapper: (ChartData data, _) => data.category,
                          yValueMapper: (ChartData data, _) => data.value,
                          pointColorMapper: (ChartData data, _) => data.color,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Model cho dữ liệu biểu đồ
class ChartData {
  final String category;
  final int value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}