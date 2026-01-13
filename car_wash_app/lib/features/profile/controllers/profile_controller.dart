import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  // Observable status matching the toggle on Home/Profile
  var isOnline = false.obs;
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
      Get.snackbar("Error", "Failed to load profile: ${e.toString()}");
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
      phone.value = user['phone'] ?? '';
      walletBalance.value = (user['wallet_balance'] ?? 0).toDouble();
    } else {
      // Fallback to direct fields if user object doesn't exist
      userName.value = profileData['name'] ?? '';
      email.value = profileData['email'] ?? '';
    }
    
    // Extract washer data
    if (washer != null) {
      isOnline.value = washer['online_status'] ?? false;
      userRating.value = (washer['rating'] ?? 0).toDouble();
      totalJobs.value = washer['total_jobs'] ?? 0;
      completedJobs.value = washer['completed_jobs'] ?? 0;
      totalEarnings.value = (washer['total_earnings'] ?? 0).toDouble();
    } else if (profileData['status'] != null) {
      // If only status is available (from check-status endpoint)
      // Set default values for pending accounts
      isOnline.value = false;
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
        Get.snackbar("Error", "Failed to update online status");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update online status: $e");
    }
  }

  Future<void> signOut() async {
    await _authService.logout();
    Get.offAllNamed('/login');
  }
  
  Future<void> refreshProfile() async {
    await loadProfile();
  }
}
