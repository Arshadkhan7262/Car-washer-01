class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}










