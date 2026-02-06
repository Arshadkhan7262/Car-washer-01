import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../services/home_service.dart';

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  // Reactive states
  // Default to true - user should be online by default
  var isOnline = true.obs;
  var rating = 5.0.obs;
  var jobsCount = 0.obs; // Today's jobs
  var earnings = 0.00.obs; // Today's earnings
  var designedCount = 0.obs;
  var isLoading = true.obs;
  var washerName = "".obs; // Washer name from profile
  bool _nameLoaded = false; // Track if name has been loaded

  @override
  void onInit() {
    super.onInit();
    // Load name only once on first initialization
    _loadWasherNameOnce();
    loadDashboardData();
    
    // Listen for ProfileController updates to get name (only if not loaded)
    _listenToProfileUpdates();
  }

  /// Listen for ProfileController updates
  void _listenToProfileUpdates() {
    // Check periodically if ProfileController is available and has name
    // Only if name hasn't been loaded yet
    if (_nameLoaded) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<ProfileController>() && !_nameLoaded) {
        final profileController = Get.find<ProfileController>();
        if (profileController.userName.value.isNotEmpty && washerName.value.isEmpty) {
          washerName.value = profileController.userName.value;
          _nameLoaded = true;
        }
      }
    });
  }

  /// Load washer name only once (first time)
  Future<void> _loadWasherNameOnce() async {
    if (_nameLoaded) return;
    
    // Try to get name from ProfileController if available
    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      if (profileController.userName.value.isNotEmpty) {
        washerName.value = profileController.userName.value;
        _nameLoaded = true;
        return;
      }
    }
    
    // If ProfileController not available or name is empty, try to load from API
    await _loadNameFromAPI();
  }

  /// Load dashboard stats from API
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      
      // Check if account is pending or suspended - don't call API
      final cachedStatus = await _authService.getCachedAccountStatus();
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // Set default values for pending/suspended accounts
        jobsCount.value = 0;
        earnings.value = 0.0;
        rating.value = 0.0;
        isOnline.value = false; // Offline for pending/suspended
        isLoading.value = false;
        return;
      }
      
      final stats = await _homeService.getDashboardStats();
      
      if (stats != null) {
        // Update today's stats
        final today = stats['today'];
        if (today != null) {
          jobsCount.value = today['jobs'] ?? 0;
          earnings.value = (today['earnings'] ?? 0).toDouble();
        }
        
        // Update total stats
        final total = stats['total'];
        if (total != null) {
          rating.value = (total['rating'] ?? 0).toDouble();
        }
        
        // Update online status - default to true if not set
        isOnline.value = stats['online_status'] ?? true;
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load name from profile API
  Future<void> _loadNameFromAPI() async {
    if (_nameLoaded) return;
    
    try {
      final profileData = await _profileService.getWasherProfile();
      if (profileData != null) {
        final user = profileData['user'];
        final washer = profileData['washer'];
        if (user != null && user['name'] != null) {
          washerName.value = user['name'];
          _nameLoaded = true;
        } else if (washer != null && washer['name'] != null) {
          washerName.value = washer['name'];
          _nameLoaded = true;
        }
      }
    } catch (e) {
      print('Error loading washer name: $e');
    }
  }

  /// Toggle online status
  Future<void> toggleStatus(bool value) async {
    try {
      final success = await _profileService.toggleOnlineStatus(value);
      
      if (success) {
        isOnline.value = value;
        // Also update ProfileController if it exists
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          profileController.isOnline.value = value;
        }
      } else {
        // Revert on failure
        isOnline.value = !value;
        Get.snackbar(
          "Error",
          "Failed to update online status",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Revert on error
      isOnline.value = !value;
      Get.snackbar(
        "Error",
        "Failed to update online status: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  /// Refresh dashboard data
  Future<void> refreshData() async {
    await loadDashboardData();
  }
}
