import 'package:get/get.dart';
import 'dart:async';
import '../../features/auth/services/auth_service.dart';
import 'widgets/suspended_account_overlay.dart';
import 'services/location_initialization_service.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/jobs/controllers/jobs_controller.dart';

class DashboardController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final AuthService _authService = AuthService();
  final LocationInitializationService _locationInitService = LocationInitializationService();
  Timer? _statusCheckTimer;
  final RxBool isPendingApproval = false.obs;
  String? _lastKnownStatus; // Track previous status to detect changes

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
        _lastKnownStatus = cachedStatus;
        return;
      }

      // Only check API if account is active (or status unknown)
      final statusData = await _authService.checkUserStatus();
      if (statusData != null) {
        final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
        isPendingApproval.value = (washerStatus == 'pending');
        
        // Check if status changed from pending to active (account approved)
        if (_lastKnownStatus == 'pending' && washerStatus == 'active') {
          // Account was just approved - initialize location tracking
          _initializeLocationForApprovedAccount();
        }
        
        _lastKnownStatus = washerStatus;
        
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
      } else {
        // If no status data, check if we have a cached status
        if (cachedStatus != null) {
          _lastKnownStatus = cachedStatus;
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Initialize location tracking when account is approved
  Future<void> _initializeLocationForApprovedAccount() async {
    try {
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Initialize location tracking
      await _locationInitService.initializeLocationTracking();
    } catch (e) {
      // Silently handle errors - location will be requested when needed
    }
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    
    // Refresh home screen data when navigating to home tab
    if (index == 0) {
      // Home tab selected - refresh earnings and stats
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadDashboardData();
      }
    }
    
    // Refresh jobs when navigating to jobs tab
    if (index == 1) {
      if (Get.isRegistered<JobController>()) {
        final jobController = Get.find<JobController>();
        jobController.fetchJobs();
      }
    }
  }
}
