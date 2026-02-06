import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../home/controllers/home_controller.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  // Observable status matching the toggle on Home/Profile
  // Default to true - user should be online by default
  var isOnline = true.obs;
  var isLoading = true.obs;

  // Profile Data
  var userName = "".obs;
  var userRating = 0.0.obs;
  var totalJobs = 0.obs;
  var completedJobs = 0.obs;
  var email = "".obs;
  var phone = "".obs;
  var walletBalance = 0.0.obs;
  var totalEarnings = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Load profile data immediately (don't wait)
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      
      // Try to load from cache first for instant display
      final cachedEmail = await _authService.getUserEmail();
      final cachedStatus = await _authService.getCachedAccountStatus();
      
      // If account is pending/suspended, don't call API - use cached data
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // Set basic info from cache
        if (cachedEmail != null) {
          email.value = cachedEmail;
        }
        isLoading.value = false;
        // Don't call API for pending/suspended accounts
        return;
      }
      
      // Use new profile API endpoint
      final profileData = await _profileService.getWasherProfile();
      
      // Fallback to auth service if profile service fails
      if (profileData == null) {
        var authProfileData = await _authService.getProfile();
        if (authProfileData == null) {
          authProfileData = await _authService.checkUserStatus();
        }
        
        if (authProfileData != null) {
          _extractProfileData(authProfileData);
        } else {
          // Use cached data if API fails
          if (cachedEmail != null) {
            email.value = cachedEmail;
          }
        }
      } else {
        _extractProfileData(profileData);
      }
    } catch (e) {
      // On error, try to use cached data
      final cachedEmail = await _authService.getUserEmail();
      if (cachedEmail != null) {
        email.value = cachedEmail;
      }
      Get.snackbar(
        "Error",
        "Failed to load profile: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _extractProfileData(Map<String, dynamic> profileData) {
    final user = profileData['user'];
    final washer = profileData['washer'];
    
    // Extract user data
    if (user != null) {
      userName.value = user['name'] ?? profileData['name'] ?? '';
      email.value = user['email'] ?? profileData['email'] ?? '';
      // Try multiple sources for phone number
      phone.value = user['phone'] ?? 
                    washer?['phone'] ?? 
                    profileData['phone'] ?? 
                    '';
      walletBalance.value = (user['wallet_balance'] ?? 0).toDouble();
    } else {
      // Fallback to direct fields if user object doesn't exist
      userName.value = profileData['name'] ?? '';
      email.value = profileData['email'] ?? '';
      // Try to get phone from washer or direct fields
      phone.value = washer?['phone'] ?? 
                    profileData['phone'] ?? 
                    '';
    }
    
    // Update HomeController with washer name if available
    _updateHomeControllerName();
    
    // Extract washer data
    if (washer != null) {
      // Use API value if available, otherwise default to true (online)
      final onlineStatusFromAPI = washer['online_status'];
      final accountStatus = washer['status'];
      
      // If account is active and online_status is false/null, default to true
      if (accountStatus == 'active' && (onlineStatusFromAPI == null || onlineStatusFromAPI == false)) {
        isOnline.value = true;
      } else {
        isOnline.value = onlineStatusFromAPI ?? true;
      }
      
      userRating.value = (washer['rating'] ?? 0).toDouble();
      totalJobs.value = washer['total_jobs'] ?? 0;
      completedJobs.value = washer['completed_jobs'] ?? 0;
      totalEarnings.value = (washer['total_earnings'] ?? 0).toDouble();
    } else if (profileData['status'] != null) {
      // If only status is available (from check-status endpoint)
      // Set default values for pending accounts
      final accountStatus = profileData['status'];
      // Default to online for active accounts, offline for pending/suspended
      isOnline.value = accountStatus == 'active' ? true : false;
      userRating.value = 0.0;
      totalJobs.value = 0;
      completedJobs.value = 0;
      totalEarnings.value = 0.0;
    }
  }

  Future<void> toggleStatus(bool value) async {
    try {
      final success = await _profileService.toggleOnlineStatus(value);
      
      if (success) {
        isOnline.value = value;
      } else {
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

  Future<void> signOut() async {
    await _authService.logout();
    Get.offAllNamed('/login');
  }
  
  Future<void> refreshProfile() async {
    await loadProfile();
  }
  
  /// Update HomeController with washer name
  void _updateHomeControllerName() {
    if (userName.value.isNotEmpty) {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.washerName.value = userName.value;
      }
    }
  }
}
