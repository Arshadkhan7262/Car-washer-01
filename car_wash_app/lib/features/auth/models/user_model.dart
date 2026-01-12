/// User Model
/// Represents washer user data from backend API
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool phoneVerified;
  final bool emailVerified;
  final String? status; // For washers: 'pending', 'active', 'suspended'
  final bool? onlineStatus; // For washers: online/offline status

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.phoneVerified,
    required this.emailVerified,
    this.status,
    this.onlineStatus,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'washer',
      phoneVerified: json['phone_verified'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      status: json['status']?.toString(),
      onlineStatus: json['online_status'] as bool?,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'phone_verified': phoneVerified,
      'email_verified': emailVerified,
      'status': status,
      'online_status': onlineStatus,
    };
  }
}

