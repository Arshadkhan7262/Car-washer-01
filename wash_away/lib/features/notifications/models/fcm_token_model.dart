/// FCM Token Model
class FcmTokenModel {
  final String? id;
  final String token;
  final String? userId;
  final String? deviceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FcmTokenModel({
    this.id,
    required this.token,
    this.userId,
    this.deviceType,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenModel(
      id: json['id']?.toString(),
      token: json['token'] ?? '',
      userId: json['user_id']?.toString(),
      deviceType: json['device_type'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (deviceType != null) 'device_type': deviceType,
    };
  }
}

