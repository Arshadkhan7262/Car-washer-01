import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';

/// Global Notification Handler Service
/// Handles Firebase Cloud Messaging notifications throughout the app
class NotificationHandlerService {
  static final NotificationHandlerService _instance = NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  bool _initialized = false;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  NotificationController? get _notificationController {
    if (Get.isRegistered<NotificationController>()) {
      return Get.find<NotificationController>();
    }
    return null;
  }

  /// Initialize notification handlers
  Future<void> initialize() async {
    if (_initialized) {
      log('📱 [NotificationHandler] Already initialized');
      return;
    }

    try {
      log('📱 [NotificationHandler] Initializing notification handlers...');

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

      log('📱 [NotificationHandler] Permission status: ${settings.authorizationStatus}');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('📱 [NotificationHandler] Foreground notification received');
        log('📱 Title: ${message.notification?.title}');
        log('📱 Body: ${message.notification?.body}');
        log('📱 Data: ${message.data}');

        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? 'You have a new message';
        
        // Add to notification controller
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: message.data,
        );

        _showNotification(title, body);
      });

      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 [NotificationHandler] App opened from notification');
        final title = initialMessage.notification?.title ?? 'New Notification';
        final body = initialMessage.notification?.body ?? 'You have a new message';
        
        // Add to notification controller
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: initialMessage.data,
        );

        _showNotification(title, body);
      }

      // Handle notification when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('📱 [NotificationHandler] App opened from background notification');
        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? 'You have a new message';
        
        // Add to notification controller
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: message.data,
        );

        _showNotification(title, body);
      });

      _initialized = true;
      log('✅ [NotificationHandler] Notification handlers initialized');
    } catch (e) {
      log('❌ [NotificationHandler] Error initializing: $e');
    }
  }

  /// Show notification using GetX snackbar
  void _showNotification(String title, String body) {
    try {
      // Use GetX snackbar if available
      if (Get.isRegistered<GetMaterialController>()) {
        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          colorText: Get.theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          duration: const Duration(seconds: 4),
          icon: Icon(
            Icons.notifications_active,
            color: Get.theme.primaryColor,
          ),
          shouldIconPulse: true,
        );
      } else {
        // Fallback: just log if GetX is not ready
        log('📱 [NotificationHandler] GetX not ready, notification: $title - $body');
      }
    } catch (e) {
      log('❌ [NotificationHandler] Error showing notification: $e');
    }
  }
}

