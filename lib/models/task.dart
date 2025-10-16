import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final String userId;
  final String assignedTo;
  String? employeeId; // Thêm tạm để lưu khi lấy từ Firestore
  bool isRead; // Bỏ final để cho phép gán lại
  String? createdBy;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.userId,
    required this.assignedTo,
    this.employeeId,
    this.isRead = false, // Mặc định là chưa đọc
    this.createdBy
  });

  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      employeeId: json['employeeId'] as String?,
      isRead: json['isRead'] ?? false, // Lấy từ Firestore, mặc định là false
      createdBy: json['createdBy']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'userId': userId,
      'assignedTo': assignedTo,
      'isRead': isRead, // Thêm vào JSON để lưu
      'createdBy':createdBy
    };
  }

  // Thêm phương thức copyWith (tùy chọn, giữ lại để tương lai)
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? userId,
    String? assignedTo,
    String? employeeId,
    bool? isRead,
    String? createdBy
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      employeeId: employeeId ?? this.employeeId,
      isRead: isRead ?? this.isRead,
      createdBy: createdBy ?? this.createdBy
    );
  }
}