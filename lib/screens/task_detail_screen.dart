import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../utils/date_formatter.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({required this.task, Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    if (!_currentTask.isRead) {
      try {
        await _firestore.collection('tasks').doc(_currentTask.id).update({'isRead': true});
        setState(() => _currentTask.isRead = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')));
        }
      }
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .doc(_currentTask.id)
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _reports = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'report': data['report'] as String,
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải báo cáo: $e')));
      }
    }
  }

  Future<void> _addReport() async {
    final text = _reportController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập báo cáo')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('tasks')
          .doc(_currentTask.id)
          .collection('reports')
          .add({
        'report': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _reportController.clear();
      _loadReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thêm báo cáo: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(bool isCompleted) async {
    if (_currentTask.isOverdue || !_currentTask.canChangeStatus) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể thay đổi trạng thái!')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Cập nhật trạng thái nhiệm vụ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('OK')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('tasks').doc(_currentTask.id).update({'isCompleted': isCompleted});
      final doc = await _firestore.collection('tasks').doc(_currentTask.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentTask = Task.fromJson(doc.data()!, _currentTask.id);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thành công!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _currentTask.isOverdue && !_currentTask.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Nhiệm Vụ'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentTask.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 8),
                    Text('Mô tả: ${_currentTask.description ?? 'Không có'}', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Hạn: ${DateFormatter.formatDate(_currentTask.dueDate)}', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_currentTask.isCompleted ? Icons.check_circle : Icons.pending, color: _currentTask.isCompleted ? Colors.green : Colors.red),
                        SizedBox(width: 8),
                        Text('Trạng thái: ${_currentTask.isCompleted ? 'Hoàn thành' : 'Chưa hoàn thành'}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Giao cho: ${_currentTask.assignedTo} (ID: ${_currentTask.employeeId ?? 'N/A'})', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            if (isOverdue)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade400)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      SizedBox(width: 8),
                      Expanded(child: Text('Nhiệm vụ đã quá hạn!', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (_currentTask.isCompleted || !_currentTask.canChangeStatus) ? null : () => _updateTaskStatus(true),
                  icon: Icon(Icons.check),
                  label: Text('Hoàn thành'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                ElevatedButton.icon(
                  onPressed: (!_currentTask.isCompleted || !_currentTask.canChangeStatus) ? null : () => _updateTaskStatus(false),
                  icon: Icon(Icons.cancel),
                  label: Text('Chưa hoàn thành'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),

            SizedBox(height: 16),
            Text('Báo cáo công việc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                  ? Center(child: Text('Chưa có báo cáo', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(report['report']),
                      subtitle: Text(DateFormatter.formatDateTime(report['timestamp']), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16),
            TextField(
              controller: _reportController,
              decoration: InputDecoration(
                labelText: 'Nhập báo cáo mới',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _isLoading ? Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),

            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addReport,
                icon: Icon(Icons.send),
                label: Text('Gửi báo cáo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}