import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show EdgeInsets;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../screens/track_order_screen.dart';
import '../controllers/notification_controller.dart';

/// Callback type for booking status updates
typedef BookingStatusCallback = void Function(String bookingId, Map<String, dynamic> data);

/// Global Notification Handler Service
/// Handles Firebase Cloud Messaging notifications throughout the app
class NotificationHandlerService {
  static final NotificationHandlerService _instance = NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  bool _initialized = false;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Map of booking_id -> callback functions
  final Map<String, List<BookingStatusCallback>> _bookingCallbacks = {};
  
  NotificationController? get _notificationController {
    if (Get.isRegistered<NotificationController>()) {
      return Get.find<NotificationController>();
    }
    return null;
  }

  /// Register a callback for booking status updates
  void registerBookingCallback(String bookingId, BookingStatusCallback callback) {
    _bookingCallbacks.putIfAbsent(bookingId, () => []).add(callback);
    log('📱 [NotificationHandler] Registered callback for booking: $bookingId');
  }

  /// Unregister a callback for booking status updates
  void unregisterBookingCallback(String bookingId, BookingStatusCallback callback) {
    _bookingCallbacks[bookingId]?.remove(callback);
    if (_bookingCallbacks[bookingId]?.isEmpty ?? false) {
      _bookingCallbacks.remove(bookingId);
    }
    log('📱 [NotificationHandler] Unregistered callback for booking: $bookingId');
  }

