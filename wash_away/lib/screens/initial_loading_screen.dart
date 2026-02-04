import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/notifications/controllers/fcm_token_controller.dart';
import '../features/notifications/services/notification_handler_service.dart';

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
    final authService = AuthService();
    final Future<String> authTask = _runAuthCheck(authService);
    final Future<String> timeoutTask = Future<String>.delayed(
      _authTimeout,
      () => 'timeout',
    );
    final String result = await Future.any([authTask, timeoutTask]);
    if (!mounted) return;
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
