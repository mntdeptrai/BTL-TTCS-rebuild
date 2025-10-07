import 'package:cloud_firestore/cloud_firestore.dart';
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final String userId;
  final String assignedTo;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.userId,
    required this.assignedTo,
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
    };
  }
}