import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Login with Google using Firebase Authentication (Android-only)
  /// Uses Firebase Google Sign-In - no Web Client ID needed
  /// Firebase handles authentication using google-services.json configuration
  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      isLoggingIn.value = true;
      errorMessage.value = '';

      log('🔐 Starting Firebase Google Sign-In (Android-only)...');

      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      // Sign out any existing Firebase session
      try {
        await firebaseAuth.signOut();
        log('🧹 Signed out from any existing Firebase session');
      } catch (e) {
        log('ℹ️ No existing Firebase session: $e');
      }

      // Use Google Sign-In (6.2.2)
      // Explicitly provide serverClientId to ensure ID token can be retrieved
      // This fixes error 12500 when Android OAuth client is not yet configured
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '91468661410-57tg402nos5tf94jvc56ckina69tabkb.apps.googleusercontent.com', // Web Client ID from google-services.json
      );

      // Sign out any existing Google session
      try {
        await googleSignIn.signOut();
        log('🧹 Signed out from any existing Google session');
      } catch (e) {
        log('ℹ️ No existing Google session: $e');
      }

      // Sign in with Google using signIn() method (for google_sign_in 6.2.2)
      // Uses Web Client ID explicitly to get ID token for Firebase
      log('🚀 Initiating Google Sign-In (Android with Web Client ID)...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        log('⚠️ Google Sign-In was canceled by user');
        isLoading.value = false;
        isLoggingIn.value = false;
        return false;
      }

      log('✅ Google Sign-In successful for: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        log('❌ Failed to get Google ID token');
        isLoading.value = false;
        isLoggingIn.value = false;
        errorMessage.value = 'Failed to get Google ID token. Please ensure Android OAuth Client is configured in Firebase Console.';
        return false;
      }

      // Create Firebase credential
      log('🔥 Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      log('🔥 Signing in to Firebase...');
      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        log('❌ Firebase sign-in failed');
        isLoading.value = false;
        isLoggingIn.value = false;
        errorMessage.value = 'Firebase authentication failed.';
        return false;
      }

      log('✅ Firebase authentication successful');
      log('   User UID: ${userCredential.user!.uid}');
      log('   User Email: ${userCredential.user!.email}');

      // Save user data locally
      final firebaseUser = userCredential.user!;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_id', firebaseUser.uid);
        await prefs.setString('user_email', firebaseUser.email ?? '');
        await prefs.setString('user_name', firebaseUser.displayName ?? '');
        await prefs.setString('user_phone', firebaseUser.phoneNumber ?? '');
        await prefs.setString('auth_provider', 'google');
        await prefs.setString('profile_image', firebaseUser.photoURL ?? '');
        log('💾 Firebase user data saved locally');
      } catch (e) {
        log('⚠️ Failed to save user data: $e');
      }

      isLoading.value = false;
      isLoggingIn.value = false;

      // Navigate to dashboard
      Get.offAllNamed('/dashboard');
      return true;
    } on PlatformException catch (e) {
      isLoading.value = false;
      isLoggingIn.value = false;
      
      // Handle specific Google Sign-In platform errors
      String errorMsg = 'Google Sign-In failed';
      
      if (e.code == 'sign_in_failed') {
        // Parse error code from message (e.g., "ApiException: 12500" or "ApiException: 10")
        String? errorCodeStr;
        if (e.message != null && e.message!.contains('ApiException:')) {
          try {
            final match = RegExp(r'ApiException:\s*(\d+)').firstMatch(e.message!);
            errorCodeStr = match?.group(1);
          } catch (_) {}
        }
        
        if (errorCodeStr == '12500' || errorCodeStr == '10') {
          // Error codes 10 and 12500 = DEVELOPER_ERROR
          // Usually means SHA-1 fingerprint not added or google-services.json not updated
          errorMsg = 'Google Sign-In configuration error (Error $errorCodeStr).\n\n'
              'The OAuth client is automatically created by Firebase, but you need to:\n'
              '1. Add SHA-1 fingerprint in Firebase Console (Project Settings → Your Android App)\n'
              '2. Wait 2-3 minutes for Firebase to process\n'
              '3. Download updated google-services.json from Firebase Console\n'
              '4. Replace: wash_away/android/app/google-services.json\n'
              '5. Rebuild: flutter clean && flutter pub get && flutter run\n\n'
              'Note: OAuth client is auto-created by Firebase - no manual OAuth setup needed!';
        } else {
          errorMsg = 'Google Sign-In configuration error.\n\n'
              'Please verify in Firebase Console:\n'
              '1. Package name: com.example.wash_away\n'
              '2. SHA-1 fingerprint is added\n'
              '3. Android OAuth Client is configured\n\n'
              'Error Code: ${errorCodeStr ?? "unknown"}';
        }
        log('❌ Google Sign-In Platform Error: ${e.code}');
        log('   Error Code: ${errorCodeStr ?? "unknown"}');
        log('   Message: ${e.message}');
        log('   Details: ${e.details}');
      } else {
        errorMsg = 'Google Sign-In error: ${e.message ?? e.toString()}';
        log('❌ Google Sign-In Platform Error: ${e.code}');
        log('   Message: ${e.message}');
      }
      
      errorMessage.value = errorMsg;
      return false;
    } catch (e) {
      isLoading.value = false;
      isLoggingIn.value = false;
      errorMessage.value = 'Google Sign-In failed: ${e.toString()}';
      log('❌ Google Login Error: $e');
      return false;
    }
  }
}

