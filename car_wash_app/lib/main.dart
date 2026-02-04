import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'routes.dart';
import 'features/auth/services/auth_service.dart';
import 'features/notifications/services/notification_handler_service.dart';

// Background message handler (must be top-level function)
// This runs when app is in background or terminated (separate isolate)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  log('📱 [Background] Received notification: ${message.messageId}');
  log('📱 [Background] Title: ${message.notification?.title}');
  log('📱 [Background] Body: ${message.notification?.body}');
  log('📱 [Background] Data: ${message.data}');
  
  // Store navigation data for when app opens
  try {
    final prefs = await SharedPreferences.getInstance();
    final jobId = message.data['booking_id']?.toString() ?? message.data['job_id']?.toString();
    if (jobId != null && jobId.isNotEmpty) {
      await prefs.setString('pending_navigation_job_id', jobId);
      await prefs.setString('pending_navigation_screen', message.data['screen']?.toString() ?? 'jobs');
      log('📱 [Background] Stored navigation data for job: $jobId');
    }
  } catch (e) {
    log('❌ [Background] Error storing navigation data: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase before running the app (skip on web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
      
      // Set up background message handler (only on mobile)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Continue app execution even if Firebase fails (fallback will handle it)
    }
  } else {
    debugPrint('ℹ️ Firebase initialization skipped on web platform');
  }

  final authService = AuthService();
  String initialRoute = AppRoutes.login;
  Map<String, dynamic>? routeArguments;

  // Check if user has stored token (logged in)
  final isLoggedIn = await authService.isLoggedIn();
  final cachedStatus = await authService.getCachedAccountStatus();

  if (isLoggedIn) {
    // User has token - verify status with backend
    final statusData = await authService.checkUserStatus();

    if (statusData != null) {
      final washerStatus = statusData['washer']?['status'] ?? statusData['status'];

      if (washerStatus == 'active') {
        // User is active, navigate to dashboard
        initialRoute = AppRoutes.dashboard;
      } else if (washerStatus == 'pending') {
        // User is pending, navigate to dashboard with pending overlay
        initialRoute = AppRoutes.dashboard;
        routeArguments = {'isPending': true};
      } else if (washerStatus == 'suspended') {
        // User is suspended, navigate to dashboard with suspended overlay
        initialRoute = AppRoutes.dashboard;
        routeArguments = {'isSuspended': true};
      } else {
        // Invalid status, logout and show login
        await authService.logout();
        initialRoute = AppRoutes.login;
      }
    } else {
      // API call failed - check cached status
      if (cachedStatus == 'pending') {
        // Account exists but is pending - show dashboard with overlay
        initialRoute = AppRoutes.dashboard;
        routeArguments = {'isPending': true};
      } else if (cachedStatus == 'suspended') {
        // Account is suspended - show dashboard with suspended overlay
        initialRoute = AppRoutes.dashboard;
        routeArguments = {'isSuspended': true};
      } else if (cachedStatus == 'active') {
        // Cached status is active - try to get profile to verify
        // If profile fetch fails, still show dashboard (token might be expired but status is active)
        initialRoute = AppRoutes.dashboard;
      } else {
        // Invalid token and no cached status, logout and show login
        await authService.logout();
        initialRoute = AppRoutes.login;
      }
    }
  } else {
    // Not logged in - check cached status
    if (cachedStatus == 'pending') {
      // Account exists but is pending - show dashboard with overlay
      initialRoute = AppRoutes.dashboard;
      routeArguments = {'isPending': true};
    } else if (cachedStatus == 'suspended') {
      // Account is suspended - show dashboard with suspended overlay
      initialRoute = AppRoutes.dashboard;
      routeArguments = {'isSuspended': true};
    } else if (cachedStatus == 'active') {
      // Account is active but no token - user needs to login
      initialRoute = AppRoutes.login;
    }
    // If no cached status, show login screen
  }

  runApp(MyApp(initialRoute: initialRoute, routeArguments: routeArguments));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  final Map<String, dynamic>? routeArguments;

  const MyApp({super.key, required this.initialRoute, this.routeArguments});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Skip notifications on web (Firebase Messaging doesn't work on web)
    if (kIsWeb) {
      log('ℹ️ Notifications initialization skipped on web platform');
      return;
    }
    
    // Wait a bit for GetX to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      // Initialize the handler service
      await NotificationHandlerService().initialize();
      
      // Check for any pending navigation from background/terminated state
      // Wait a bit more for app to fully initialize
      await Future.delayed(const Duration(milliseconds: 1000));
      await NotificationHandlerService().checkPendingNavigation();
    } catch (e) {
      log('❌ Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Car Wash Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // This is the "kill switch" for dark mode.
      initialRoute: widget.initialRoute,
      getPages: AppRoutes.getRoutes(),
      initialBinding: widget.routeArguments != null && widget.routeArguments!['isPending'] == true
          ? null
          : null, // Dashboard binding will be handled by route
    );
  }
}
