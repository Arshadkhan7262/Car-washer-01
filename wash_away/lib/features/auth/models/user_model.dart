/// User Model
/// Represents customer user data from backend API
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool phoneVerified;
  final bool emailVerified;
  final String? status; // For customers: 'active', 'suspended'
  final double? walletBalance; // Customer wallet balance

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.phoneVerified,
    required this.emailVerified,
    this.status,
    this.walletBalance,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      phoneVerified: json['phone_verified'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      status: json['status']?.toString(),
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
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
      'wallet_balance': walletBalance,
    };
  }
}




