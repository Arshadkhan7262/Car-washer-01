import 'dart:async';
import 'package:flutter/foundation.dart';
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
  var email = Rxn<String>();

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
      this.email.value = result['email'];
      // Start resend timer (60 seconds)
      startResendTimer();
      Get.toNamed('/email-otp-verify', arguments: {
        'email': this.email.value,
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
      this.email.value = email.toLowerCase();

      final result = await _authService.requestEmailOTP(email);

        isSendingOTP.value = false;
      this.email.value = result['email'];
      
          // Start resend timer (60 seconds)
          startResendTimer();
      
          // Navigate to OTP screen
      Get.toNamed('/email-otp-verify', arguments: {'email': this.email.value});
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
      if (email.value == null) {
        errorMessage.value = 'Email not found. Please request OTP again.';
        return false;
      }

      isVerifyingOTP.value = true;
      errorMessage.value = '';

      final result = await _authService.verifyEmailOTP(email.value!, otp);

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
      this.email.value = email.toLowerCase();
      // Start resend timer (60 seconds)
      startResendTimer();
      Get.toNamed('/email-otp-verify', arguments: {
        'email': this.email.value,
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
      if (email.value == null) {
        errorMessage.value = 'Email not found. Please request password reset again.';
        return false;
      }

      isResettingPassword.value = true;
      errorMessage.value = '';

      final result = await _authService.resetPassword(email.value!, otp, newPassword);

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
  /// Sends OTP to washer's email via API: POST /washer/auth/send-email-otp
  Future<bool> resendEmailOTP() async {
    // If email is not set, try to get it from storage (app restart scenario)
    if (email.value == null) {
      try {
        final storedEmail = await _authService.getUserEmail();
        if (storedEmail != null) {
          email.value = storedEmail;
          debugPrint('📧 [resendEmailOTP] Loaded email from storage: $storedEmail');
        }
      } catch (e) {
        debugPrint('❌ [resendEmailOTP] Failed to load email from storage: $e');
      }
    }
    
    if (email.value == null) {
      errorMessage.value = 'Email not found';
      Get.snackbar(
        'Error',
        'Email not found. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!canResend.value) {
      errorMessage.value = 'Please wait before resending OTP';
      Get.snackbar(
        'Wait',
        'Please wait before resending OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // Reset timer and disable resend
    _stopResendTimer();
    canResend.value = false;
    resendTimer.value = 0;
    errorMessage.value = '';
    isSendingOTP.value = true;

    try {
      debugPrint('🔄 [resendEmailOTP] Sending OTP to email: ${email.value}');
      debugPrint('🔄 [resendEmailOTP] API: POST /washer/auth/send-email-otp');
      
      // Send OTP email directly (without navigation)
      // This calls: POST /washer/auth/send-email-otp with email in body
      final result = await _authService.requestEmailOTP(email.value!);
      
      isSendingOTP.value = false;
      email.value = result['email'];
      
      debugPrint('✅ [resendEmailOTP] OTP sent successfully to: ${result['email']}');
      debugPrint('✅ [resendEmailOTP] Response message: ${result['message']}');
      
      // Start resend timer (60 seconds)
      startResendTimer();
      
      // Show success message
      Get.snackbar(
        'Success',
        'OTP has been sent to ${result['email']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      return true;
    } catch (e) {
      isSendingOTP.value = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('Failed to send OTP: ', '');
      errorMessage.value = errorMsg;
      
      debugPrint('❌ [resendEmailOTP] Failed to send OTP: $errorMsg');
      
      // Show error message
      Get.snackbar(
        'Error',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // Re-enable resend if sending failed
      canResend.value = true;
      return false;
    }
  }

  /// Start resend timer (60 seconds)
  void startResendTimer() {
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

  /// Set email (for password reset flow)
  void setEmail(String email) {
    this.email.value = email.toLowerCase();
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
