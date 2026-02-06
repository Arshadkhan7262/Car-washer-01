import 'dart:async';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsBinding;
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
  bool _isInitializing = false; // Prevent concurrent initialization
  bool _notificationChannelCreated = false; // Track if Android channel is created
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Store subscriptions to prevent duplicate listeners
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  
  // Map of booking_id -> callback functions
  final Map<String, List<BookingStatusCallback>> _bookingCallbacks = {};
  
  NotificationController get _notificationController {
    if (Get.isRegistered<NotificationController>()) {
      return Get.find<NotificationController>();
    }
    // Initialize if not registered to ensure notifications are always tracked
    return Get.put(NotificationController());
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

  /// Handle navigation based on notification data.
  /// When user taps a notification (foreground, background, or terminated), navigate to Track Order only.
  Future<void> _handleNotificationNavigation(Map<String, dynamic> data, {bool delayNavigation = false}) async {
    try {
      // Support both booking_id and bookingId (backend may send either)
      final bookingId = data['booking_id']?.toString() ?? data['bookingId']?.toString();
      final screen = data['screen']?.toString();
      final action = data['action']?.toString();
      final notificationType = data['type']?.toString();

      log('📱 [NotificationHandler] Navigation request - bookingId: $bookingId, type: $notificationType, action: $action, screen: $screen');

      // Navigate to Track Order whenever we have a booking_id (any notification tap = go to track order)
      if (bookingId != null && bookingId.isNotEmpty) {
        log('📱 [NotificationHandler] Processing navigation to TrackOrderScreen for booking: $bookingId');

        if (delayNavigation) {
          log('📱 [NotificationHandler] Delaying navigation for app initialization...');
          await Future.delayed(const Duration(milliseconds: 1500));
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (Get.context != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_navigation_booking_id');
          await prefs.remove('pending_navigation_screen');

          // Navigate to dashboard first, then push TrackOrderScreen on top
          // This ensures there's always a screen to go back to
          log('📱 [NotificationHandler] Navigating to TrackOrderScreen for booking: $bookingId');
          Get.offAllNamed('/dashboard');
          // Wait a bit for dashboard to load, then push TrackOrderScreen
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.to(() => TrackerOrderScreen(bookingId: bookingId));
          });
          log('✅ [NotificationHandler] Successfully navigated to TrackOrderScreen');
        } else {
          log('⚠️ [NotificationHandler] GetX context not available, storing for later navigation');
          await _storePendingNavigation(data);
          Future.delayed(const Duration(milliseconds: 2000), () async {
            if (Get.context != null) {
              final prefs = await SharedPreferences.getInstance();
              final storedBookingId = prefs.getString('pending_navigation_booking_id');
              if (storedBookingId != null && storedBookingId.isNotEmpty) {
                await prefs.remove('pending_navigation_booking_id');
                await prefs.remove('pending_navigation_screen');
                // Navigate to dashboard first, then push TrackOrderScreen
                Get.offAllNamed('/dashboard');
                Future.delayed(const Duration(milliseconds: 300), () {
                  Get.to(() => TrackerOrderScreen(bookingId: storedBookingId));
                });
                log('✅ [NotificationHandler] Navigated after retry');
              }
            }
          });
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
          await prefs.remove('pending_navigation_booking_id');
          await prefs.remove('pending_navigation_screen');
          // Replace stack so user sees only Track Order
          Get.offAll(() => TrackerOrderScreen(bookingId: bookingId));
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
    // Prevent concurrent initialization
    if (_isInitializing) {
      log('⚠️ [NotificationHandler] Initialization already in progress, waiting...');
      // Wait for current initialization to complete
      int waitCount = 0;
      while (_isInitializing && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_initialized) {
        log('✅ [NotificationHandler] Initialization completed by another call');
        return;
      }
    }
    
    _isInitializing = true;
    
    try {
      // Always cancel existing subscriptions first to prevent duplicates
      await _onMessageSubscription?.cancel();
      await _onMessageOpenedAppSubscription?.cancel();
      _onMessageSubscription = null;
      _onMessageOpenedAppSubscription = null;
      
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
        _isInitializing = false;
        return;
      }

      // Main initialization code
      log('📱 [NotificationHandler] ==========================================');
      log('📱 [NotificationHandler] Initializing notification handlers...');
      await Future.delayed(Duration.zero); // yield to UI thread

      // Check current permission status (don't request again - FCM token controller handles that)
      NotificationSettings settings = await _messaging.getNotificationSettings();
      log('📱 [NotificationHandler] Permission status: ${settings.authorizationStatus}');
      await Future.delayed(Duration.zero); // yield
      
      // IMPORTANT: Disable Firebase's automatic notification display in foreground
      // We handle notifications manually via flutter_local_notifications to avoid duplicates
      // This prevents Firebase from auto-showing notifications when app is in foreground
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: false,  // Don't auto-show alert (we'll show via flutter_local_notifications)
          badge: true,   // Still update badge count
          sound: false,  // Don't auto-play sound (we'll handle it in our custom notification)
        );
        log('✅ [NotificationHandler] Disabled Firebase auto-display in foreground (iOS)');
      } catch (e) {
        // setForegroundNotificationPresentationOptions is iOS-only, ignore on Android
        log('ℹ️ [NotificationHandler] setForegroundNotificationPresentationOptions not available (Android)');
      }

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
        _notificationChannelCreated = false; // Reset channel flag on reinitialize
      }

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();
      await Future.delayed(Duration.zero); // yield

      // Listen for foreground messages
      // Show system notification using flutter_local_notifications
      log('📱 [NotificationHandler] Registering onMessage listener...');
      
      // Cancel existing subscription to prevent duplicates
      await _onMessageSubscription?.cancel();
      
      // Store subscription to prevent garbage collection and track it
      _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        log('📱 [NotificationHandler] Foreground notification received');
        log('📱 Title: ${message.notification?.title}');
        log('📱 Body: ${message.notification?.body}');
        log('📱 Data: ${message.data}');

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
        
        // FOREGROUND: Show system notification FIRST so it always appears even if later steps fail
        try {
          await _showSystemNotification(title, body, message.data);
          log('✅ [NotificationHandler] System notification displayed (foreground)');
          debugPrint('✅ [Notification] Shown in tray: $title');
        } catch (e) {
          log('❌ [NotificationHandler] Failed to show system notification: $e');
          debugPrint('❌ [Notification] Tray show failed: $e');
        }

        // Then process callbacks, in-app list, in-app top banner, and pending navigation (non-blocking for display)
        try {
          final bid = message.data['booking_id']?.toString() ?? message.data['bookingId']?.toString() ?? '';
          if (bid.isNotEmpty) _notificationController.recordForegroundPush(bid);
          _processBookingNotification(message);
          _notificationController.addNotification(
            title: title,
            body: body,
            data: message.data,
          );
          // Show banner on next frame so UI updates reliably (and snackbar suppression already set above)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _notificationController.showBanner(
                title: title,
                body: body,
                data: message.data,
              );
            } catch (e) {
              log('❌ [NotificationHandler] Error showing banner: $e');
            }
          });
          _storePendingNavigation(message.data);
        } catch (e) {
          log('❌ [NotificationHandler] Error in post-notification processing: $e');
        }
      });

      // Handle notification when app is opened from terminated state (user tapped notification)
      log('📱 [NotificationHandler] Checking for initial message (terminated state)...');
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 [NotificationHandler] ==========================================');
        log('📱 [NotificationHandler] ✅✅✅ APP OPENED FROM TERMINATED STATE ✅✅✅');
        log('📱 [NotificationHandler] Message ID: ${initialMessage.messageId}');
        log('📱 [NotificationHandler] Data: ${initialMessage.data}');
        log('📱 [NotificationHandler] ==========================================');

        // Store pending so InitialLoadingScreen can navigate to Track Order (avoids race with dashboard)
        await _storePendingNavigation(initialMessage.data);

        final title = initialMessage.notification?.title ?? initialMessage.data['title'] ?? 'New Notification';
        final body = initialMessage.notification?.body ?? initialMessage.data['body'] ?? 'You have a new message';
        _processBookingNotification(initialMessage);
        _notificationController.addNotification(
          title: title,
          body: body,
          data: initialMessage.data,
        );

        // Don't await: let InitialLoadingScreen see pending and navigate (so it won't overwrite with dashboard)
        _handleNotificationNavigation(initialMessage.data, delayNavigation: true);
      } else {
        await checkPendingNavigation();
      }

      // Handle notification when app is opened from background
      log('📱 [NotificationHandler] Registering onMessageOpenedApp listener...');
      
      // Cancel existing subscription to prevent duplicates
      await _onMessageOpenedAppSubscription?.cancel();
      
      // Store subscription to prevent garbage collection and track it
      _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
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
        _notificationController.addNotification(
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
      log('   ✅ onMessage (foreground notifications) - Subscription active: ${_onMessageSubscription != null}');
      log('   ✅ onMessageOpenedApp (background notifications) - Subscription active: ${_onMessageOpenedAppSubscription != null}');
      log('   ✅ getInitialMessage (terminated state)');
      log('📱 [NotificationHandler] ==========================================');
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error initializing: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
    } finally {
      _isInitializing = false;
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

      // Create Android notification channel (matches car_wash_app - Importance.high)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id - must match AndroidManifest.xml
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

      // CRITICAL: Create channel synchronously and verify it was created
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          await androidPlugin.createNotificationChannel(channel);
          _notificationChannelCreated = true;
          log('✅ [NotificationHandler] Android notification channel created successfully');
          debugPrint('✅ [Notification] Channel "high_importance_channel" created');
        } catch (e) {
          log('❌ [NotificationHandler] Failed to create Android notification channel: $e');
          debugPrint('❌ [Notification] Channel creation failed: $e');
          // Try again after a short delay
          try {
            await Future.delayed(const Duration(milliseconds: 200));
            await androidPlugin.createNotificationChannel(channel);
            _notificationChannelCreated = true;
            log('✅ [NotificationHandler] Android notification channel created on retry');
            debugPrint('✅ [Notification] Channel created on retry');
          } catch (retryError) {
            log('❌ [NotificationHandler] Channel creation failed on retry: $retryError');
            debugPrint('❌ [Notification] Channel creation retry failed: $retryError');
            _notificationChannelCreated = false;
          }
        }
      } else {
        // Not Android platform
        _notificationChannelCreated = true; // Not needed for iOS
        log('ℹ️ [NotificationHandler] Android plugin not available (not Android platform)');
      }

      log('✅ [NotificationHandler] Local notifications initialized');
      log('📱 [NotificationHandler] Channel created flag: $_notificationChannelCreated');
    } catch (e) {
      log('❌ [NotificationHandler] Error initializing local notifications: $e');
    }
  }

  /// Show system notification (heads-up push notification when app is in foreground)
  Future<void> _showSystemNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Skip on web platform
      if (kIsWeb) {
        log('ℹ️ [NotificationHandler] Skipping notification display on web platform');
        return;
      }

      // CRITICAL: Ensure Android notification channel is created before showing notification
      if (!_notificationChannelCreated) {
        log('⚠️ [NotificationHandler] Notification channel not created yet, creating now...');
        debugPrint('⚠️ [Notification] Creating channel before showing notification...');
        try {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'This channel is used for important notifications.',
            importance: Importance.high,
            playSound: true,
          );
          
          final androidPlugin = _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          
          if (androidPlugin != null) {
            await androidPlugin.createNotificationChannel(channel);
            _notificationChannelCreated = true;
            log('✅ [NotificationHandler] Notification channel created before showing notification');
            debugPrint('✅ [Notification] Channel created successfully');
          } else {
            log('⚠️ [NotificationHandler] Android plugin not available');
            _notificationChannelCreated = true; // Not Android, continue
          }
        } catch (channelError) {
          log('❌ [NotificationHandler] Failed to create channel before showing notification: $channelError');
          debugPrint('❌ [Notification] Channel creation error: $channelError');
          // Continue anyway - channel might already exist
          _notificationChannelCreated = true; // Assume it exists or will be created by system
        }
      }
      
      final bookingId = data['booking_id']?.toString() ?? '';
      final screen = data['screen']?.toString() ?? 'track_order';
      
      // Create payload for navigation
      final payload = '$bookingId|$screen';

      // Android notification details (matches car_wash_app: Importance.high, Priority.high)
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel', // Must match channel ID
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID so each notification appears in tray (not overwritten)
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      log('📱 [NotificationHandler] ==========================================');
      log('📱 [NotificationHandler] ATTEMPTING TO SHOW FOREGROUND NOTIFICATION');
      log('📱 [NotificationHandler] Title: $title');
      log('📱 [NotificationHandler] Body: $body');
      log('📱 [NotificationHandler] Channel created: $_notificationChannelCreated');
      log('📱 [NotificationHandler] Notification ID: $id');
      log('📱 [NotificationHandler] Payload: $payload');
      debugPrint('📱 [Notification] Showing foreground notification: $title');
      
      // CRITICAL: Show the notification
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      log('✅ [NotificationHandler] ==========================================');
      log('✅ [NotificationHandler] System notification shown successfully!');
      log('✅ [NotificationHandler] Title: $title');
      log('✅ [NotificationHandler] ID: $id');
      debugPrint('✅ [Notification] ✅✅✅ FOREGROUND NOTIFICATION DISPLAYED ✅✅✅');
      debugPrint('✅ [Notification] Title: $title, Body: $body');
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] ==========================================');
      log('❌ [NotificationHandler] ERROR SHOWING SYSTEM NOTIFICATION');
      log('❌ [NotificationHandler] Error: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
      debugPrint('❌ [Notification] Failed to show foreground notification: $e');
      debugPrint('❌ [Notification] Error details: $stackTrace');
      
      // Try to show notification again with a delay (sometimes helps with timing issues)
      try {
        log('🔄 [NotificationHandler] Retrying notification display after delay...');
        debugPrint('🔄 [Notification] Retrying after 500ms delay...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        final bookingId = data['booking_id']?.toString() ?? '';
        final screen = data['screen']?.toString() ?? 'track_order';
        final payload = '$bookingId|$screen';
        final int id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
        
        final NotificationDetails retryDetails = NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
        
        await _localNotifications.show(id, title, body, retryDetails, payload: payload);
        log('✅ [NotificationHandler] Notification shown successfully on retry');
        debugPrint('✅ [Notification] Retry successful!');
      } catch (retryError, retryStack) {
        log('❌ [NotificationHandler] Retry also failed: $retryError');
        log('❌ [NotificationHandler] Retry stack: $retryStack');
        debugPrint('❌ [Notification] Retry failed: $retryError');
      }
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

