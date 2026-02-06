import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/notifications/controllers/fcm_token_controller.dart';
import '../features/notifications/services/notification_handler_service.dart';
import 'track_order_screen.dart';

/// Shown as the first route inside GetMaterialApp.
/// Runs auth check then navigates to /dashboard or /login so the app never gets stuck.
class InitialLoadingScreen extends StatefulWidget {
  const InitialLoadingScreen({super.key});

  @override
  State<InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<InitialLoadingScreen> {
  static const Duration _authTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _performAuthAndNavigate());
  }

  Future<void> _performAuthAndNavigate() async {
    // IMPORTANT: Check authentication FIRST to restore session token before navigation
    // This ensures API client has the auth token when TrackOrderScreen makes requests
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    
    // Check for pending notification but don't navigate yet
    var pendingBookingId = prefs.getString('pending_navigation_booking_id');
    final hasPendingNotification = pendingBookingId != null && pendingBookingId.isNotEmpty;
    
    if (hasPendingNotification) {
      log('📱 [InitialLoadingScreen] Pending notification detected for booking: $pendingBookingId');
      log('📱 [InitialLoadingScreen] Will check authentication first before navigating...');
    }

    // Run auth check FIRST to restore token to API client
    final Future<String> authTask = _runAuthCheck(authService);
    final Future<String> timeoutTask = Future<String>.delayed(
      _authTimeout,
      () => 'timeout',
    );
    final String result = await Future.any([authTask, timeoutTask]);
    if (!mounted) return;

    // After auth check, verify if user is logged in
    final isLoggedIn = result == 'dashboard';
    
    // If there's a pending notification, navigate to Track Order (only if logged in)
    if (hasPendingNotification) {
      // Re-read pending booking ID (might have been updated during auth check)
      pendingBookingId = prefs.getString('pending_navigation_booking_id');
      
      if (pendingBookingId != null && pendingBookingId.isNotEmpty) {
        if (isLoggedIn) {
          // User is logged in - navigate to Track Order
          await prefs.remove('pending_navigation_booking_id');
          await prefs.remove('pending_navigation_screen');
          log('📱 [InitialLoadingScreen] User is logged in -> navigating to Track Order for booking: $pendingBookingId');
          
          // Wait for Get.context to be ready (cold start can be slow)
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;
            if (Get.context != null) {
              // Navigate to dashboard first, then push TrackOrderScreen on top
              // This ensures there's always a screen to go back to
              Get.offAllNamed('/dashboard');
              Future.delayed(const Duration(milliseconds: 300), () {
                Get.to(() => TrackerOrderScreen(bookingId: pendingBookingId!));
              });
              log('✅ [InitialLoadingScreen] Navigated to Track Order (terminated state)');
              return;
            }
          }
          log('⚠️ [InitialLoadingScreen] Get.context not ready, re-storing pending for later');
          await prefs.setString('pending_navigation_booking_id', pendingBookingId);
        } else {
          // User is not logged in - clear pending and go to login
          log('⚠️ [InitialLoadingScreen] User not logged in -> clearing pending notification and going to login');
          await prefs.remove('pending_navigation_booking_id');
          await prefs.remove('pending_navigation_screen');
          Get.offAllNamed('/login');
          return;
        }
      }
    }

    // Check if pending was set during _runAuthCheck (e.g. by getInitialMessage in initialize())
    pendingBookingId = prefs.getString('pending_navigation_booking_id');
    if (pendingBookingId != null && pendingBookingId.isNotEmpty && isLoggedIn) {
      await prefs.remove('pending_navigation_booking_id');
      await prefs.remove('pending_navigation_screen');
      log('📱 [InitialLoadingScreen] Pending set during init -> Track Order for booking: $pendingBookingId');
      if (Get.context != null) {
        // Navigate to dashboard first, then push TrackOrderScreen on top
        Get.offAllNamed('/dashboard');
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.to(() => TrackerOrderScreen(bookingId: pendingBookingId!));
        });
        return;
      }
    }

    // Normal navigation flow
    if (result == 'dashboard') {
      Get.offAllNamed('/dashboard');
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<String> _runAuthCheck(AuthService authService) async {
    try {
      final isLoggedIn = await authService.isLoggedIn();
      if (!isLoggedIn) return 'login';
      
      // If user is logged in, refresh FCM token and ensure notifications are initialized
      if (!kIsWeb) {
        try {
          log('🔄 [InitialLoadingScreen] ==========================================');
          log('🔄 [InitialLoadingScreen] Refreshing FCM token for logged-in user...');
          
          // Get or create FCM token controller
          FcmTokenController fcmController;
          if (Get.isRegistered<FcmTokenController>()) {
            fcmController = Get.find<FcmTokenController>();
            log('📱 [InitialLoadingScreen] Found existing FcmTokenController');
          } else {
            fcmController = Get.put(FcmTokenController());
            log('📱 [InitialLoadingScreen] Created new FcmTokenController');
          }
          
          // Refresh token (this will update backend if token changed)
          log('🔄 [InitialLoadingScreen] Calling refreshToken()...');
          await fcmController.refreshToken();
          log('✅ [InitialLoadingScreen] refreshToken() completed');
          
          // Ensure notification handler is initialized
          log('🔄 [InitialLoadingScreen] Initializing NotificationHandlerService...');
          await NotificationHandlerService().initialize(forceReinitialize: false);
          log('✅ [InitialLoadingScreen] NotificationHandlerService initialized');
          
          log('✅ [InitialLoadingScreen] FCM token refreshed and notifications initialized');
          log('🔄 [InitialLoadingScreen] ==========================================');
        } catch (e, stackTrace) {
          log('❌ [InitialLoadingScreen] Error refreshing FCM token: $e');
          log('❌ [InitialLoadingScreen] Stack trace: $stackTrace');
          // Don't fail auth check if FCM refresh fails
        }
      }
      
      final statusData = await authService.checkUserStatus();
      return statusData != null ? 'dashboard' : 'login';
    } catch (_) {
      return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Loading...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
