import 'package:get/get.dart';
import 'dart:async';
import '../../features/auth/services/auth_service.dart';
import 'widgets/suspended_account_overlay.dart';

class DashboardController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final AuthService _authService = AuthService();
  Timer? _statusCheckTimer;
  final RxBool isPendingApproval = false.obs;

  @override
  void onInit() {
    super.onInit();
    _startStatusChecking();
  }

  @override
  void onClose() {
    _statusCheckTimer?.cancel();
    super.onClose();
  }

  void _startStatusChecking() {
    // Check status immediately
    _checkStatus();
    
    // Then check every 5 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      // First check cached status - if pending or suspended, don't call API
      final cachedStatus = await _authService.getCachedAccountStatus();
      
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // Don't call API if account is pending or suspended
        // The overlay is already showing, no need to check status
        isPendingApproval.value = (cachedStatus == 'pending');
        return;
      }

      // Only check API if account is active (or status unknown)
      final statusData = await _authService.checkUserStatus();
      if (statusData != null) {
        final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
        isPendingApproval.value = (washerStatus == 'pending');
        
        // If status is suspended, show suspended overlay
        if (washerStatus == 'suspended') {
          // Check if suspended overlay is already showing
          final isDialogOpen = Get.isDialogOpen ?? false;
          if (!isDialogOpen) {
            Get.dialog(
              const SuspendedAccountOverlay(),
              barrierDismissible: false,
            );
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
