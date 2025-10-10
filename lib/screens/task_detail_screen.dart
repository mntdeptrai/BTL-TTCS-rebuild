import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> _reports = [];
  late Task _currentTask; // Sử dụng biến tạm để theo dõi trạng thái hiện tại

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task; // Gán giá trị ban đầu
    _loadReports();
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
        _reports = snapshot.docs.map((doc) => doc['report'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải báo cáo: $e')));
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
        _loadReports(); // Tải lại báo cáo
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thêm báo cáo: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập báo cáo')));
    }
  }

  Future<void> _updateTaskStatus(bool isCompleted) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestore.collection('tasks').doc(_currentTask.id).update({
        'isCompleted': isCompleted,
      });
      // Làm mới dữ liệu từ Firestore
      final updatedDoc = await _firestore.collection('tasks').doc(_currentTask.id).get();
      if (updatedDoc.exists) {
        setState(() {
          _currentTask = Task.fromJson(updatedDoc.data()!, _currentTask.id); // Cập nhật với dữ liệu mới
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi Tiết Nhiệm Vụ')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiêu đề: ${_currentTask.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Mô tả: ${_currentTask.description ?? 'Không có mô tả'}'),
            SizedBox(height: 10),
            Text('Đến hạn: ${DateFormatter.formatDate(_currentTask.dueDate)}'),
            SizedBox(height: 10),
            Text('Trạng thái: ${_currentTask.isCompleted ? 'Hoàn thành' : 'Chưa hoàn thành'}'),
            SizedBox(height: 10),
            Text('Giao cho: ${_currentTask.assignedTo} (ID: ${_currentTask.employeeId ?? 'N/A'})'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentTask.isCompleted
                      ? null
                      : () => _updateTaskStatus(true),
                  child: Text('Đã hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentTask.isCompleted ? Colors.grey : Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: _currentTask.isCompleted
                      ? () => _updateTaskStatus(false)
                      : null,
                  child: Text('Chưa hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_currentTask.isCompleted ? Colors.grey : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Báo cáo công việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                  ? Center(child: Text('Chưa có báo cáo'))
                  : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_reports[index]),
                  );
                },
              ),
            ),
            TextField(
              controller: _reportController,
              decoration: InputDecoration(labelText: 'Nhập báo cáo'),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addReport,
              child: Text('Thêm báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}