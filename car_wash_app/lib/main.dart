import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? routeArguments;

  const MyApp({super.key, required this.initialRoute, this.routeArguments});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Car Wash Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // This is the "kill switch" for dark mode.
      initialRoute: initialRoute,
      getPages: AppRoutes.getRoutes(),
      initialBinding: routeArguments != null && routeArguments!['isPending'] == true
          ? null
          : null, // Dashboard binding will be handled by route
    );
  }
}
