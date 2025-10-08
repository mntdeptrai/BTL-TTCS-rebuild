import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Task>> layNhiemVu() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final username = prefs.getString('username') ?? '';
    final role = prefs.getString('role') ?? '';
    Query query;
    if (role == 'Admin' || role == 'Manager') {
      query = _firestore.collection('tasks');
    } else {
      query = _firestore.collection('tasks').where('assignedTo', isEqualTo: username);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Task.fromJson(data, doc.id);
    }).toList();
  }

  Future<void> themNhiemVu(String title, String description, DateTime dueDate, String assignedTo) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final role = prefs.getString('role') ?? '';
    final currentUsername = prefs.getString('username') ?? '';

    // Lấy vai trò của người được giao (assignedTo)
    final assigneeDoc = await _firestore
        .collection('users')
        .where('username', isEqualTo: assignedTo)
        .limit(1)
        .get();
    if (assigneeDoc.docs.isEmpty) {
      print('Không tìm thấy người dùng với username: $assignedTo');
      throw Exception('Người dùng không tồn tại');
    }
    final assigneeRole = assigneeDoc.docs.first.data()['role'] as String?;

    // Kiểm tra quyền giao nhiệm vụ
    if (role == 'Admin') {
      if (assigneeRole == 'Admin') {
        print('Admin không thể giao nhiệm vụ cho Admin khác');
        throw Exception('Không thể giao nhiệm vụ cho Admin');
      }
      // Admin có thể giao cho Manager hoặc Employee
    } else if (role == 'Manager') {
      if (assigneeRole == 'Admin') {
        print('Manager không thể giao nhiệm vụ cho Admin');
        throw Exception('Manager không thể giao nhiệm vụ cho Admin');
      } else if (assigneeRole == 'Manager') {
        print('Manager không thể giao nhiệm vụ cho Manager khác');
        throw Exception('Không thể giao nhiệm vụ cho Manager');
      }
      // Manager chỉ có thể giao cho Employee
    } else {
      print('Chỉ Admin hoặc Manager mới có thể giao nhiệm vụ');
      throw Exception('Bạn không có quyền giao nhiệm vụ');
    }

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
    print('Đã thêm nhiệm vụ cho: $assignedTo bởi $currentUsername');
  }

  Future<void> capNhatNhiemVu(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({'isCompleted': isCompleted});
  }

  // Lấy danh sách người dùng với họ tên và ID
  Future<List<Map<String, String>>> layDanhSachNguoiDung() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'username': data['username']?.toString() ?? '',
        'fullName': data['fullName']?.toString() ?? data['username']?.toString() ?? '',
        'employeeId': data['employeeId']?.toString() ?? 'N/A',
      };
    }).toList();
  }

  // Lấy vai trò của người dùng dựa trên username
  Future<String?> layVaiTroCuaNguoiDung(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['role'] as String?;
    }
    return null;
  }
}