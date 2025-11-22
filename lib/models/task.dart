import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  bool isCompleted; // Có thể thay đổi
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

  // Kiểm tra nhiệm vụ có quá hạn không
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isCompleted;

  // Có thể thay đổi trạng thái không (chỉ khi chưa quá hạn)
  bool get canChangeStatus => !isOverdue;

  // Từ Firestore JSON
  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      isCompleted: json['isCompleted'] ?? false,
      assignedTo: json['assignedTo'] ?? '',
      createdBy: json['createdBy'],
      employeeId: json['employeeId'] as String?,
      isRead: json['isRead'] ?? false,
    );
  }

  // Sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'employeeId': employeeId,
      'isRead': isRead,
    };
  }

  // Copy với thay đổi
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