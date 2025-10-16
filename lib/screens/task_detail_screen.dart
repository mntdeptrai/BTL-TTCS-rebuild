import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../utils/date_formatter.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _reportController = TextEditingController();
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _reports = [];
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadReports();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!_currentTask.isRead) {
      try {
        await _firestore.collection('tasks').doc(_currentTask.id).update({
          'isRead': true,
        });
        setState(() {
          _currentTask.isRead = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
        );
      }
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .doc(_currentTask.id)
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _reports = snapshot.docs
            .map((doc) => {
          'report': doc['report'] as String,
          'timestamp': (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải báo cáo: $e')),
      );
    }
  }

  Future<void> _addReport() async {
    if (_reportController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _firestore
            .collection('tasks')
            .doc(_currentTask.id)
            .collection('reports')
            .add({
          'report': _reportController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _reportController.clear();
        _loadReports();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm báo cáo: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập báo cáo')),
      );
    }
  }

  Future<void> _updateTaskStatus(bool isCompleted) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc muốn cập nhật trạng thái nhiệm vụ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _firestore.collection('tasks').doc(_currentTask.id).update({
          'isCompleted': isCompleted,
        });
        final updatedDoc =
        await _firestore.collection('tasks').doc(_currentTask.id).get();
        if (updatedDoc.exists) {
          setState(() {
            _currentTask = Task.fromJson(updatedDoc.data()!, _currentTask.id);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Nhiệm Vụ'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTask.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mô tả: ${_currentTask.description ?? 'Không có mô tả'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Đến hạn: ${DateFormatter.formatDate(_currentTask.dueDate)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _currentTask.isCompleted
                              ? Icons.check_circle
                              : Icons.pending,
                          color:
                          _currentTask.isCompleted ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Trạng thái: ${_currentTask.isCompleted ? 'Hoàn thành' : 'Chưa hoàn thành'}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Giao cho: ${_currentTask.assignedTo} (ID: ${_currentTask.employeeId ?? 'N/A'})',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentTask.isCompleted
                      ? null
                      : () => _updateTaskStatus(true),
                  icon: Icon(Icons.check),
                  label: Text('Đã hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentTask.isCompleted
                        ? Colors.grey
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentTask.isCompleted
                      ? () => _updateTaskStatus(false)
                      : null,
                  icon: Icon(Icons.cancel),
                  label: Text('Chưa hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_currentTask.isCompleted
                        ? Colors.grey
                        : Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Báo cáo công việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                  ? Center(child: Text('Chưa có báo cáo'))
                  : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(report['report']),
                      subtitle: Text(
                        DateFormatter.formatDateTime(report['timestamp']),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reportController,
              decoration: InputDecoration(
                labelText: 'Nhập báo cáo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addReport,
              icon: Icon(Icons.send),
              label: Text('Thêm báo cáo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}