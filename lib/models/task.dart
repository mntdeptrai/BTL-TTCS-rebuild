// lib/models/task.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;           // ← ĐÃ LÀ DateTime → CÓ THỂ CÓ GIỜ PHÚT
  bool isCompleted;
  final String assignedTo;
  final String? createdBy;
  String? employeeId;
  bool isRead;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.assignedTo,
    this.createdBy,
    this.employeeId,
    this.isRead = false,
  });

  // Quá hạn chưa?
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isCompleted;

  // Cho phép đổi trạng thái không?
  bool get canChangeStatus => !isOverdue;

  // Từ Firestore
  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: (json['dueDate'] as Timestamp).toDate(), // ← Chuẩn, hỗ trợ giờ phút
      isCompleted: json['isCompleted'] ?? false,
      assignedTo: json['assignedTo'] ?? '',
      createdBy: json['createdBy'],
      employeeId: json['employeeId'] as String?,
      isRead: json['isRead'] ?? false,
    );
  }

  // Sang Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate), // ← Lưu cả giờ phút vào Firestore
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'employeeId': employeeId,
      'isRead': isRead,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? assignedTo,
    String? createdBy,
    String? employeeId,
    bool? isRead,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      employeeId: employeeId ?? this.employeeId,
      isRead: isRead ?? this.isRead,
    );
  }
}