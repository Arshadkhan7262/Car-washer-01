/// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final String? bookingId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    required this.isRead,
    this.type,
    this.bookingId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      isRead: json['is_read'] == true || json['read'] == true,
      type: json['data']?['type']?.toString() ?? json['type']?.toString(),
      bookingId: json['data']?['booking_id']?.toString() ??
          json['data']?['job_id']?.toString() ??
          json['booking_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'message': message,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'booking_id': bookingId,
    };
  }
}
