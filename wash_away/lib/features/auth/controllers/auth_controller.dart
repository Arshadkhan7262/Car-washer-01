import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      isLoggingIn.value = true;
      errorMessage.value = '';

      // Use GoogleSignIn.instance (singleton pattern in 7.x)
      // serverClientId is automatically read from strings.xml (default_web_client_id)
      // It's also configured in MainActivity.kt for native Android
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      // Initialize the Google Sign-In instance
      await googleSignIn.initialize();

      log('🔐 Starting Google Sign-In authentication...');
      log('📦 Package name: com.example.wash_away');
      log('🔑 Server Client ID: 10266283459-7g052icp6h684cru34f2ab3h6qdamnp9.apps.googleusercontent.com');

      // Sign out any existing session first to ensure a fresh sign-in
      try {
        await googleSignIn.signOut();
        log('🧹 Signed out from any existing Google session');
      } catch (e) {
        log('ℹ️ No existing session to sign out: $e');
      }

      // Trigger the authentication flow
      // authenticate() is the correct method for google_sign_in 7.x
      log('🚀 Calling authenticate()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        // User canceled the sign-in or it failed silently
        log('⚠️ Google Sign-In returned null - this usually means:');
        log('   1. User canceled the dialog');
        log('   2. SHA-1 fingerprint not registered in Google Cloud Console');
        log('   3. Package name mismatch in OAuth Client ID');
        log('   4. OAuth Client ID configuration issue');
        isLoading.value = false;
        isLoggingIn.value = false;
        errorMessage.value = 'Google Sign-In failed. Please check:\n1. SHA-1 fingerprint is registered\n2. Package name matches\n3. OAuth Client ID is correct';
        return false;
      }

      log('✅ Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      log('🔐 Requesting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      log('🔑 Authentication details received');
      log('   - idToken: ${googleAuth.idToken != null ? "✅ Present (${googleAuth.idToken!.length} chars)" : "❌ NULL"}');

      if (googleAuth.idToken == null) {
        log('❌ Failed to get Google ID token');
        log('   This usually means serverClientId is incorrect or not configured properly');
        isLoading.value = false;
        isLoggingIn.value = false;
        errorMessage.value = 'Failed to get Google ID token. Please check serverClientId configuration.';
        return false;
      }

      // Store idToken safely (no force unwrap needed since we checked above)
      final String idToken = googleAuth.idToken!;
      log('🔑 Got Google ID token (${idToken.length} chars), sending to backend...');
      log('🌐 Backend endpoint: /auth/google/customer');

      // Send ID token to backend with detailed error handling
      try {
        log('📡 Calling backend API...');
        await _authService.loginWithGoogle(idToken);
        log('✅ Backend login successful');
      } catch (e, stackTrace) {
        log('❌ Backend login failed: $e');
        log('📚 Stack trace: $stackTrace');
        isLoading.value = false;
        isLoggingIn.value = false;
        errorMessage.value = 'Backend login failed: ${e.toString().replaceAll('Exception: ', '').replaceAll('Google login failed: ', '')}';
        return false;
      }

      isLoading.value = false;
      isLoggingIn.value = false;

      // Success - navigate to dashboard with error handling
      try {
        log('🚀 Navigating to dashboard...');
        Get.offAllNamed('/dashboard');
        log('✅ Navigation successful');
      } catch (e) {
        log('❌ Navigation failed: $e');
        // Don't return false here - login was successful, just navigation failed
        // User can manually navigate
      }
      return true;
    } on GoogleSignInException catch (e) {
      isLoading.value = false;
      isLoggingIn.value = false;
      
      // Handle specific Google Sign-In errors
      String errorMsg = 'Google Sign-In failed';
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // "Canceled" after selecting account usually means configuration issue
        errorMsg = 'Google Sign-In configuration issue.\n\n'
            'Since you\'re using Web Client ID, please verify:\n'
            '1. Web Client ID is correct: 773204771050-m2386frnvq934chd608mcvs5qf1nkuli.apps.googleusercontent.com\n'
            '2. Package name matches in Google Cloud Console: com.example.wash_away\n'
            '3. DEFAULT_WEB_CLIENT_ID meta-data is in AndroidManifest.xml\n'
            '4. If still failing, you may need to create an Android OAuth Client ID with SHA-1\n'
            '   SHA-1: 4F:AE:6D:5D:40:79:96:7C:55:61:97:24:5F:71:DC:9B:84:5F:0D:A4';
        log('❌ Google Sign-In Exception: ${e.code}');
        log('   Message: ${e.toString()}');
        log('   Using Web Client ID: 773204771050-m2386frnvq934chd608mcvs5qf1nkuli.apps.googleusercontent.com');
      } else if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        errorMsg = 'Google Sign-In configuration error.\n\n'
            'Please check:\n'
            '1. serverClientId is set correctly\n'
            '2. Package name matches: com.example.wash_away\n'
            '3. OAuth Client ID exists in Google Cloud Console';
        log('❌ Google Sign-In Exception: ${e.code}');
        log('   Message: ${e.toString()}');
      } else {
        errorMsg = 'Google Sign-In error: ${e.toString()}';
        log('❌ Google Sign-In Exception: ${e.code}');
        log('   Message: ${e.toString()}');
      }
      
      errorMessage.value = errorMsg;
      return false;
    } catch (e) {
      isLoading.value = false;
      isLoggingIn.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '').replaceAll('Google login failed: ', '');
      log('❌ Google Login Error: $e');
      return false;
    }
  }
}

