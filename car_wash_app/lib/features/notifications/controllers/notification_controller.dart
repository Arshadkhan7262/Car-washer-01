import 'dart:developer';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Notification Controller
/// Manages notification state and operations
class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxInt unreadCount = 0.obs;
  final RxBool hasMore = true.obs;

  int _currentPage = 1;
  final int _limit = 50;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
  }

  /// Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        isRefreshing.value = true;
        _currentPage = 1;
        hasMore.value = true;
      } else {
        isLoading.value = true;
      }

      final data = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
      );

      if (data != null) {
        final List<dynamic> notificationsList = data['notifications'] ?? [];
        final List<NotificationModel> newNotifications = notificationsList
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        if (refresh) {
          notifications.value = newNotifications;
        } else {
          notifications.addAll(newNotifications);
        }

        // Check if there are more notifications
        final pagination = data['pagination'];
        if (pagination != null) {
          final int currentPage = pagination['page'] ?? 1;
          final int totalPages = pagination['pages'] ?? 1;
          hasMore.value = currentPage < totalPages;
        } else {
          hasMore.value = newNotifications.length >= _limit;
        }

        // Update unread count
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      log('❌ [NotificationController] Error loading notifications: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Load more notifications
  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;

    _currentPage++;
    await loadNotifications();
  }

  /// Mark notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final success = await _notificationService.markAsRead(notification.id);
      if (success) {
        // Update local state
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            createdAt: notification.createdAt,
            isRead: true,
            type: notification.type,
            bookingId: notification.bookingId,
          );
          unreadCount.value = notifications.where((n) => !n.isRead).length;
        }
      }
    } catch (e) {
      log('❌ [NotificationController] Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success) {
        // Update local state
        notifications.value = notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            createdAt: notification.createdAt,
            isRead: true,
            type: notification.type,
            bookingId: notification.bookingId,
          );
        }).toList();
        unreadCount.value = 0;
      }
    } catch (e) {
      log('❌ [NotificationController] Error marking all notifications as read: $e');
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      log('❌ [NotificationController] Error loading unread count: $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
    await loadUnreadCount();
  }
}
