import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // Google Maps API Key
  static const String _googleApiKey = 'AIzaSyDQTjH85etAVOY56-3AZ3oydpI3414ZsMU';
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      print('📍 [LocationService] Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ [LocationService] Location services are disabled');
        throw Exception('Location services are disabled. Please enable location services.');
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      print('📍 [LocationService] Permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        // Request permission
        print('📍 [LocationService] Requesting permission...');
        permission = await requestPermission();
        print('📍 [LocationService] Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ [LocationService] Location permissions are denied');
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ [LocationService] Location permissions are permanently denied');
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // Get current position with more lenient settings
      print('📍 [LocationService] Requesting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for better compatibility
        timeLimit: const Duration(seconds: 15), // Increased timeout from 10 to 15 seconds
      );

      print('✅ [LocationService] Position obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e, stackTrace) {
      print('❌ [LocationService] Error getting location: $e');
      print('❌ [LocationService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get place name from coordinates using Google Geocoding API
  /// Returns place name (city/locality) or null if not found
  Future<String?> getPlaceNameFromCoordinates(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_geocodingBaseUrl?latlng=$latitude,$longitude&key=$_googleApiKey'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Get the first result (most accurate)
          final result = data['results'][0];
          final components = result['address_components'] as List?;
          
          print('📍 [LocationService] Geocoding API response OK, components count: ${components?.length ?? 0}');
          
          if (components != null && components.isNotEmpty) {
            // Priority order for place name:
            // 1. Route (street name) - PRIMARY
            // 2. Sub-locality (neighborhood) - SECONDARY
            // 3. Locality (city name) - FALLBACK
            // 4. Administrative Area Level 1 (state/province) - LAST RESORT
            // 5. Administrative Area Level 2 (county) - LAST RESORT
            
            String? placeName;
            
            // Try to get route (street name) FIRST
            for (var component in components) {
              final types = component['types'] as List?;
              if (types != null && types.contains('route')) {
                placeName = component['long_name'] as String? ?? component['short_name'] as String?;
                print('📍 [LocationService] Found route (street): $placeName');
                break;
              }
            }
            
            // If no route, try sub-locality (neighborhood)
            if (placeName == null || placeName.isEmpty) {
              for (var component in components) {
                final types = component['types'] as List?;
                if (types != null && types.contains('sublocality')) {
                  placeName = component['long_name'] as String? ?? component['short_name'] as String?;
                  print('📍 [LocationService] Found sub-locality (neighborhood): $placeName');
                  break;
                }
              }
            }
            
            // If still no place name, try locality (city) as fallback
            if (placeName == null || placeName.isEmpty) {
              for (var component in components) {
                final types = component['types'] as List?;
                if (types != null && types.contains('locality')) {
                  placeName = component['long_name'] as String? ?? component['short_name'] as String?;
                  print('📍 [LocationService] Found locality (city): $placeName');
                  break;
                }
              }
            }
            
            // If still no place name, try administrative area level 1 (state/province)
            if (placeName == null || placeName.isEmpty) {
              for (var component in components) {
                final types = component['types'] as List?;
                if (types != null && types.contains('administrative_area_level_1')) {
                  placeName = component['long_name'] as String? ?? component['short_name'] as String?;
                  print('📍 [LocationService] Found admin area level 1: $placeName');
                  break;
                }
              }
            }
            
            // Last resort: try administrative area level 2 (county)
            if (placeName == null || placeName.isEmpty) {
              for (var component in components) {
                final types = component['types'] as List?;
                if (types != null && types.contains('administrative_area_level_2')) {
                  placeName = component['long_name'] as String? ?? component['short_name'] as String?;
                  print('📍 [LocationService] Found admin area level 2: $placeName');
                  break;
                }
              }
            }
            
            if (placeName == null || placeName.isEmpty) {
              print('📍 [LocationService] No place name found in components');
            }
            
            return placeName != null && placeName.isNotEmpty ? placeName : null;
          }
          return null; // No components found
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('📍 [LocationService] Geocoding API returned ZERO_RESULTS');
          return null;
        } else {
          print('❌ [LocationService] Geocoding API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('❌ [LocationService] Error message: ${data['error_message']}');
          }
          return null;
        }
      } else {
        print('❌ [LocationService] HTTP error: ${response.statusCode}');
        print('❌ [LocationService] Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [LocationService] Error getting place name from coordinates: $e');
      print('❌ [LocationService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get current location place name
  /// Returns place name (city/locality) or null if not found
  Future<String?> getCurrentLocationPlaceName() async {
    try {
      print('📍 [LocationService] Getting current position...');
      Position? position = await getCurrentPosition();
      
      if (position != null) {
        print('📍 [LocationService] Position: ${position.latitude}, ${position.longitude}');
        String? placeName = await getPlaceNameFromCoordinates(position.latitude, position.longitude);
        print('📍 [LocationService] Place name: $placeName');
        return placeName;
      }
      print('❌ [LocationService] No position available - getCurrentPosition() returned null');
      return null;
    } catch (e, stackTrace) {
      print('❌ [LocationService] Error getting current location place name: $e');
      print('❌ [LocationService] Stack trace: $stackTrace');
      return null;
    }
  }
}

