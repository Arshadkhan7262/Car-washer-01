import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';
import 'widgets/suspended_account_overlay.dart';
import 'services/location_initialization_service.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/jobs/controllers/jobs_controller.dart';
import '../../features/wallet/controllers/wallet_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';

class DashboardController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final AuthService _authService = AuthService();
  final LocationInitializationService _locationInitService = LocationInitializationService();
  Timer? _statusCheckTimer;
  final RxBool isPendingApproval = false.obs;
  String? _lastKnownStatus; // Track previous status to detect changes
  int? _lastStatusCheckTime; // Track last API check time for pending/suspended accounts

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
      // First check cached status - if pending or suspended, only check API occasionally
      final cachedStatus = await _authService.getCachedAccountStatus();
      
      // Skip API call if status is pending/suspended (overlay already showing)
      // Only check API if status is active or unknown (to detect changes)
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // For pending/suspended, check API less frequently (every 30 seconds instead of 5)
        // This reduces main thread blocking
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastStatusCheckTime != null && (now - _lastStatusCheckTime!) < 30000) {
          // Skip this check - too soon
          isPendingApproval.value = (cachedStatus == 'pending');
          return;
        }
        _lastStatusCheckTime = now;
      }
      
      // Check API to detect status changes (with timeout to prevent blocking)
      final statusData = await _authService.checkUserStatus().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (statusData != null) {
        final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
        isPendingApproval.value = (washerStatus == 'pending');
        
        // Check if status changed from pending to active (account approved)
        if (_lastKnownStatus == 'pending' && washerStatus == 'active') {
          // Account was just approved - refresh all data and initialize location
          await _onAccountApproved();
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
        // If no status data, use cached status
        if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
          isPendingApproval.value = (cachedStatus == 'pending');
          _lastKnownStatus = cachedStatus;
        } else if (cachedStatus != null) {
          _lastKnownStatus = cachedStatus;
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Called when account status changes from pending to active
  /// Refreshes all app data (profile, home, jobs, wallet)
  Future<void> _onAccountApproved() async {
    try {
      // Show success snackbar
      Get.snackbar(
        'Account Approved',
        'Your account has been approved! You can now start accepting jobs.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      
      // Initialize location tracking
      await _initializeLocationForApprovedAccount();
      
      // Refresh profile data
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        await profileController.refreshProfile();
        // Set online status to true by default when account is approved
        if (!profileController.isOnline.value) {
          await profileController.toggleStatus(true);
        }
      }
      
      // Refresh home data
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.loadDashboardData();
        // Set online status to true by default when account is approved
        if (!homeController.isOnline.value) {
          await homeController.toggleStatus(true);
        }
      }
      
      // Refresh jobs data
      if (Get.isRegistered<JobController>()) {
        final jobController = Get.find<JobController>();
        jobController.fetchJobs();
      }
      
      // Refresh wallet data
      if (Get.isRegistered<WalletController>()) {
        final walletController = Get.find<WalletController>();
        walletController.loadWalletData();
      }
    } catch (e) {
      // Silently handle errors - data will refresh on next navigation
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
