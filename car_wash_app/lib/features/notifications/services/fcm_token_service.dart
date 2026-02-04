import 'dart:developer';
import '../../../api/api_client.dart';

/// FCM Token Service
/// Handles FCM token registration and updates for washer app
class FcmTokenService {
  final ApiClient _apiClient = ApiClient();

  /// Save or update FCM token for the current washer
  Future<bool> saveFcmToken(String token, {String? deviceType}) async {
    try {
      log('📱 [FcmTokenService] Saving FCM token to backend...');
      log('📱 [FcmTokenService] Token: ${token.substring(0, 20)}...');

      final response = await _apiClient.post(
        '/washer/notifications/fcm-token',
        body: {
          'token': token,
          'device_type': deviceType ?? 'android',
        },
      );

      if (!response.success) {
        log('❌ [FcmTokenService] Failed to save FCM token: ${response.error}');
        return false;
      }

      log('✅ [FcmTokenService] FCM token saved successfully');
      return true;
    } catch (e) {
      log('❌ [FcmTokenService] Error saving FCM token: $e');
      return false;
    }
  }

  /// Update FCM token (same as save, but semantically different)
  Future<bool> updateFcmToken(String token, {String? deviceType}) async {
    return await saveFcmToken(token, deviceType: deviceType);
  }

  /// Remove FCM token (when washer logs out)
  Future<bool> removeFcmToken() async {
    try {
      log('📱 [FcmTokenService] Removing FCM token from backend...');

      final response = await _apiClient.delete(
        '/washer/notifications/fcm-token',
      );

      if (!response.success) {
        log('❌ [FcmTokenService] Failed to remove FCM token: ${response.error}');
        return false;
      }

      log('✅ [FcmTokenService] FCM token removed successfully');
      return true;
    } catch (e) {
      log('❌ [FcmTokenService] Error removing FCM token: $e');
      return false;
    }
  }
}
