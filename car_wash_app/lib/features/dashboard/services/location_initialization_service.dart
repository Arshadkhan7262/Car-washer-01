import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../../jobs/services/location_tracker.dart';

/// Location Initialization Service
/// Handles location permission request and service enablement when account is approved
class LocationInitializationService {
  final LocationTracker _locationTracker = LocationTracker();
  bool _hasInitialized = false;

  /// Initialize location tracking when account is approved
  /// This is called when status changes from pending to active
  Future<bool> initializeLocationTracking() async {
    if (_hasInitialized) {
      log('📍 [LocationInit] Already initialized');
      return true;
    }

    try {
      log('📍 [LocationInit] Starting location initialization...');

      // Step 1: Check and request location permission
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        log('❌ [LocationInit] Location permission denied');
        _showPermissionDeniedDialog();
        return false;
      }

      // Step 2: Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ [LocationInit] Location services are disabled');
        final enabled = await _requestEnableLocationServices();
        if (!enabled) {
          log('❌ [LocationInit] User did not enable location services');
          _showLocationServiceDisabledDialog();
          return false;
        }
      }

      // Step 3: Start location tracking
      final started = await _locationTracker.startTracking(
        updateInterval: const Duration(seconds: 3),
        distanceFilter: 5,
      );

      if (started) {
        _hasInitialized = true;
        log('✅ [LocationInit] Location tracking started successfully');
        Get.snackbar(
          'Location Tracking',
          'Your location is now being shared',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        log('❌ [LocationInit] Failed to start location tracking');
        return false;
      }
    } catch (e) {
      log('❌ [LocationInit] Error: $e');
      return false;
    }
  }

  /// Request location permission
  Future<bool> _requestLocationPermission() async {
    try {
      var status = await Permission.location.status;

      if (status.isGranted) {
        log('✅ [LocationInit] Location permission already granted');
        return true;
      }

      if (status.isDenied) {
        log('📍 [LocationInit] Requesting location permission...');
        status = await Permission.location.request();
        
        if (status.isGranted) {
          log('✅ [LocationInit] Location permission granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          log('❌ [LocationInit] Location permission permanently denied');
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        log('❌ [LocationInit] Location permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      log('❌ [LocationInit] Error checking permission: $e');
      return false;
    }
  }

  /// Request to enable location services (opens system settings)
  Future<bool> _requestEnableLocationServices() async {
    try {
      // Check current status
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        return true;
      }

      // Show dialog to enable location services
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text(
            'Location services are disabled. Please enable location services in your device settings to share your location with customers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Open location settings
                await Geolocator.openLocationSettings();
                Get.back(result: true);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result == true) {
        // Wait a bit for user to enable location
        await Future.delayed(const Duration(seconds: 2));
        
        // Check again if location is enabled
        final enabled = await Geolocator.isLocationServiceEnabled();
        return enabled;
      }

      return false;
    } catch (e) {
      log('❌ [LocationInit] Error requesting location services: $e');
      return false;
    }
  }

  /// Show dialog when permission is denied
  void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is required to share your location with customers. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Get.back();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show dialog when location services are disabled
  void _showLocationServiceDisabledDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable location services in your device settings to share your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Get.back();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Reset initialization flag (for testing or re-initialization)
  void reset() {
    _hasInitialized = false;
  }
}

