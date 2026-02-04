import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/fcm_token_service.dart';
import '../services/notification_handler_service.dart';

/// FCM Token Controller
/// Manages FCM token lifecycle and synchronization with backend
class FcmTokenController extends GetxController {
  final FcmTokenService _fcmTokenService = FcmTokenService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final RxString fcmToken = ''.obs;
  final RxBool isTokenSaved = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Don't auto-initialize - will be called explicitly from auth flow
  }

  /// Initialize FCM token and save to backend
  /// Call this method after user login/signup
  Future<void> initializeFcmToken() async {
    try {
      isLoading.value = true;

      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        log('⚠️ [FcmTokenController] Notification permission not granted');
        isLoading.value = false;
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      
      if (token != null) {
        fcmToken.value = token;
        log('🔑 [FcmTokenController] FCM Token generated: ${token.substring(0, 20)}...');
        
        // Save token to backend
        await saveTokenToBackend(token);

        // Initialize notification handler after token is saved
        // This ensures handlers are set up to receive notifications
        try {
          final notificationHandler = NotificationHandlerService();
          await notificationHandler.initialize();
          log('✅ [FcmTokenController] Notification handler initialized');
        } catch (e) {
          log('⚠️ [FcmTokenController] Error initializing notification handler: $e');
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          log('🔑 [FcmTokenController] FCM Token refreshed: ${newToken.substring(0, 20)}...');
          fcmToken.value = newToken;
          saveTokenToBackend(newToken);
        });
      } else {
        log('❌ [FcmTokenController] FCM token is null');
      }
    } catch (e) {
      log('❌ [FcmTokenController] Error initializing FCM token: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Save FCM token to backend
  Future<void> saveTokenToBackend(String token) async {
    try {
      String deviceType = _getDeviceType();
      bool success = await _fcmTokenService.saveFcmToken(token, deviceType: deviceType);
      isTokenSaved.value = success;
      
      if (success) {
        log('✅ [FcmTokenController] FCM token saved to backend');
      } else {
        log('❌ [FcmTokenController] Failed to save FCM token to backend');
      }
    } catch (e) {
      log('❌ [FcmTokenController] Error saving token to backend: $e');
      isTokenSaved.value = false;
    }
  }

  /// Get device type
  String _getDeviceType() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  /// Initialize FCM token WITHOUT requesting permission
  /// Use this when permission will be requested separately (e.g., after location permission)
  Future<void> initializeFcmTokenWithoutPermission() async {
    try {
      isLoading.value = true;

      // Check if permission is already granted
      NotificationSettings settings = await _messaging.getNotificationSettings();
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        log('⚠️ [FcmTokenController] Notification permission not granted yet');
        isLoading.value = false;
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      
      if (token != null) {
        fcmToken.value = token;
        log('🔑 [FcmTokenController] FCM Token generated: ${token.substring(0, 20)}...');
        
        // Save token to backend
        await saveTokenToBackend(token);

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          log('🔑 [FcmTokenController] FCM Token refreshed: ${newToken.substring(0, 20)}...');
          fcmToken.value = newToken;
          saveTokenToBackend(newToken);
        });
      } else {
        log('❌ [FcmTokenController] FCM token is null');
      }
    } catch (e) {
      log('❌ [FcmTokenController] Error initializing FCM token: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Manually refresh token
  Future<void> refreshToken() async {
    try {
      isLoading.value = true;
      
      // Check permission status first
      NotificationSettings settings = await _messaging.getNotificationSettings();
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        log('⚠️ [FcmTokenController] Notification permission not granted, requesting...');
        // Request permission if not granted
        settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          log('⚠️ [FcmTokenController] Notification permission denied, cannot refresh token');
          isLoading.value = false;
          return;
        }
      }
      
      String? token = await _messaging.getToken();
      
      if (token != null) {
        fcmToken.value = token;
        log('🔑 [FcmTokenController] Token refreshed: ${token.substring(0, 20)}...');
        await saveTokenToBackend(token);
        
        // Ensure notification handler is initialized after token refresh
        try {
          await NotificationHandlerService().initialize(forceReinitialize: false);
        } catch (e) {
          log('⚠️ [FcmTokenController] Error initializing notification handler after refresh: $e');
        }
      } else {
        log('⚠️ [FcmTokenController] Token is null after refresh attempt');
      }
    } catch (e) {
      log('❌ [FcmTokenController] Error refreshing token: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove token from backend (on logout)
  Future<void> removeToken() async {
    try {
      await _fcmTokenService.removeFcmToken();
      fcmToken.value = '';
      isTokenSaved.value = false;
      log('✅ [FcmTokenController] FCM token removed from backend');
    } catch (e) {
      log('❌ [FcmTokenController] Error removing token: $e');
    }
  }
}

