import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_client.dart';

/// Authentication Service
/// Handles Email Authentication via Backend API
class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Storage Keys
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _washerStatusKey = 'washer_status';
  static const String _accountCreatedKey = 'account_created';
  static const String _emailVerifiedKey = 'email_verified';

  /// Login with email and password
  /// Requires: email_verified=true AND status=active
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/washer/auth/login', // Updated to new endpoint
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
      final washer = data['washer'];

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
        washerStatus: washer['status'],
      );

      // Set token in API client for future requests
      _apiClient.setAuthToken(token);

      return {
        'success': true,
        'user': user,
        'washer': washer,
        'token': token,
        'refreshToken': refreshToken,
        'message': data['message'],
      };
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Register with email and password
  /// After registration: email_verified=false, status=pending
  /// User must verify email via OTP before login
  Future<Map<String, dynamic>> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      final response = await _apiClient.post(
        '/washer/auth/register', // Updated to new endpoint
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
      
      // Save account creation status and pending status to cache
      final status = data['status'] ?? 'pending';
      final emailVerified = data['email_verified'] ?? false;
      await _saveAccountStatus(
        email: data['email'],
        status: status,
        emailVerified: emailVerified,
        accountCreated: true,
      );
      
      // IMPORTANT: Registration no longer returns tokens
      // User must verify email via OTP first
      // Return success message directing to email verification
      return {
        'success': true,
        'email': data['email'],
        'email_verified': emailVerified,
        'status': status,
        'nextStep': data['nextStep'] ?? 'verify_email',
        'message': data['message'] ?? 'Account created. Please verify your email.',
      };
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Request email OTP (4-digit, expires in 5 minutes)
  Future<Map<String, dynamic>> requestEmailOTP(String email) async {
    try {
      final response = await _apiClient.post(
        '/washer/auth/send-email-otp', // Updated to match backend primary route
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
        'email': data['email'],
        'message': data['message'],
        'status': data['status'],
        'otp': data['otp'], // Only in development
      };
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  /// Verify email OTP
  /// If status=pending: Returns message about admin approval (no tokens)
  /// If status=active: Returns tokens for login
  Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    try {
      final response = await _apiClient.post(
        '/washer/auth/verify-email-otp',
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
      
      // Check if account can login (has tokens)
      final token = data['token'];
      final canLogin = data['canLogin'] ?? (token != null);
      
      if (canLogin && token != null) {
        // Account is active - save tokens and login
        final refreshToken = data['refreshToken'];
        final user = data['user'];
        final washer = data['washer'];

        // Save tokens and user data
        await _saveAuthData(
          token: token,
          refreshToken: refreshToken,
          userId: user['id'],
          userEmail: user['email'],
          userName: user['name'],
          washerStatus: washer['status'],
        );

        // Set token in API client for future requests
        _apiClient.setAuthToken(token);

        return {
          'success': true,
          'canLogin': true,
          'user': user,
          'washer': washer,
          'token': token,
          'refreshToken': refreshToken,
          'message': data['message'],
        };
      } else {
        // Account is pending - email verified but waiting for admin approval
        // Save pending status to cache (even without token)
        final status = data['status'] ?? 'pending';
        final normalizedEmail = email.toLowerCase();
        await _saveAccountStatus(
          email: normalizedEmail,
          status: status,
          emailVerified: true,
          accountCreated: true,
        );
        
        return {
          'success': true,
          'canLogin': false,
          'email_verified': data['email_verified'] ?? true,
          'status': status,
          'message': data['message'] ?? 'Email verified. Waiting for admin approval.',
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset (sends 4-digit OTP, expires in 5 minutes)
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '/washer/auth/forgot-password', // Updated to new endpoint
        body: {
          'email': email.toLowerCase(),
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to send reset link';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'message': data['message'],
        'resetCode': data['resetCode'], // Only in development
      };
    } catch (e) {
      throw Exception('Failed to send reset link: ${e.toString()}');
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
        '/washer/auth/reset-password',
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
        'message': data['message'],
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
    String? washerStatus,
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

    if (washerStatus != null) {
      await prefs.setString(_washerStatusKey, washerStatus);
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

  /// Get stored washer status
  Future<String?> getWasherStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_washerStatusKey);
  }

  /// Save account status to cache (for pending accounts without tokens)
  Future<void> _saveAccountStatus({
    required String email,
    required String status,
    required bool emailVerified,
    required bool accountCreated,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_washerStatusKey, status);
    await prefs.setBool(_emailVerifiedKey, emailVerified);
    await prefs.setBool(_accountCreatedKey, accountCreated);
    log('💾 [saveAccountStatus] Saved to cache: email=$email, status=$status, emailVerified=$emailVerified');
  }

  /// Get cached account status (for pending/suspended/active accounts)
  /// Returns status if account was created
  Future<String?> getCachedAccountStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accountCreated = prefs.getBool(_accountCreatedKey) ?? false;
    final emailVerified = prefs.getBool(_emailVerifiedKey) ?? false;
    final status = prefs.getString(_washerStatusKey);
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    // Return cached status if:
    // 1. Account was created
    // 2. Email is verified OR status exists
    // 3. Status is one of: pending, active, suspended
    if (accountCreated && (emailVerified || status != null)) {
      if (status == 'pending' || status == 'active' || status == 'suspended') {
        log('📦 [getCachedAccountStatus] Found cached status: $status');
        return status;
      }
    }
    
    // Also check if logged in and status exists
    if (isLoggedIn && status != null) {
      log('📦 [getCachedAccountStatus] Found cached status from login: $status');
      return status;
    }
    
    log('📦 [getCachedAccountStatus] No cached status found');
    return null;
  }

  /// Check if account exists but is pending (from cache)
  Future<bool> isAccountPending() async {
    final cachedStatus = await getCachedAccountStatus();
    return cachedStatus == 'pending';
  }

  /// Check if account is suspended (from cache)
  Future<bool> isAccountSuspended() async {
    final cachedStatus = await getCachedAccountStatus();
    return cachedStatus == 'suspended';
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final token = await getAuthToken();
      
      // Call logout API if token exists
      if (token != null) {
        try {
          _apiClient.setAuthToken(token);
          await _apiClient.post('/washer/auth/logout');
        } catch (e) {
          // Ignore API errors, continue with local logout
          print('Logout API error (ignored): ${e.toString()}');
        }
      }

      // Clear local storage (including cached account status)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear API client token
      _apiClient.setAuthToken(null);
      
      log('🚪 [logout] All data cleared including cached account status');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Check current user status from backend
  /// Returns user status and data if authenticated
  /// Falls back to email-based check if no token (for pending accounts)
  Future<Map<String, dynamic>?> checkUserStatus() async {
    try {
      log('🔍 [checkUserStatus] Starting status check...');
      
      final token = await getAuthToken();
      final email = await getUserEmail();
      
      // If we have a token, use authenticated endpoint
      if (token != null) {
        // Verify token is set in API client
        _apiClient.setAuthToken(token);

        log('📡 [checkUserStatus] Calling authenticated API: /washer/auth/me');
        final response = await _apiClient.get('/washer/auth/me');

        log('📥 [checkUserStatus] API Response received:');
        log('   Success: ${response.success}');
        log('   Status Code: ${response.statusCode}');
        log('   Response Data: ${response.data}');
        log('   Error: ${response.error}');

        if (response.success) {
          final data = response.data['data'];
          final washer = data['washer'];
          
          log('✅ [checkUserStatus] Parsing response data:');
          log('   Data: $data');
          log('   Washer: $washer');
          log('   Washer Status: ${washer?['status']}');
          
          // Update stored washer status
          if (washer != null && washer['status'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_washerStatusKey, washer['status']);
            log('💾 [checkUserStatus] Updated stored status: ${washer['status']}');
          }

          final result = {
            'status': washer['status'],
            'online_status': washer['online_status'],
            'user': data['user'],
            'washer': washer,
          };
          
          log('✅ [checkUserStatus] Returning result: $result');
          return result;
        } else {
          // If unauthorized, token might be invalid
          if (response.statusCode == 401 || response.statusCode == 403) {
            log('🔒 [checkUserStatus] Unauthorized - will try email-based check');
            // Don't logout yet, try email-based check first
          } else {
            return null;
          }
        }
      }
      
      // Fallback: Check status by email (for pending accounts without tokens)
      if (email != null) {
        log('📧 [checkUserStatus] No token found, checking status by email: $email');
        log('📡 [checkUserStatus] Calling public API: /washer/auth/check-status');
        
        final response = await _apiClient.post(
          '/washer/auth/check-status',
          body: {'email': email},
        );
        
        log('📥 [checkUserStatus] Email-based API Response:');
        log('   Success: ${response.success}');
        log('   Status Code: ${response.statusCode}');
        log('   Response Data: ${response.data}');
        log('   Error: ${response.error}');
        
        if (response.success) {
          final data = response.data['data'];
          final status = data['status'];
          
          log('✅ [checkUserStatus] Status from email check: $status');
          
          // Update stored washer status
          if (status != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_washerStatusKey, status);
            log('💾 [checkUserStatus] Updated stored status: $status');
          }
          
          final result = {
            'status': status,
            'email_verified': data['email_verified'],
            'email': data['email'],
            'name': data['name'],
            'washer': {
              'status': status,
            },
          };
          
          log('✅ [checkUserStatus] Returning result: $result');
          return result;
        } else {
          log('❌ [checkUserStatus] Email-based check failed');
          return null;
        }
      } else {
        log('⚠️ [checkUserStatus] No auth token and no email found');
        return null;
      }
    } catch (e, stackTrace) {
      log('❌ [checkUserStatus] Exception occurred:');
      log('   Error: $e');
      log('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Get full profile data (requires authentication token)
  /// Returns complete user and washer profile information
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      log('🔍 [getProfile] Starting profile fetch...');
      
      final token = await getAuthToken();
      if (token == null) {
        log('⚠️ [getProfile] No auth token found - cannot fetch full profile');
        return null;
      }

      // Set token in API client
      _apiClient.setAuthToken(token);

      log('📡 [getProfile] Calling API: /washer/auth/me');
      final response = await _apiClient.get('/washer/auth/me');

      log('📥 [getProfile] API Response received:');
      log('   Success: ${response.success}');
      log('   Status Code: ${response.statusCode}');
      log('   Response Data: ${response.data}');
      log('   Error: ${response.error}');

      if (!response.success) {
        log('❌ [getProfile] API call failed');
        // If unauthorized, token might be invalid
        if (response.statusCode == 401 || response.statusCode == 403) {
          log('🔒 [getProfile] Unauthorized - clearing invalid token');
          await logout();
        }
        return null;
      }

      final data = response.data['data'];
      final user = data['user'];
      final washer = data['washer'];
      
      log('✅ [getProfile] Parsing response data:');
      log('   User: $user');
      log('   Washer: $washer');
      
      // Update stored washer status
      if (washer != null && washer['status'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_washerStatusKey, washer['status']);
        log('💾 [getProfile] Updated stored status: ${washer['status']}');
      }

      final result = {
        'user': user,
        'washer': washer,
        'status': washer['status'],
        'online_status': washer['online_status'],
      };
      
      log('✅ [getProfile] Returning result');
      return result;
    } catch (e, stackTrace) {
      log('❌ [getProfile] Exception occurred:');
      log('   Error: $e');
      log('   Stack Trace: $stackTrace');
      return null;
    }
  }
}
