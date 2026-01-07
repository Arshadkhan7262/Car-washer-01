import 'dart:developer';
import '../../../api/api_client.dart';

class BookingService {
  final ApiClient _apiClient = ApiClient();

  /// Create booking (confirm booking)
  Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    String? vehicleTypeId,
    String? vehicleId, // Customer's saved vehicle ID
    required String vehicleTypeName,
    required DateTime bookingDate,
    required String timeSlot,
    required String address,
    double? addressLatitude,
    double? addressLongitude,
    String? addressId, // Customer's saved address ID
    String? additionalLocation,
    required String paymentMethod,
    String? couponCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/bookings',
        body: {
          'service_id': serviceId,
          if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
          if (vehicleId != null) 'vehicle_id': vehicleId,
          'vehicle_type_name': vehicleTypeName,
          'booking_date': bookingDate.toIso8601String().split('T')[0],
          'time_slot': timeSlot,
          'address': address,
          if (addressLatitude != null) 'address_latitude': addressLatitude,
          if (addressLongitude != null) 'address_longitude': addressLongitude,
          if (addressId != null) 'address_id': addressId,
          if (additionalLocation != null) 'additional_location': additionalLocation,
          'payment_method': paymentMethod,
          if (couponCode != null) 'coupon_code': couponCode,
        },
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to create booking');
      }

      final bookingData = response.data['data'] as Map<String, dynamic>;
      log('✅ [createBooking] Booking created: ${bookingData['booking_id']}');
      return bookingData;
    } catch (e) {
      log('❌ [createBooking] Error: $e');
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Get customer bookings
  Future<List<dynamic>> getCustomerBookings({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        '/customer/bookings',
        queryParameters: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to get bookings');
      }

      final bookingsData = response.data['data']['bookings'] as List<dynamic>;
      log('✅ [getCustomerBookings] Retrieved ${bookingsData.length} bookings');
      return bookingsData;
    } catch (e) {
      log('❌ [getCustomerBookings] Error: $e');
      throw Exception('Failed to get bookings: ${e.toString()}');
    }
  }

  /// Track booking by ID with retry logic
  Future<Map<String, dynamic>> trackBooking(String bookingId, {int maxRetries = 2}) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        log('📍 [trackBooking] Attempt ${attempt + 1}/${maxRetries + 1} - Tracking booking: $bookingId');
        
        // URL encode the booking ID to handle special characters
        final encodedBookingId = Uri.encodeComponent(bookingId);
        final response = await _apiClient.get('/customer/bookings/$encodedBookingId/track');

        if (!response.success) {
          log('❌ [trackBooking] API returned error: ${response.error}');
          
          // Don't retry on client errors (4xx)
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            throw Exception(response.error ?? 'Failed to track booking');
          }
          
          // Retry on server errors (5xx) or network issues
          if (attempt < maxRetries) {
            attempt++;
            await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
            continue;
          }
          
          throw Exception(response.error ?? 'Failed to track booking');
        }

        final trackingData = response.data['data'] as Map<String, dynamic>;
        log('✅ [trackBooking] Retrieved tracking data for booking: $bookingId');
        return trackingData;
      } catch (e) {
        log('❌ [trackBooking] Error on attempt ${attempt + 1}: $e');
        
        // Retry on timeout or network errors
        if (attempt < maxRetries && 
            (e.toString().contains('TimeoutException') || 
             e.toString().contains('SocketException') ||
             e.toString().contains('Failed host lookup'))) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
          continue;
        }
        
        // Provide more specific error messages
        String errorMessage = 'Failed to track booking';
        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
        } else if (e.toString().contains('404') || e.toString().contains('not found')) {
          errorMessage = 'Booking not found.';
        } else if (e.toString().contains('403') || e.toString().contains('permission')) {
          errorMessage = 'You do not have permission to view this booking.';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        throw Exception(errorMessage);
      }
    }
    
    throw Exception('Failed to track booking after ${maxRetries + 1} attempts');
  }

  /// Get customer booking by ID
  Future<Map<String, dynamic>> getCustomerBookingById(String bookingId) async {
    try {
      final response = await _apiClient.get('/customer/bookings/$bookingId');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to get booking');
      }

      final bookingData = response.data['data'] as Map<String, dynamic>;
      log('✅ [getCustomerBookingById] Retrieved booking: $bookingId');
      return bookingData;
    } catch (e) {
      log('❌ [getCustomerBookingById] Error: $e');
      throw Exception('Failed to get booking: ${e.toString()}');
    }
  }
}

