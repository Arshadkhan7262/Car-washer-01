import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/auth/services/auth_service.dart';
import '../features/profile/services/profile_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  // Loading state
  var isLoading = true.obs;

  // User Info
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userInitial = ''.obs;
  final RxBool isGoldMember = false.obs;

  // Stats
  final RxInt totalWashes = 0.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxDouble walletBalance = 0.0.obs;

  // Preferences
  final RxBool pushNotificationEnabled = false.obs;
  final RxBool twoFactorAuthEnabled = false.obs;

  // Theme Colors and Constants
  static const Color darkBackgroundColor = Color(0xFF131313);
  static const Color cardColor = Color(0xFF282828);
  static const Color primaryYellow = Color(0xFFFBC02D);
  static const Color primaryBlue = Color(0xFF42A5F5);
  static const Color signoutButtonBorder = Color(0xFF424242);
  static const Color primaryRed = Color(0xFFE53935);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  /// Fetch profile data from backend
  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final profileData = await _profileService.getProfile();

      // Update user info
      if (profileData['user'] != null) {
        final user = profileData['user'];
        userName.value = user['name'] ?? '';
        userEmail.value = user['email'] ?? '';
        userPhone.value = user['phone'] ?? '';
        userInitial.value = user['userInitial'] ?? (userName.value.isNotEmpty ? userName.value[0].toUpperCase() : 'U');
        isGoldMember.value = user['is_gold_member'] ?? false;
      }

      // Update stats
      if (profileData['stats'] != null) {
        final stats = profileData['stats'];
        totalWashes.value = stats['total_washes'] ?? 0;
        totalSpent.value = (stats['total_spent'] ?? 0).toDouble();
        walletBalance.value = (stats['wallet_balance'] ?? 0).toDouble();
      }

      // Update preferences
      if (profileData['preferences'] != null) {
        final preferences = profileData['preferences'];
        pushNotificationEnabled.value = preferences['push_notification_enabled'] ?? false;
        twoFactorAuthEnabled.value = preferences['two_factor_auth_enabled'] ?? false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle push notification preference
  Future<void> togglePushNotification(bool value) async {
    try {
      pushNotificationEnabled.value = value;
      await _profileService.updatePreferences(
        pushNotificationEnabled: value,
      );
      Get.snackbar('Success', 'Push notification preference updated');
    } catch (e) {
      // Revert on error
      pushNotificationEnabled.value = !value;
      Get.snackbar('Error', 'Failed to update preference: ${e.toString()}');
    }
  }

  /// Toggle two factor auth preference
  Future<void> toggleTwoFactorAuth(bool value) async {
    try {
      twoFactorAuthEnabled.value = value;
      await _profileService.updatePreferences(
        twoFactorAuthEnabled: value,
      );
      Get.snackbar('Success', 'Two factor auth preference updated');
    } catch (e) {
      // Revert on error
      twoFactorAuthEnabled.value = !value;
      Get.snackbar('Error', 'Failed to update preference: ${e.toString()}');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _authService.logout();
      Get.offAllNamed('/login');
      Get.snackbar('Sign Out', 'You have been signed out successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: ${e.toString()}');
    }
  }
}

