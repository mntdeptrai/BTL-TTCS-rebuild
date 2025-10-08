class User {
  final String id;
  final String username;
  final String? fullName; // Thêm họ tên
  final String? employeeId; // Thêm ID nhân viên
  final String role;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    this.fullName,
    this.employeeId,
    required this.role,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'],
      employeeId: json['employeeId'],
      role: json['role'] ?? 'Employee',
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'employeeId': employeeId,
      'role': role,
      'phoneNumber': phoneNumber,
    };
  }
}