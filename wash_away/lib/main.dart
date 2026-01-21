
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'features/auth/auth_binding.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/email_otp_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'screens/resume_booking_screen.dart';
import 'controllers/theme_controller.dart';

import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/notifications/services/notification_handler_service.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'util/constants.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'features/bookings/services/draft_booking_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📱 [Background] Received notification: ${message.messageId}');
  log('📱 [Background] Title: ${message.notification?.title}');
  log('📱 [Background] Body: ${message.notification?.body}');
  log('📱 [Background] Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase before running the app (skip on web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Set up background message handler (only on mobile)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      // Continue app execution even if Firebase fails (fallback will handle it)
    }
  } else {
    print('ℹ️ Firebase initialization skipped on web platform');
  }

  // Initialize Stripe (skip on web - Stripe Payment Sheet doesn't work on web)
  if (!kIsWeb) {
    try {
      final stripeKey = AppConstants.stripePublishableKey;
      if (stripeKey.isNotEmpty && stripeKey != 'pk_test_your_publishable_key_here') {
        // Set publishable key directly
        Stripe.publishableKey = stripeKey;
        
        // Set Apple Pay merchant identifier if configured
        final merchantId = AppConstants.applePayMerchantIdentifier;
        if (merchantId.isNotEmpty) {
          Stripe.merchantIdentifier = merchantId;
          print('✅ Apple Pay merchant identifier configured: $merchantId');
        } else {
          print('ℹ️ Apple Pay merchant identifier not configured (Apple Pay will be disabled)');
        }
        
        // Apply settings to initialize Stripe SDK
        await Stripe.instance.applySettings();
        print('✅ Stripe initialized successfully with key: ${stripeKey.substring(0, 12)}...');
      } else {
        print('⚠️ Stripe publishable key not configured. Card payments will be disabled.');
        print('   Please add your Stripe publishable key in util/constants.dart');
        // Don't set an invalid key - leave it uninitialized
        // CardField will check for this and show fallback UI
      }
    } catch (e, stackTrace) {
      print('❌ Stripe initialization error: $e');
      print('Stack trace: $stackTrace');
      // Don't set invalid key - CardField will handle gracefully
      // Continue app execution even if Stripe fails
    }
  } else {
    print('ℹ️ Stripe initialization skipped on web platform (not supported)');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? initialRoute;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    // Initialize notification handlers after app starts
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
      // Initialize notification controller first
      Get.put(NotificationController());
      // Then initialize the handler service
      await NotificationHandlerService().initialize();
    } catch (e) {
      log('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      // If logged in, verify token is still valid by checking user status
      if (isLoggedIn) {
        final statusData = await authService.checkUserStatus();
        if (statusData != null) {
          // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
          // Check if there's a draft booking
          // final draftBookingService = DraftBookingService();
          // final hasDraft = await draftBookingService.checkDraftExists();
          
          setState(() {
            // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
            // if (hasDraft) {
            //   initialRoute = '/resume-booking';
            // } else {
            //   initialRoute = '/dashboard';
            // }
            initialRoute = '/dashboard';
            isLoading = false;
          });
          return;
        }
      }
      
      // Not logged in or token invalid
      setState(() {
        initialRoute = '/login';
        isLoading = false;
      });
    } catch (e) {
      // On error, default to login
      setState(() {
        initialRoute = '/login';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    
    if (isLoading) {
      return MaterialApp(
        title: 'Wash Away',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return Obx(() => GetMaterialApp(
      title: 'Wash Away',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.themeData,
      darkTheme: DarkTheme.themeData,
      themeMode: themeController.isDarkMode.value 
          ? ThemeMode.dark 
          : ThemeMode.light,
      initialBinding: AuthBinding(),
      initialRoute: initialRoute ?? '/login',
      getPages: [
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
        // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
        // GetPage(
        //   name: '/resume-booking',
        //   page: () => const ResumeBookingScreen(),
        // ),
      ],
    ));
  }
}
