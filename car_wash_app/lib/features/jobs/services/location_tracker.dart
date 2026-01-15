import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_service.dart';

/// Location Tracker
/// Manages continuous location tracking and updates to backend
class LocationTracker {
  final LocationService _locationService = LocationService();
  
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  bool _isTracking = false;
  Position? _lastPosition;
  
  /// Callback for location updates (optional)
  Function(Position)? onLocationUpdate;
  
  /// Start tracking location and updating to backend
  /// 
  /// [updateInterval] - How often to update backend (default: 10 seconds)
  /// [distanceFilter] - Minimum distance in meters to trigger update (default: 10 meters)
  Future<bool> startTracking({
    Duration updateInterval = const Duration(seconds: 10),
    int distanceFilter = 10,
  }) async {
    if (_isTracking) {
      log('⚠️ [LocationTracker] Already tracking location');
      return true;
    }

    try {
      // Check and request location permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        log('❌ [LocationTracker] Location permission denied');
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ [LocationTracker] Location services are disabled');
        return false;
      }

      // Configure location settings
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters for more frequent updates
      );

      // Start listening to position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastPosition = position;
          onLocationUpdate?.call(position);
          _updateLocationToBackend(position);
        },
        onError: (error) {
          log('❌ [LocationTracker] Position stream error: $error');
        },
      );

      // Also set up a timer to ensure updates even if position doesn't change
      _updateTimer = Timer.periodic(updateInterval, (timer) {
        if (_lastPosition != null) {
          _updateLocationToBackend(_lastPosition!);
        }
      });

      _isTracking = true;
      log('✅ [LocationTracker] Started tracking location');
      return true;
    } catch (e) {
      log('❌ [LocationTracker] Error starting tracking: $e');
      return false;
    }
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    await _positionStream?.cancel();
    _updateTimer?.cancel();
    _positionStream = null;
    _updateTimer = null;
    _isTracking = false;
    _lastPosition = null;
    
    log('🛑 [LocationTracker] Stopped tracking location');
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  /// Update location to backend
  Future<void> _updateLocationToBackend(Position position) async {
    try {
      // Calculate heading if available
      double? heading;
      if (position.heading >= 0) {
        heading = position.heading;
      }

      // Calculate speed in km/h
      double? speed;
      if (position.speed >= 0) {
        speed = position.speed * 3.6; // Convert m/s to km/h
      }

      await _locationService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: heading,
        speed: speed,
      );
    } catch (e) {
      log('❌ [LocationTracker] Error updating location to backend: $e');
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    // Check permission status
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Request permission
      status = await Permission.location.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      log('⚠️ [LocationTracker] Location permission permanently denied');
      // Optionally open app settings
      // await openAppSettings();
    }

    return false;
  }

  /// Get current position once (for immediate location)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      log('❌ [LocationTracker] Error getting current position: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}


