import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

/// Authentication Controller
/// Manages Customer Authentication flow via Backend API
class AuthController extends GetxController {
  final AuthService _authService = AuthService();

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

      await _authService.loginWithEmail(email, password);

      isLoggingIn.value = false;

      // Success - navigate to dashboard
      // TODO: Update route name when dashboard is ready
      Get.offAllNamed('/dashboard');
      return true;
    } catch (e) {
      isLoggingIn.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Login failed: ', '');
      return false;
    }
  }

  /// Register with email and password
  /// After registration: Save session, navigate to OTP verification screen
  /// User must verify email before accessing dashboard
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

      // Session is saved (tokens stored), but navigate to OTP verification screen
      _email = result['email'];
      _startResendTimer(); // Start timer for resend OTP
      Get.offAllNamed('/email-otp-verify', arguments: {
        'email': _email,
        'isRegistration': true,
      });
      Get.snackbar('Success', result['message'] ?? 'Account created successfully. Please verify your email.');
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
  /// After verification: Navigate to dashboard (customers are always active)
  /// Tokens are already saved from registration, but verifyEmailOTP also saves them
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
      _resendTimerController?.cancel(); // Stop timer on successful verification

      // Tokens are already saved in verifyEmailOTP service method
      // Customers are always active - navigate to dashboard after email verification
      Get.offAllNamed('/dashboard');
      Get.snackbar('Success', result['message'] ?? 'Email verified successfully');
      return true;
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

  @override
  void onClose() {
    _stopResendTimer();
    super.onClose();
  }

  /// Get current email
  String? get email => _email;

  /// Set email (for password reset flow)
  void setEmail(String email) {
    _email = email.toLowerCase();
  }
}

