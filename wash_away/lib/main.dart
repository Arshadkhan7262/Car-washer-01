import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/auth/auth_binding.dart'; 
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/email_otp_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/initial_loading_screen.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'screens/resume_booking_screen.dart';
import 'controllers/theme_controller.dart';

import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';
import 'features/notifications/services/notification_handler_service.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/notifications/controllers/fcm_token_controller.dart';
import 'features/notifications/widgets/in_app_notification_banner.dart';
import 'util/constants.dart';
import 'config/env_config.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'features/bookings/services/draft_booking_service.dart';

// Background message handler (must be top-level function)
// This runs when app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  log('📱 [Background] ==========================================');
  log('📱 [Background] BACKGROUND NOTIFICATION RECEIVED');
  log('📱 [Background] Message ID: ${message.messageId}');
  log('📱 [Background] Title: ${message.notification?.title}');
  log('📱 [Background] Body: ${message.notification?.body}');
  log('📱 [Background] Data: ${message.data}');
  log('📱 [Background] ==========================================');

  // Show notification in system tray when app is in background/terminated
  // Since backend now sends data-only payloads, we must show notifications manually
  // This ensures consistent notification appearance and proper navigation handling
  try {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Wash Away';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? 'You have a new notification';
    if (Platform.isAndroid) {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await plugin.initialize(initSettings);
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      final details = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        ticker: title,
      );
      final bookingId = message.data['booking_id']?.toString() ?? '';
      final screen = message.data['screen']?.toString() ?? 'track_order';
      final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      await plugin.show(id, title, body, NotificationDetails(android: details), payload: '$bookingId|$screen');
      log('📱 [Background] Notification shown in tray: $title');
    } else if (Platform.isIOS) {
      // iOS handling
      final plugin = FlutterLocalNotificationsPlugin();
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(iOS: iosSettings);
      await plugin.initialize(initSettings);
      const details = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final bookingId = message.data['booking_id']?.toString() ?? '';
      final screen = message.data['screen']?.toString() ?? 'track_order';
      final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      await plugin.show(id, title, body, NotificationDetails(iOS: details), payload: '$bookingId|$screen');
      log('📱 [Background] Notification shown in tray: $title');
    }
  } catch (e) {
    log('❌ [Background] Error showing notification: $e');
  }

  // Store navigation data for when app opens
  try {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = message.data['booking_id']?.toString();
    if (bookingId != null && bookingId.isNotEmpty) {
      await prefs.setString('pending_navigation_booking_id', bookingId);
      await prefs.setString('pending_navigation_screen', message.data['screen']?.toString() ?? 'track_order');
      log('📱 [Background] Stored navigation data for booking: $bookingId');
    }
  } catch (e) {
    log('❌ [Background] Error storing navigation data: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await EnvConfig.initialize();
  
  // Initialize Firebase before running the app (skip on web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
      
      // Set up background message handler (only on mobile)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permission early so handler can show notifications when it inits
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('📱 [Notification] Permission at startup: ${settings.authorizationStatus}');
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          debugPrint('📱 [Notification] Enable in Settings → Apps → Wash Away → Notifications, then restart app');
        }
        
        // IMPORTANT: Disable Firebase's automatic notification display in foreground
        // We handle notifications manually via flutter_local_notifications to avoid duplicates
        // This prevents Firebase from auto-showing notifications when app is in foreground
        try {
          await messaging.setForegroundNotificationPresentationOptions(
            alert: true,  // Don't auto-show alert (we'll show via flutter_local_notifications)
            badge: true,   // Still update badge
            sound: true,  // Don't auto-play sound (we'll handle it)
          );
          debugPrint('✅ [Notification] Disabled Firebase auto-display in foreground (iOS)');
        } catch (e) {
          // setForegroundNotificationPresentationOptions is iOS-only, ignore on Android
          debugPrint('ℹ️ [Notification] setForegroundNotificationPresentationOptions not available (Android)');
        }
      } catch (e) {
        debugPrint('⚠️ [Notification] Permission request failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Continue app execution even if Firebase fails (fallback will handle it)
    }
  } else {
    debugPrint('ℹ️ Firebase initialization skipped on web platform');
  }

  // Initialize Stripe (skip on web - Stripe Payment Sheet doesn't work on web)
  if (!kIsWeb) {
    try {
      // Validate Stripe configuration
      if (!AppConstants.validateStripeConfig()) {
        debugPrint('⚠️ Stripe publishable key not configured properly.');
        debugPrint('   Please check your .env file and ensure STRIPE_PUBLISHABLE_KEY is set correctly.');
        debugPrint('   The key must match your backend STRIPE_SECRET_KEY account.');
        debugPrint('   Get keys from: https://dashboard.stripe.com/test/apikeys');
      } else {
        final stripeKey = AppConstants.stripePublishableKey;
        
        // Set publishable key
        Stripe.publishableKey = stripeKey;
        
        // Set Apple Pay merchant identifier if configured
        final merchantId = AppConstants.applePayMerchantIdentifier;
        if (merchantId.isNotEmpty) {
          Stripe.merchantIdentifier = merchantId;
          debugPrint('✅ Apple Pay merchant identifier configured: $merchantId');
        } else {
          debugPrint('ℹ️ Apple Pay merchant identifier not configured (Apple Pay will be disabled)');
        }
        
        // Apply settings to initialize Stripe SDK
        await Stripe.instance.applySettings();
        
        // Log Stripe mode (test vs live)
        final mode = AppConstants.isStripeTestMode ? 'TEST' : 'LIVE';
        debugPrint('✅ Stripe initialized successfully');
        debugPrint('   Mode: $mode');
        debugPrint('   Key: ${stripeKey.substring(0, 12)}...');
        debugPrint('   ⚠️ IMPORTANT: Ensure backend STRIPE_SECRET_KEY matches this account!');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Stripe initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('⚠️ Please check your .env file and ensure STRIPE_PUBLISHABLE_KEY is correct');
      // Don't set an invalid key - CardField will handle gracefully
      // Continue app execution even if Stripe fails
    }
  } else {
    debugPrint('ℹ️ Stripe initialization skipped on web platform (not supported)');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Defer notification init until after first frame to avoid blocking UI and ANR/crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    // Skip notifications on web (Firebase Messaging doesn't work on web)
    if (kIsWeb) {
      log('ℹ️ Notifications initialization skipped on web platform');
      return;
    }
    
    log('🔄 [MyApp] Starting notification initialization...');
    
    try {
      await Future.delayed(Duration.zero); // start as soon as possible
      log('🔄 [MyApp] Initializing NotificationController (permanent)...');
      Get.put(NotificationController(), permanent: true);
      log('✅ [MyApp] NotificationController initialized');
      
      await Future.delayed(const Duration(milliseconds: 50)); // yield
      log('🔄 [MyApp] Initializing FcmTokenController (permanent)...');
      if (!Get.isRegistered<FcmTokenController>()) {
        Get.put(FcmTokenController(), permanent: true);
      }
      log('✅ [MyApp] FcmTokenController ready');
      
      await Future.delayed(const Duration(milliseconds: 50)); // yield
      log('🔄 [MyApp] Initializing NotificationHandlerService (foreground + tray)...');
      await NotificationHandlerService().initialize();
      log('✅ [MyApp] NotificationHandlerService initialized');
      
      await Future.delayed(const Duration(milliseconds: 300)); // yield before navigation check
      log('🔄 [MyApp] Checking pending navigation...');
      await NotificationHandlerService().checkPendingNavigation();
      log('✅ [MyApp] Notification initialization completed');
    } catch (e, stackTrace) {
      log('❌ [MyApp] Error initializing notifications: $e');
      log('❌ [MyApp] Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    return Obx(() => GetMaterialApp(
      title: 'Wash Away',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.themeData,
      darkTheme: DarkTheme.themeData,
      themeMode: themeController.isDarkMode.value
          ? ThemeMode.dark
          : ThemeMode.light,
      initialBinding: AuthBinding(),
      initialRoute: '/',
      builder: (context, child) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InAppNotificationBanner(),
            ),
          ],
        );
      },
      getPages: [
        GetPage(
          name: '/',
          page: () => const InitialLoadingScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/signup',
          page: () => const SignUpScreen(),
        ),
        GetPage(
          name: '/email-otp-verify',
          page: () => const EmailOtpScreen(),
        ),
        GetPage(
          name: '/reset-password',
          page: () => const ResetPasswordScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardScreen(),
        ),
      ],
    ));
  }
}
