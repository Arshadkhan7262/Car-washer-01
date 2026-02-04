import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes.dart';

/// Global Notification Handler Service
/// Handles Firebase Cloud Messaging notifications throughout the washer app
class NotificationHandlerService {
  static final NotificationHandlerService _instance = NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  bool _initialized = false;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        log('📱 [NotificationHandler] Foreground notification received');
        log('📱 Title: ${message.notification?.title}');
        log('📱 Body: ${message.notification?.body}');
        log('📱 Data: ${message.data}');

        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? 'You have a new message';

        // Show system notification (not snackbar)
        await _showSystemNotification(title, body, message.data);
        
        // Store navigation data - navigation will happen when user taps the notification
        _storePendingNavigation(message.data);
      });

      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 [NotificationHandler] App opened from terminated state via notification');
        log('📱 [NotificationHandler] Notification data: ${initialMessage.data}');
        
        // Navigate when app opens from notification (with delay to ensure app is ready)
        await _handleNotificationNavigation(initialMessage.data, delayNavigation: true);
      } else {
        // Check for any pending navigation from background handler
        await checkPendingNavigation();
      }

      // Handle notification when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        log('📱 [NotificationHandler] App opened from background notification');
        log('📱 [NotificationHandler] Notification data: ${message.data}');
        
        // Navigate immediately when notification is tapped (user explicitly opened app)
        await _handleNotificationNavigation(message.data, delayNavigation: false);
      });

      _initialized = true;
      log('✅ [NotificationHandler] Notification handlers initialized');
    } catch (e) {
      log('❌ [NotificationHandler] Error initializing: $e');
    }
  }

  /// Store pending navigation data for when app opens
  Future<void> _storePendingNavigation(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobId = data['booking_id']?.toString() ?? data['job_id']?.toString();
      if (jobId != null && jobId.isNotEmpty) {
        await prefs.setString('pending_navigation_job_id', jobId);
        await prefs.setString('pending_navigation_screen', data['screen']?.toString() ?? 'jobs');
        log('📱 [NotificationHandler] Stored pending navigation for job: $jobId');
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
      final jobId = data['booking_id']?.toString() ?? data['job_id']?.toString();
      final notificationType = data['type']?.toString();

      log('📱 [NotificationHandler] Navigation request - jobId: $jobId, type: $notificationType, action: $action, screen: $screen');

      // Navigate if we have a job_id and it's a job-related notification
      if (jobId != null && jobId.isNotEmpty) {
        // Check if this is a job notification (job assignment, status update, etc.)
        final isJobNotification = notificationType == 'job_assigned' || 
                                  notificationType == 'job_status' ||
                                  notificationType == 'booking_status' ||
                                  screen == 'jobs' ||
                                  action == 'navigate';

        if (isJobNotification) {
          log('📱 [NotificationHandler] Processing navigation for job: $jobId');

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
            await prefs.remove('pending_navigation_job_id');
            await prefs.remove('pending_navigation_screen');
            
            // Navigate to jobs screen
            Get.toNamed(AppRoutes.jobs);
            log('✅ [NotificationHandler] Navigated to JobsScreen');
          } else {
            log('⚠️ [NotificationHandler] GetX context not available, storing for later');
            _storePendingNavigation(data);
          }
        }
      }
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error handling navigation: $e');
      log('❌ [NotificationHandler] Stack trace: $stackTrace');
    }
  }

  /// Check for pending navigation from background/terminated state
  Future<void> checkPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobId = prefs.getString('pending_navigation_job_id');
      
      if (jobId != null && jobId.isNotEmpty) {
        log('📱 [NotificationHandler] Found pending navigation for job: $jobId');
        
        // Wait for GetX to be ready
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // Retry logic - check multiple times
        int retries = 0;
        while (retries < 5 && Get.context == null) {
          await Future.delayed(const Duration(milliseconds: 500));
          retries++;
        }
        
        if (Get.context != null) {
          // Clear pending navigation
          await prefs.remove('pending_navigation_job_id');
          await prefs.remove('pending_navigation_screen');
          
          // Navigate to jobs screen
          Get.toNamed(AppRoutes.jobs);
          log('✅ [NotificationHandler] Handled pending navigation to JobsScreen for job: $jobId');
        } else {
          log('⚠️ [NotificationHandler] GetX context still not available after retries');
        }
      }
    } catch (e, stackTrace) {
      log('❌ [NotificationHandler] Error checking pending navigation: $e');
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
              // Payload format: job_id|screen
              final parts = response.payload!.split('|');
              if (parts.length >= 1 && parts[0].isNotEmpty) {
                final jobId = parts[0];
                log('📱 [NotificationHandler] Parsed jobId from payload: $jobId');
                
                final data = {
                  'job_id': jobId,
                  'booking_id': jobId, // Support both keys
                  'screen': parts.length > 1 ? parts[1] : 'jobs',
                  'action': 'navigate',
                  'type': 'job_status',
                };
                
                // Wait a bit for app to be ready
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Navigate
                await _handleNotificationNavigation(data, delayNavigation: false);
              } else {
                log('⚠️ [NotificationHandler] Empty jobId in payload');
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
      final jobId = data['booking_id']?.toString() ?? data['job_id']?.toString() ?? '';
      final screen = data['screen']?.toString() ?? 'jobs';
      
      // Create payload for navigation
      final payload = '$jobId|$screen';

      // Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
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
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
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
}
