import 'dart:developer';
import 'dart:math' as math;
import '../../../api/api_client.dart';

/// Washer Location Service
/// Handles fetching washer location for bookings
class WasherLocationService {
  final ApiClient _apiClient = ApiClient();

  /// Get washer location for a booking
  /// Returns null if washer is not assigned or location is not available
  Future<Map<String, dynamic>?> getWasherLocation(String bookingId) async {
    try {
      log('📍 [getWasherLocation] Fetching washer location for booking: $bookingId');
      
      // URL encode the booking ID to handle special characters
      final encodedBookingId = Uri.encodeComponent(bookingId);
      final response = await _apiClient.get('/customer/bookings/$encodedBookingId/washer-location');

      if (!response.success) {
        log('❌ [getWasherLocation] API returned error: ${response.error}');
        
        // If location is not available, return null (not an error)
        if (response.statusCode != null && response.statusCode == 200 && response.data['data'] == null) {
          log('ℹ️ [getWasherLocation] Washer location not available');
          return null;
        }
        
        throw Exception(response.error ?? 'Failed to get washer location');
      }

      final locationData = response.data['data'] as Map<String, dynamic>?;
      
      if (locationData == null) {
        log('ℹ️ [getWasherLocation] Washer location not available');
        return null;
      }

      log('✅ [getWasherLocation] Retrieved washer location: ${locationData['latitude']}, ${locationData['longitude']}');
      return locationData;
    } catch (e) {
      log('❌ [getWasherLocation] Error: $e');
      // Return null instead of throwing - location might not be available yet
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Uses Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Calculate estimated time of arrival in minutes
  /// Based on distance and average speed (default 30 km/h in city)
  static int calculateETA(double distanceKm, {double averageSpeedKmh = 30}) {
    if (distanceKm <= 0 || averageSpeedKmh <= 0) return 0;
    return (distanceKm / averageSpeedKmh * 60).round();
  }
}

