// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String fullName;
  final String employeeId;
  final String? role;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.employeeId,
    this.role,
    this.phoneNumber,
  });

  // THÊM: Chuyển từ Map (dùng khi đọc từ Firestore)
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      username: map['username'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      role: map['role'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  // THÊM: Chuyển thành Map (dùng khi ghi vào Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'employeeId': employeeId,
      'role': role,
      'phoneNumber': phoneNumber,
    };
  }

  // Dễ debug
  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, role: $role)';
  }
}