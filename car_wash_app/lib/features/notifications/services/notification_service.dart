import 'dart:developer';
import '../../../api/api_client.dart';
import '../models/notification_model.dart';

/// Notification Service
/// Handles API calls for notification management
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all notifications for the current washer
  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      log('📱 [NotificationService] Fetching notifications...');
      
      final response = await _apiClient.get(
        '/washer/notifications',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (!response.success) {
        log('❌ [NotificationService] Error fetching notifications: ${response.error}');
        return null;
      }

      log('✅ [NotificationService] Notifications fetched successfully');
      return response.data['data'];
    } catch (e) {
      log('❌ [NotificationService] Exception fetching notifications: $e');
      return null;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      log('📱 [NotificationService] Marking notification as read: $notificationId');
      
      final response = await _apiClient.put(
        '/washer/notifications/$notificationId/read',
        body: {},
      );

      if (!response.success) {
        log('❌ [NotificationService] Error marking notification as read: ${response.error}');
        return false;
      }

      log('✅ [NotificationService] Notification marked as read');
      return true;
    } catch (e) {
      log('❌ [NotificationService] Exception marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      log('📱 [NotificationService] Marking all notifications as read...');
      
      final response = await _apiClient.put(
        '/washer/notifications/read-all',
        body: {},
      );

      if (!response.success) {
        log('❌ [NotificationService] Error marking all notifications as read: ${response.error}');
        return false;
      }

      log('✅ [NotificationService] All notifications marked as read');
      return true;
    } catch (e) {
      log('❌ [NotificationService] Exception marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        '/washer/notifications/unread-count',
      );

      if (!response.success) {
        return 0;
      }

      return response.data['data']?['count'] ?? 0;
    } catch (e) {
      log('❌ [NotificationService] Exception getting unread count: $e');
      return 0;
    }
  }
}
