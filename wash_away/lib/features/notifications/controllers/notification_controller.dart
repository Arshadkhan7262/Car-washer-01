import 'dart:developer';
import 'package:get/get.dart';
import '../models/notification_model.dart';

/// Data for the in-app banner shown at the top when a push is received in foreground
class InAppBannerData {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const InAppBannerData({
    required this.title,
    required this.body,
    required this.data,
  });
}

/// Notification Controller
/// Manages list of notifications received in the app
class NotificationController extends GetxController {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  /// In-app banner shown at top of screen when push received in foreground (replaces green snackbar)
  final Rx<InAppBannerData?> banner = Rx<InAppBannerData?>(null);

  /// When a foreground push is received for a booking, we record it so Track Order
  /// can suppress the green snackbar (push notification / banner already shown).
  final Map<String, DateTime> _lastForegroundPushByBooking = {};

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

  /// Show in-app banner at top (foreground push). Replaces green snackbar.
  void showBanner({required String title, required String body, Map<String, dynamic>? data}) {
    banner.value = InAppBannerData(
      title: title,
      body: body,
      data: data ?? {},
    );
    log('✅ [NotificationController] Banner shown: $title');
  }

  /// Dismiss the in-app banner
  void dismissBanner() {
    banner.value = null;
  }

  /// Record that a foreground push was shown for this booking (so snackbar can be suppressed).
  void recordForegroundPush(String bookingId) {
    if (bookingId.isEmpty) return;
    _lastForegroundPushByBooking[bookingId] = DateTime.now();
    // Keep only last 20 entries to avoid unbounded growth
    if (_lastForegroundPushByBooking.length > 20) {
      final sorted = _lastForegroundPushByBooking.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (var i = 0; i < _lastForegroundPushByBooking.length - 20; i++) {
        _lastForegroundPushByBooking.remove(sorted[i].key);
      }
    }
  }

  /// True if a foreground push was shown for this booking recently (so do not show snackbar).
  bool wasRecentlyNotifiedByPush(String bookingId, {Duration within = const Duration(seconds: 12)}) {
    final at = _lastForegroundPushByBooking[bookingId];
    if (at == null) return false;
    return DateTime.now().difference(at) < within;
  }

  /// Update unread count
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
}

