import 'dart:developer';
import '../../../api/api_client.dart';

/// Profile Service
/// Handles Customer Profile data, stats, and preferences via Backend API
class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Get customer profile with stats and preferences
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.get('/customer/profile');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to fetch profile';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'user': data['user'],
        'stats': data['stats'],
        'preferences': data['preferences'],
      };
    } catch (e) {
      log('❌ [getProfile] Error: $e');
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Get customer stats only
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get('/customer/profile/stats');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to fetch stats';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'total_washes': data['total_washes'] ?? 0,
        'total_spent': (data['total_spent'] ?? 0).toDouble(),
        'wallet_balance': (data['wallet_balance'] ?? 0).toDouble(),
      };
    } catch (e) {
      log('❌ [getStats] Error: $e');
      throw Exception('Failed to fetch stats: ${e.toString()}');
    }
  }

  /// Get customer preferences only
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _apiClient.get('/customer/profile/preferences');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to fetch preferences';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'push_notification_enabled': data['push_notification_enabled'] ?? false,
        'two_factor_auth_enabled': data['two_factor_auth_enabled'] ?? false,
      };
    } catch (e) {
      log('❌ [getPreferences] Error: $e');
      throw Exception('Failed to fetch preferences: ${e.toString()}');
    }
  }

  /// Update customer profile (name, phone, email)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final response = await _apiClient.put(
        '/customer/profile',
        body: body,
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to update profile';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'user': data['user'],
        'stats': data['stats'],
        'preferences': data['preferences'],
        'message': response.data['message'] ?? 'Profile updated successfully',
      };
    } catch (e) {
      log('❌ [updateProfile] Error: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update customer preferences
  Future<Map<String, dynamic>> updatePreferences({
    bool? pushNotificationEnabled,
    bool? twoFactorAuthEnabled,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (pushNotificationEnabled != null) {
        body['push_notification_enabled'] = pushNotificationEnabled;
      }
      if (twoFactorAuthEnabled != null) {
        body['two_factor_auth_enabled'] = twoFactorAuthEnabled;
      }

      final response = await _apiClient.put(
        '/customer/profile/preferences',
        body: body,
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to update preferences';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'push_notification_enabled': data['push_notification_enabled'] ?? false,
        'two_factor_auth_enabled': data['two_factor_auth_enabled'] ?? false,
        'message': response.data['message'] ?? 'Preferences updated successfully',
      };
    } catch (e) {
      log('❌ [updatePreferences] Error: $e');
      throw Exception('Failed to update preferences: ${e.toString()}');
    }
  }
}




