import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../../../screens/track_order_screen.dart';

/// In-app notification banner shown at the top (app bar area) when a push is
/// received in foreground. Replaces the green bottom snackbar.
class InAppNotificationBanner extends StatelessWidget {
  const InAppNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller exists from first frame so Obx is active when showBanner is called
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }
    final controller = Get.find<NotificationController>();
    return Obx(() {
      final data = controller.banner.value;
      if (data == null) return const SizedBox.shrink();
      return _BannerContent(data: data);
    });
  }
}

class _BannerContent extends StatefulWidget {
  final InAppBannerData data;

  const _BannerContent({required this.data});

  @override
  State<_BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends State<_BannerContent> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) Get.find<NotificationController>().dismissBanner();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    _dismissTimer?.cancel();
    Get.find<NotificationController>().dismissBanner();
    final bookingId = widget.data.data['booking_id']?.toString() ??
        widget.data.data['bookingId']?.toString();
    if (bookingId != null && bookingId.isNotEmpty && Get.context != null) {
      Get.offAllNamed('/dashboard');
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.to(() => TrackerOrderScreen(bookingId: bookingId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      elevation: 8,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.primaryContainer
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: isDark
                        ? theme.colorScheme.primary
                        : const Color(0xFF2E7D32),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.data.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? theme.colorScheme.onPrimaryContainer
                                : const Color(0xFF1B5E20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.data.body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.85)
                                : const Color(0xFF388E3C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? theme.colorScheme.onPrimaryContainer
                        : const Color(0xFF2E7D32),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
