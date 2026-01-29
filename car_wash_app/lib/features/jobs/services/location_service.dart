import 'dart:developer';
import '../../../api/api_client.dart';

/// Washer Location Service
/// Handles updating washer's current location to backend
class LocationService {
  final ApiClient _apiClient = ApiClient();

  /// Update washer's current location
  /// 
  /// [latitude] - Current latitude
  /// [longitude] - Current longitude
  /// [heading] - Optional: Direction in degrees (0-360)
  /// [speed] - Optional: Speed in km/h
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      log('📍 [updateLocation] Updating location: $latitude, $longitude');

      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

      if (heading != null) {
        body['heading'] = heading;
      }

      if (speed != null) {
        body['speed'] = speed;
      }

      final response = await _apiClient.put(
        '/washer/location',
        body: body,
      );

      if (!response.success) {
        log('❌ [updateLocation] Failed to update location: ${response.error}');
        return false;
      }

      log('✅ [updateLocation] Location updated successfully');
      return true;
    } catch (e) {
      log('❌ [updateLocation] Error: $e');
      return false;
    }
  }

  /// Get current location from backend
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final response = await _apiClient.get('/washer/location');

      if (!response.success) {
        log('❌ [getCurrentLocation] Failed to get location: ${response.error}');
        return null;
      }

      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      log('❌ [getCurrentLocation] Error: $e');
      return null;
    }
  }
}















