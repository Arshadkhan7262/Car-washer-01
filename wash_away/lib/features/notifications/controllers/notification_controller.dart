import 'dart:developer';
import 'package:get/get.dart';
import '../models/notification_model.dart';

/// Notification Controller
/// Manages list of notifications received in the app
class NotificationController extends GetxController {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Listeners are handled by NotificationHandlerService to avoid duplicates
    // This controller only manages the list of notifications
  }

  /// Add a new notification
  void addNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      data: data,
      isRead: false,
    );

    // Add to the beginning of the list
    notifications.insert(0, notification);
    _updateUnreadCount();
    
    log('✅ [NotificationController] Notification added: $title');
  }

  /// Mark notification as read
  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    _updateUnreadCount();
  }

  /// Delete a notification
  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();
  }

  /// Clear all notifications
  void clearAll() {
    notifications.clear();
    _updateUnreadCount();
  }

  /// Update unread count
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
}