  /// Store pending navigation data for when app opens
  Future<void> _storePendingNavigation(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingId = data['booking_id']?.toString();
      if (bookingId != null && bookingId.isNotEmpty) {
        await prefs.setString('pending_navigation_booking_id', bookingId);
        await prefs.setString('pending_navigation_screen', data['screen']?.toString() ?? 'track_order');
        log('📱 [NotificationHandler] Stored pending navigation for booking: $bookingId');
      }
    } catch (e) {
      log('❌ [NotificationHandler] Error storing pending navigation: $e');
    }
  }

  /// Handle navigation based on notification data
  Future<void> _handleNotificationNavigation(Map<String, dynamic> data, {bool delayNavigation = false}) async {
    try {
      final screen = data['screen']?.toString();
      final action = data['action']?.toString();
      final bookingId = data['booking_id']?.toString();
      final notificationType = data['type']?.toString();

      log('📱 [NotificationHandler] Navigation request - bookingId: $bookingId, type: $notificationType, action: $action, screen: $screen');

      // Navigate if we have a booking_id and it's a booking_status notification
      // Don't require action to be 'navigate' - if it's booking_status, navigate anyway
      if (bookingId != null && bookingId.isNotEmpty) {
        // Check if this is a booking status notification
        final isBookingStatus = notificationType == 'booking_status' || 
                                screen == 'track_order' ||
                                action == 'navigate';

        if (isBookingStatus) {
          log('📱 [NotificationHandler] Processing navigation for booking: $bookingId');

          // If delayNavigation is true, wait a bit for app to fully initialize
          if (delayNavigation) {
            log('📱 [NotificationHandler] Delaying navigation for app initialization...');
            await Future.delayed(const Duration(milliseconds: 1500));
          }

          // Wait a bit more to ensure GetX context is ready
          await Future.delayed(const Duration(milliseconds: 500));

          // Check if GetX context is available
          if (Get.context != null) {
            // Clear any pending navigation
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('pending_navigation_booking_id');
            await prefs.remove('pending_navigation_screen');
            
            // Navigate to track order screen
            log('📱 [NotificationHandler] Navigating to TrackOrderScreen for booking: $bookingId');
            Get.to(() => TrackerOrderScreen(bookingId: bookingId));
            log('✅ [NotificationHandler] Successfully navigated to TrackOrderScreen');
          } else {
            log('⚠️ [NotificationHandler] GetX context not available, storing for later navigation');
            await _storePendingNavigation(data);
            
            // Try again after a delay
            Future.delayed(const Duration(milliseconds: 2000), () async {
              if (Get.context != null) {
                final prefs = await SharedPreferences.getInstance();
                final storedBookingId = prefs.getString('pending_navigation_booking_id');
                if (storedBookingId == bookingId) {
                  await prefs.remove('pending_navigation_booking_id');
                  await prefs.remove('pending_navigation_screen');
                  Get.to(() => TrackerOrderScreen(bookingId: bookingId));
                  log('✅ [NotificationHandler] Navigated after retry');
                }
              }
            });
          }
        } else {
          log('⚠️ [NotificationHandler] Not a booking status notification, skipping navigation');
        }
      } else {
        log('⚠️ [NotificationHandler] No booking_id found in notification data');
      }
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error handling navigation: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
    }
  }

  /// Check and handle any pending navigation from background state
  Future<void> checkPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingId = prefs.getString('pending_navigation_booking_id');
      
      if (bookingId != null && bookingId.isNotEmpty) {
        log('📱 [NotificationHandler] Found pending navigation for booking: $bookingId');
        
        // Wait for GetX to be ready (short delay to avoid blocking UI at startup)
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Retry logic - check multiple times
        int retries = 0;
        while (retries < 5 && Get.context == null) {
          await Future.delayed(const Duration(milliseconds: 500));
          retries++;
        }
        
        if (Get.context != null) {
          // Clear pending navigation
          await prefs.remove('pending_navigation_booking_id');
          await prefs.remove('pending_navigation_screen');
          
          // Navigate
          Get.to(() => TrackerOrderScreen(bookingId: bookingId));
          log('✅ [NotificationHandler] Handled pending navigation to TrackOrderScreen for booking: $bookingId');
        } else {
          log('⚠️ [NotificationHandler] GetX context still not available after retries');
        }
      }
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error checking pending navigation: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
    }
  }

  /// Process notification and trigger callbacks if it's a booking status update
  void _processBookingNotification(RemoteMessage message) {
    final data = message.data;
    final bookingId = data['booking_id']?.toString();
    final notificationType = data['type']?.toString();

    // Check if this is a booking status notification
    if (bookingId != null && notificationType == 'booking_status') {
      log('📱 [NotificationHandler] Booking status notification for: $bookingId');
      
      // Trigger all callbacks registered for this booking
      final callbacks = _bookingCallbacks[bookingId];
      if (callbacks != null && callbacks.isNotEmpty) {
        log('📱 [NotificationHandler] Triggering ${callbacks.length} callback(s)');
        for (final callback in callbacks) {
          try {
            callback(bookingId, data);
          } catch (e) {
            log('❌ [NotificationHandler] Error in booking callback: $e');
          }
        }
      } else {
        log('⚠️ [NotificationHandler] No callbacks registered for booking: $bookingId');
      }
    }
  }

  /// Initialize notification handlers
  Future<void> initialize({bool forceReinitialize = false}) async {
    if (_initialized && !forceReinitialize) {
      log('📱 [NotificationHandler] Already initialized - checking status...');
      
      // Verify listeners are still active
      try {
        final token = await _messaging.getToken();
        final settings = await _messaging.getNotificationSettings();
        log('📱 [NotificationHandler] Current FCM token: ${token != null ? token.substring(0, 30) + "..." : "NULL"}');
        log('📱 [NotificationHandler] Permission: ${settings.authorizationStatus}');
        log('📱 [NotificationHandler] Listeners should be active - if notifications not received, check token match');
      } catch (e) {
        log('⚠️ [NotificationHandler] Error checking status: $e');
      }
      return;
    }

    try {
      log('📱 [NotificationHandler] ==========================================');
      log('📱 [NotificationHandler] Initializing notification handlers...');
      await Future.delayed(Duration.zero); // yield to UI thread

      // Check current permission status (don't request again - FCM token controller handles that)
      NotificationSettings settings = await _messaging.getNotificationSettings();
      log('📱 [NotificationHandler] Permission status: ${settings.authorizationStatus}');
      await Future.delayed(Duration.zero); // yield

      // Get and log current FCM token for verification
      try {
        final token = await _messaging.getToken();
        log('📱 [NotificationHandler] Current app FCM token: ${token != null ? token.substring(0, 30) + "..." : "NULL"}');
        log('📱 [NotificationHandler] ⚠️ IMPORTANT: Verify this token matches database token!');
      } catch (e) {
        log('⚠️ [NotificationHandler] Error getting token: $e');
      }
      await Future.delayed(Duration.zero); // yield

      // If permission not granted, request it (required for Android 13+ and to show in tray)
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        log('⚠️ [NotificationHandler] Permission not granted, requesting...');
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
          log('⚠️ [NotificationHandler] Notification permission denied. Status: ${settings.authorizationStatus}');
          debugPrint('⚠️ [Notification] Permission denied - enable in Settings → Apps → Wash Away → Notifications');
          _initialized = false;
          return;
        }
        log('✅ [NotificationHandler] Permission granted after request');
      } else {
        log('✅ [NotificationHandler] Permission granted: ${settings.authorizationStatus}');
      }
      await Future.delayed(Duration.zero); // yield

      // Reset initialized flag if force reinitialize
      if (forceReinitialize) {
        _initialized = false;
      }

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();
      await Future.delayed(Duration.zero); // yield

      // Listen for foreground messages
      // Show system notification using flutter_local_notifications
      log('📱 [NotificationHandler] Registering onMessage listener...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        log('📱 [NotificationHandler] ==========================================');
        log('📱 [NotificationHandler] ✅✅✅ FOREGROUND NOTIFICATION RECEIVED ✅✅✅');
        debugPrint('📱 [Notification] FOREGROUND RECEIVED: ${message.notification?.title ?? message.data['title']}');
        log('📱 [NotificationHandler] Message ID: ${message.messageId}');
        log('📱 [NotificationHandler] Has notification: ${message.notification != null}');
        log('📱 [NotificationHandler] Title: ${message.notification?.title}');
        log('📱 [NotificationHandler] Body: ${message.notification?.body}');
        log('📱 [NotificationHandler] Data: ${message.data}');
        log('📱 [NotificationHandler] ==========================================');

        // Extract title and body from notification or data payload
        String title = message.notification?.title ?? 
                      message.data['title'] ?? 
                      _getTitleFromStatus(message.data['status']?.toString() ?? '') ??
                      'New Notification';
        
        String body = message.notification?.body ?? 
                     message.data['body'] ?? 
                     _getBodyFromStatus(message.data['status']?.toString() ?? '') ??
                     'You have a new message';
        
        log('📱 [NotificationHandler] Using title: $title, body: $body');
        
        // Process booking status notifications (for callbacks)
        _processBookingNotification(message);
        
        // Add to notification controller (for notification list / in-app screen)
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: message.data,
        );

        // Show in-app snackbar so user always sees something when app is open
        try {
          if (Get.isSnackbarOpen) Get.closeAllSnackbars();
          Get.snackbar(
            title,
            body,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(12),
          );
        } catch (_) {}

        // Show system notification in tray (foreground)
        try {
          await _showSystemNotification(title, body, message.data);
          log('✅ [NotificationHandler] System notification displayed');
          debugPrint('✅ [Notification] Shown in tray: $title');
        } catch (e) {
          log('❌ [NotificationHandler] Failed to show system notification: $e');
          debugPrint('❌ [Notification] Tray show failed: $e');
        }

        // Store navigation data - navigation will happen when user taps the notification
        _storePendingNavigation(message.data);
      });

      // Handle notification when app is opened from terminated state
      log('📱 [NotificationHandler] Checking for initial message (terminated state)...');
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 [NotificationHandler] ==========================================');
        log('📱 [NotificationHandler] ✅✅✅ APP OPENED FROM TERMINATED STATE ✅✅✅');
        log('📱 [NotificationHandler] Message ID: ${initialMessage.messageId}');
        log('📱 [NotificationHandler] Title: ${initialMessage.notification?.title}');
        log('📱 [NotificationHandler] Body: ${initialMessage.notification?.body}');
        log('📱 [NotificationHandler] Data: ${initialMessage.data}');
        log('📱 [NotificationHandler] ==========================================');
        
        final title = initialMessage.notification?.title ?? initialMessage.data['title'] ?? 'New Notification';
        final body = initialMessage.notification?.body ?? initialMessage.data['body'] ?? 'You have a new message';
        
        // Process booking status notifications
        _processBookingNotification(initialMessage);
        
        // Add to notification controller
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: initialMessage.data,
        );

        // Navigate when app opens from notification (with delay to ensure app is ready)
        await _handleNotificationNavigation(initialMessage.data, delayNavigation: true);
      } else {
        // Check for any pending navigation from background handler
        await checkPendingNavigation();
      }

      // Handle notification when app is opened from background
      log('📱 [NotificationHandler] Registering onMessageOpenedApp listener...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        log('📱 [NotificationHandler] ==========================================');
        log('📱 [NotificationHandler] ✅✅✅ APP OPENED FROM BACKGROUND ✅✅✅');
        log('📱 [NotificationHandler] Message ID: ${message.messageId}');
        log('📱 [NotificationHandler] Title: ${message.notification?.title}');
        log('📱 [NotificationHandler] Body: ${message.notification?.body}');
        log('📱 [NotificationHandler] Data: ${message.data}');
        log('📱 [NotificationHandler] ==========================================');
        
        final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
        final body = message.notification?.body ?? message.data['body'] ?? 'You have a new message';
        
        // Process booking status notifications
        _processBookingNotification(message);
        
        // Add to notification controller
        _notificationController?.addNotification(
          title: title,
          body: body,
          data: message.data,
        );

        // Navigate immediately when notification is tapped (user explicitly opened app)
        await _handleNotificationNavigation(message.data, delayNavigation: false);
      });

      _initialized = true;
      log('✅ [NotificationHandler] Notification handlers initialized');
      debugPrint('✅ [Notification] Handlers ready - push notifications will show in tray and in-app');
      log('📱 [NotificationHandler] Listeners registered:');
      log('   ✅ onMessage (foreground notifications)');
      log('   ✅ onMessageOpenedApp (background notifications)');
      log('   ✅ getInitialMessage (terminated state)');
      log('📱 [NotificationHandler] ==========================================');
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error initializing: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Handle notification tap
          log('📱 [NotificationHandler] Local notification tapped: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            // Parse payload and navigate
            try {
              // Payload format: booking_id|screen
              final parts = response.payload!.split('|');
              if (parts.length >= 1 && parts[0].isNotEmpty) {
                final bookingId = parts[0];
                log('📱 [NotificationHandler] Parsed bookingId from payload: $bookingId');
                
                final data = {
                  'booking_id': bookingId,
                  'screen': parts.length > 1 ? parts[1] : 'track_order',
                  'action': 'navigate',
                  'type': 'booking_status',
                };
                
                // Wait a bit for app to be ready
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Navigate
                await _handleNotificationNavigation(data, delayNavigation: false);
              } else {
                log('⚠️ [NotificationHandler] Empty bookingId in payload');
              }
            } catch (e, stackTrace) {
              log('❌ [NotificationHandler] Error parsing notification payload: $e');
              log('❌ [NotificationHandler] Stack trace: $stackTrace');
            }
          } else {
            log('⚠️ [NotificationHandler] No payload in notification response');
          }
        },
      );
      await Future.delayed(Duration.zero); // yield to UI

      // Create Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      log('✅ [NotificationHandler] Local notifications initialized');
    } catch (e) {
      log('❌ [NotificationHandler] Error initializing local notifications: $e');
    }
  }

  /// Show system notification (for foreground state)
  Future<void> _showSystemNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      final bookingId = data['booking_id']?.toString() ?? '';
      final screen = data['screen']?.toString() ?? 'track_order';
      
      // Create payload for navigation
      final payload = '$bookingId|$screen';

      // Android notification details (must match channel in AndroidManifest for tray visibility)
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: false,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID so each notification appears in tray (not overwritten)
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      log('✅ [NotificationHandler] System notification shown: $title');
    } catch (e) {
      log('❌ [NotificationHandler] Error showing system notification: $e');
    }
  }

  /// Get title from status for data-only notifications
  String? _getTitleFromStatus(String status) {
    final statusTitles = {
      'washerAssigned': 'Washer Assigned',
      'accepted': 'Washer Accepted',
      'onTheWay': 'Washer On The Way',
      'arrived': 'Washer Arrived',
      'washing': 'Washing Started',
      'completed': 'Service Completed',
      'cancelled': 'Booking Cancelled',
    };
    return statusTitles[status];
  }

  /// Get body from status for data-only notifications
  String? _getBodyFromStatus(String status) {
    final statusBodies = {
      'washerAssigned': 'A washer has been assigned to your booking',
      'accepted': 'Your washer has accepted the booking and is preparing',
      'onTheWay': 'Your washer is on the way to your location',
      'arrived': 'Your washer has arrived at your location',
      'washing': 'Your car wash has started',
      'completed': 'Your car wash service has been completed',
      'cancelled': 'Your booking has been cancelled',
    };
    return statusBodies[status];
  }
}

