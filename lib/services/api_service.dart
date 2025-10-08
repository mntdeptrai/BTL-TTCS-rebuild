import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Task>> layNhiemVu() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final username = prefs.getString('username') ?? ''; // Lấy username
    final role = prefs.getString('role') ?? '';
    Query query;
    if (role == 'Admin' || role == 'Manager') {
      query = _firestore.collection('tasks'); // Admin/Manager thấy tất cả
    } else {
      // Employee thấy task được giao cho họ (assignedTo == username)
      query = _firestore.collection('tasks').where('assignedTo', isEqualTo: username);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> themNhiemVu(String title, String description, DateTime dueDate, String assignedTo) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('tasks').doc(taskId).set({
      'id': taskId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': false,
      'userId': userId, // Người tạo
      'assignedTo': assignedTo, // Người được giao
    });
  }

  Future<void> capNhatNhiemVu(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({'isCompleted': isCompleted});
  }

  // Lấy danh sách người dùng
  Future<List<String>> layDanhSachNguoiDung() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => doc['username'] as String).toList();
  }
}