import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_client.dart';

/// Authentication Service
/// Handles Customer Authentication via Backend API
class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Storage Keys
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';

  /// Login with email and password
  /// Requires: email_verified=true
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/login',
        body: {
          'email': email.toLowerCase(),
          'password': password,
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Login failed';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      if (token == null) {
        throw Exception('No access token received from server');
      }

      // Save tokens and user data
      await _saveAuthData(
        token: token,
        refreshToken: refreshToken,
        userId: user['id'],
        userEmail: user['email'],
        userName: user['name'],
        userPhone: user['phone'],
      );

      // Set token in API client for future requests
      _apiClient.setAuthToken(token);

      return {
        'success': true,
        'user': user,
        'token': token,
        'refreshToken': refreshToken,
        'message': 'Login successful',
      };
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Register with email and password
  /// After registration: tokens saved, navigate to OTP verification screen
  /// User must verify email via OTP before accessing dashboard
  Future<Map<String, dynamic>> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/register',
        body: {
          'email': email.toLowerCase(),
          'password': password,
          'name': name,
          'phone': phone,
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Registration failed';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      if (token == null) {
        throw Exception('No access token received from server');
      }

      // Save tokens and user data immediately (session saved)
      await _saveAuthData(
        token: token,
        refreshToken: refreshToken,
        userId: user['id'],
        userEmail: user['email'],
        userName: user['name'],
        userPhone: user['phone'],
      );

      // Set token in API client for future requests
      _apiClient.setAuthToken(token);

      return {
        'success': true,
        'user': user,
        'token': token,
        'refreshToken': refreshToken,
        'email': data['email'],
        'email_verified': data['email_verified'] ?? false,
        'status': data['status'] ?? 'active',
        'message': data['message'] ?? 'Account created successfully. Please verify your email.',
        'nextStep': 'verify_email', // Navigate to OTP screen
      };
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Request email OTP (4-digit, expires in 5 minutes)
  Future<Map<String, dynamic>> requestEmailOTP(String email) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/send-email-otp',
        body: {
          'email': email.toLowerCase(),
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to send OTP';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      
      return {
        'success': true,
        'email': data['email'],
        'message': data['message'] ?? 'OTP sent to your email',
        'status': data['status'] ?? 'active',
        'otp': data['otp'], // Only in development mode
      };
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  /// Verify email OTP
  /// Customers: Always returns tokens (status is always active)
  Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/verify-email-otp',
        body: {
          'email': email.toLowerCase(),
          'otp': otp,
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'OTP verification failed';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      if (token == null) {
        throw Exception('No access token received from server');
      }

      // Save tokens and user data
      await _saveAuthData(
        token: token,
        refreshToken: refreshToken,
        userId: user['id'],
        userEmail: user['email'],
        userName: user['name'],
        userPhone: user['phone'],
      );

      // Set token in API client for future requests
      _apiClient.setAuthToken(token);

      return {
        'success': true,
        'canLogin': data['canLogin'] ?? true, // Customers can always login after email verification
        'email_verified': data['email_verified'] ?? true,
        'status': data['status'] ?? 'active',
        'user': user,
        'token': token,
        'refreshToken': refreshToken,
        'message': data['message'] ?? 'Email verified successfully. You can now login.',
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset (sends 4-digit OTP, expires in 5 minutes)
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/forgot-password',
        body: {
          'email': email.toLowerCase(),
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to send reset code';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      
      return {
        'success': true,
        'message': data['message'] ?? 'If an account exists with this email, a password reset code has been sent.',
        'resetCode': data['resetCode'], // Only in development mode
      };
    } catch (e) {
      throw Exception('Failed to send reset code: ${e.toString()}');
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        '/customer/auth/reset-password',
        body: {
          'email': email.toLowerCase(),
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Password reset failed';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      
      return {
        'success': true,
        'message': data['message'] ?? 'Password reset successfully. You can now login with your new password.',
      };
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData({
    required String token,
    String? refreshToken,
    String? userId,
    String? userEmail,
    String? userName,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_authTokenKey, token);

    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }

    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }

    if (userEmail != null) {
      await prefs.setString(_userEmailKey, userEmail);
    }

    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    }

    if (userPhone != null) {
      await prefs.setString(_userPhoneKey, userPhone);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (isLoggedIn) {
      // Restore token in API client
      final token = prefs.getString(_authTokenKey);
      if (token != null) {
        _apiClient.setAuthToken(token);
      }
    }

    return isLoggedIn;
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get stored user phone
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }


  /// Logout user
  Future<void> logout() async {
    try {
      final token = await getAuthToken();
      if (token != null) {
        try {
          _apiClient.setAuthToken(token);
          await _apiClient.post('/customer/auth/logout');
        } catch (e) {
          // Ignore API errors, continue with local logout
          log('Logout API error (ignored): ${e.toString()}');
        }
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear API client token
      _apiClient.setAuthToken(null);
      
      log('🚪 [logout] All data cleared');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Check current user status from backend
  Future<Map<String, dynamic>?> checkUserStatus() async {
    try {
      log('🔍 [checkUserStatus] Starting status check...');
      
      final token = await getAuthToken();
      
      if (token != null) {
        _apiClient.setAuthToken(token);
        final response = await _apiClient.get('/customer/auth/me');
        
        if (response.success) {
          final data = response.data['data'];
          return {
            'user': data,
            'status': 'active', // Customers are always active
          };
        }
      }
      
      // Fallback: Check status by email (public endpoint)
      final email = await getUserEmail();
      if (email != null) {
        try {
          final response = await _apiClient.post(
            '/customer/auth/check-status',
            body: {'email': email},
          );
          
          if (response.success) {
            final data = response.data['data'];
            return {
              'user': {
                'email': data['email'],
                'name': data['name'],
                'email_verified': data['email_verified'],
              },
              'status': data['status'] ?? 'active',
            };
          }
        } catch (e) {
          log('⚠️ [checkUserStatus] Failed to check status by email: $e');
        }
      }
      
      log('⚠️ [checkUserStatus] Unable to check user status');
      return null;
    } catch (e, stackTrace) {
      log('❌ [checkUserStatus] Exception occurred:');
      log('   Error: $e');
      log('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Login with Google OAuth
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      log('📡 [loginWithGoogle] Sending ID token to backend...');
      log('   Token length: ${idToken.length}');
      log('   Token preview: ${idToken.substring(0, 20)}...');
      
      final response = await _apiClient.post(
        '/auth/google/customer',
        body: {
          'idToken': idToken,
        },
      );

      log('📥 [loginWithGoogle] Backend response received');
      log('   Success: ${response.success}');
      log('   Status code: ${response.statusCode}');

      if (!response.success) {
        String errorMessage = response.error ?? 'Google login failed';
        log('❌ [loginWithGoogle] Backend returned error: $errorMessage');
        throw Exception(errorMessage);
      }

      // Backend returns { success: true, data: { token, refreshToken, user } }
      final responseData = response.data['data'];
      if (responseData == null) {
        log('❌ [loginWithGoogle] No data in response');
        throw Exception('Invalid response format from server');
      }

      final token = responseData['token'];
      final refreshToken = responseData['refreshToken'];
      final user = responseData['user'];

      log('🔍 [loginWithGoogle] Parsing response data...');
      log('   Token: ${token != null ? "✅ Present" : "❌ NULL"}');
      log('   RefreshToken: ${refreshToken != null ? "✅ Present" : "❌ NULL"}');
      log('   User: ${user != null ? "✅ Present" : "❌ NULL"}');

      if (token == null) {
        log('❌ [loginWithGoogle] No access token in response');
        throw Exception('No access token received from server');
      }

      if (user == null) {
        log('❌ [loginWithGoogle] No user data in response');
        throw Exception('No user data received from server');
      }

      log('💾 [loginWithGoogle] Saving auth data...');
      // Save tokens and user data
      await _saveAuthData(
        token: token,
        refreshToken: refreshToken ?? token, // Use refreshToken if available, otherwise use token
        userId: user['id']?.toString() ?? '',
        userEmail: user['email']?.toString() ?? '',
        userName: user['name']?.toString() ?? '',
        userPhone: user['phone']?.toString() ?? '', // Phone might be placeholder for Google users
      );

      log('✅ [loginWithGoogle] Auth data saved successfully');

      // Set token in API client for future requests
      _apiClient.setAuthToken(token);

      log('✅ [loginWithGoogle] Login completed successfully');

      // Get email_verified from response
      final emailVerified = responseData['email_verified'] ?? user['email_verified'] ?? false;
      
      return {
        'success': true,
        'user': {
          ...user,
          'email_verified': emailVerified,
        },
        'token': token,
        'message': 'Login successful',
      };
    } catch (e, stackTrace) {
      log('❌ [loginWithGoogle] Exception occurred: $e');
      log('📚 Stack trace: $stackTrace');
      throw Exception('Google login failed: ${e.toString()}');
    }
  }
}

