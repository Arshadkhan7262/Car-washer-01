import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../../dashboard/services/location_initialization_service.dart';
import '../../notifications/controllers/fcm_token_controller.dart';

/// Authentication Controller
/// Manages Email Authentication flow via Backend API
class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final LocationInitializationService _locationInitService = LocationInitializationService();

  // Observable state variables
  var isLoading = false.obs;
  var isLoggingIn = false.obs;
  var isRegistering = false.obs;
  var isSendingOTP = false.obs;
  var isVerifyingOTP = false.obs;
  var isResettingPassword = false.obs;
  var errorMessage = ''.obs;
  
  // Timer for resend OTP
  var resendTimer = 0.obs; // Timer in seconds
  var canResend = false.obs; // Whether resend button is enabled
  
  // Email for OTP flow
  String? _email;

  // Timer controller
  Timer? _resendTimerController;

  /// Login with email and password
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      isLoggingIn.value = true;
      errorMessage.value = '';

      final result = await _authService.loginWithEmail(email, password);

      isLoggingIn.value = false;

      // Check if washer status is pending
      final washerStatus = result['washer']?['status'];
      if (washerStatus == 'pending') {
        // Navigate to dashboard with pending status
        Get.offAllNamed('/dashboard', arguments: {'isPending': true});
        return true;
      }

      // Initialize FCM token after successful login
      _initializeFcmToken();

      // If account is active, initialize location tracking after navigation
      if (washerStatus == 'active') {
        // Small delay to ensure dashboard is loaded
        Future.delayed(const Duration(milliseconds: 1000), () {
          _locationInitService.initializeLocationTracking();
        });
      }

      // Success - navigate to dashboard
      Get.offAllNamed('/dashboard');
      return true;
    } catch (e) {
      isLoggingIn.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Login failed: ', '');
      return false;
    }
  }

  /// Register with email and password
  /// After registration: Navigate to email verification screen
  Future<bool> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      isRegistering.value = true;
      errorMessage.value = '';

      final result = await _authService.registerWithEmail(email, password, name, phone);

      isRegistering.value = false;

      // IMPORTANT: Registration doesn't return tokens
      // User must verify email via OTP first
      // Navigate to email verification screen
      _email = result['email'];
      Get.toNamed('/email-otp-verify', arguments: {
        'email': _email,
        'isRegistration': true,
      });
      return true;
    } catch (e) {
      isRegistering.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Registration failed: ', '');
      return false;
    }
  }

  /// Request email OTP
  Future<bool> requestEmailOTP(String email) async {
    try {
      isSendingOTP.value = true;
      errorMessage.value = '';
      _email = email.toLowerCase();

      final result = await _authService.requestEmailOTP(email);

        isSendingOTP.value = false;
      _email = result['email'];
      
          // Start resend timer (60 seconds)
          _startResendTimer();
      
          // Navigate to OTP screen
      Get.toNamed('/email-otp-verify', arguments: {'email': _email});
      return true;
    } catch (e) {
      isSendingOTP.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Failed to send OTP: ', '');
      return false;
    }
  }

  /// Verify email OTP
  /// If canLogin=true: Navigate to dashboard (status=active)
  /// If canLogin=false: Show message about admin approval (status=pending)
  Future<bool> verifyEmailOTP(String otp) async {
    try {
      if (_email == null) {
        errorMessage.value = 'Email not found. Please request OTP again.';
        return false;
      }

      isVerifyingOTP.value = true;
      errorMessage.value = '';

      final result = await _authService.verifyEmailOTP(_email!, otp);

      isVerifyingOTP.value = false;

      // Initialize FCM token after successful email verification
      _initializeFcmToken();

      // Check if account can login
      final canLogin = result['canLogin'] ?? false;
      
      if (canLogin) {
        // Account is active - navigate to dashboard
        Get.offAllNamed('/dashboard');
        return true;
      } else {
        // Email verified but account is pending admin approval
        // Navigate to dashboard with pending status overlay
        Get.offAllNamed('/dashboard', arguments: {'isPending': true});
        return true;
      }
    } catch (e) {
      isVerifyingOTP.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('OTP verification failed: ', '');
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      isResettingPassword.value = true;
      errorMessage.value = '';

      final result = await _authService.requestPasswordReset(email);

      isResettingPassword.value = false;
      
      // Show success message
      Get.snackbar(
        'Success',
        result['message'] ?? 'Password reset link sent to your email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to email OTP screen for reset code
      _email = email.toLowerCase();
      Get.toNamed('/email-otp-verify', arguments: {
        'email': _email,
        'isPasswordReset': true,
      });
      return true;
    } catch (e) {
      isResettingPassword.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Failed to send reset link: ', '');
      return false;
    }
  }

  /// Reset password with OTP
  Future<bool> resetPassword(String otp, String newPassword) async {
    try {
      if (_email == null) {
        errorMessage.value = 'Email not found. Please request password reset again.';
        return false;
      }

      isResettingPassword.value = true;
      errorMessage.value = '';

      final result = await _authService.resetPassword(_email!, otp, newPassword);

      isResettingPassword.value = false;

      // Show success message
      Get.snackbar(
        'Success',
        result['message'] ?? 'Password reset successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        );

      // Navigate to login
      Get.offAllNamed('/login');
      return true;
    } catch (e) {
      isResettingPassword.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Password reset failed: ', '');
      return false;
    }
  }

  /// Resend email OTP
  Future<bool> resendEmailOTP() async {
    if (_email == null) {
      errorMessage.value = 'Email not found';
      return false;
    }

    if (!canResend.value) {
      errorMessage.value = 'Please wait before resending OTP';
      return false;
    }

    // Reset timer and disable resend
    _stopResendTimer();
    canResend.value = false;
    resendTimer.value = 0;

    final success = await requestEmailOTP(_email!);
    
    if (!success) {
      // Re-enable resend if sending failed
      canResend.value = true;
    }

    return success;
  }

  /// Start resend timer (60 seconds)
  void _startResendTimer() {
    _stopResendTimer(); // Clear any existing timer
    
    resendTimer.value = 60; // 60 seconds
    canResend.value = false;

    _resendTimerController = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        _stopResendTimer();
        canResend.value = true;
      }
    });
  }

  /// Stop resend timer
  void _stopResendTimer() {
    _resendTimerController?.cancel();
    _resendTimerController = null;
  }

  /// Format timer seconds to MM:SS
  String get formattedTimer {
    final minutes = resendTimer.value ~/ 60;
    final seconds = resendTimer.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Get current email
  String? get email => _email;

  /// Set email (for password reset flow)
  void setEmail(String email) {
    _email = email.toLowerCase();
  }

  /// Initialize FCM token controller and save token to backend
  Future<void> _initializeFcmToken() async {
    try {
      // Get or create FCM token controller
      FcmTokenController? fcmController;
      if (Get.isRegistered<FcmTokenController>()) {
        fcmController = Get.find<FcmTokenController>();
      } else {
        fcmController = Get.put(FcmTokenController());
      }
      
      // Initialize FCM token
      if (fcmController != null) {
        await fcmController.initializeFcmToken();
      }
    } catch (e) {
      // Don't fail auth if FCM token initialization fails
      print('❌ [AuthController] Error initializing FCM token: $e');
    }
  }

  @override
  void onClose() {
    _stopResendTimer();
    // Remove FCM token controller if exists
    if (Get.isRegistered<FcmTokenController>()) {
      final fcmController = Get.find<FcmTokenController>();
      fcmController.removeToken();
      Get.delete<FcmTokenController>();
    }
    super.onClose();
  }
}
