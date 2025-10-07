import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Task>> layNhiemVu() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final role = prefs.getString('role') ?? '';
    QuerySnapshot query;
    if (role == 'Admin' || role == 'Manager') {
      query = await _firestore.collection('tasks').get();
    } else {
      query = await _firestore.collection('tasks').where('userId', isEqualTo: userId).get();
    }
    return query.docs.map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
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
      'userId': userId,
      'assignedTo': assignedTo,
    });
  }

  Future<void> capNhatNhiemVu(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({'isCompleted': isCompleted});
  }

  // Thêm phương thức để lấy danh sách người dùng
  Future<List<String>> layDanhSachNguoiDung() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => doc['username'] as String).toList();
  }
}