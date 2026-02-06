import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash screen to show (minimum 2 seconds for better UX)
    await Future.delayed(const Duration(seconds: 2));

    final authService = AuthService();
    String targetRoute = AppRoutes.login;
    Map<String, dynamic>? routeArguments;

    try {
      // Check if user has stored token (logged in) - PRIORITY CHECK
      // If logged in, go directly to dashboard (OTP was already verified)
      final isLoggedIn = await authService.isLoggedIn();
      
      if (isLoggedIn) {
        // User has token - OTP was verified, go directly to dashboard
        final cachedStatus = await authService.getCachedAccountStatus();
        
        if (cachedStatus == 'pending') {
          targetRoute = AppRoutes.dashboard;
          routeArguments = {'isPending': true};
        } else if (cachedStatus == 'suspended') {
          targetRoute = AppRoutes.dashboard;
          routeArguments = {'isSuspended': true};
        } else if (cachedStatus == 'active') {
          targetRoute = AppRoutes.dashboard;
        } else {
          // No cached status - check API (but don't block too long)
          try {
            final statusData = await authService.checkUserStatus().timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );

            if (statusData != null) {
              final washerStatus = statusData['washer']?['status'] ?? statusData['status'];

              if (washerStatus == 'active') {
                targetRoute = AppRoutes.dashboard;
              } else if (washerStatus == 'pending') {
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isPending': true};
              } else if (washerStatus == 'suspended') {
                // Account is suspended - logout and show suspended overlay
                await authService.logout();
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isSuspended': true};
              } else {
                await authService.logout();
                targetRoute = AppRoutes.login;
              }
            } else {
              // API call failed or timed out - use cached status or show dashboard
              if (cachedStatus == 'pending') {
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isPending': true};
              } else if (cachedStatus == 'suspended') {
                // Account is suspended - logout and show suspended overlay
                await authService.logout();
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isSuspended': true};
              } else if (cachedStatus == 'active') {
                targetRoute = AppRoutes.dashboard;
              } else {
                // Default to dashboard if logged in but no status (shouldn't happen)
                targetRoute = AppRoutes.dashboard;
              }
            }
          } catch (e) {
            // On error, use cached status or show dashboard
            if (cachedStatus == 'pending') {
              targetRoute = AppRoutes.dashboard;
              routeArguments = {'isPending': true};
            } else if (cachedStatus == 'suspended') {
              // Account is suspended - logout and show suspended overlay
              await authService.logout();
              targetRoute = AppRoutes.dashboard;
              routeArguments = {'isSuspended': true};
            } else if (cachedStatus == 'active') {
              targetRoute = AppRoutes.dashboard;
            } else {
              // Default to dashboard if logged in
              targetRoute = AppRoutes.dashboard;
            }
          }
        }
      } else {
        // Not logged in - check for pending email verification or cached status
        final cachedStatus = await authService.getCachedAccountStatus();
        final emailNotVerified = await authService.isEmailNotVerified();
        final registrationEmail = await authService.getUserEmail();

        // If account created but email not verified, verify account exists first
        if (emailNotVerified && registrationEmail != null) {
          // CRITICAL: Verify account exists in database before showing OTP screen
          // This prevents showing OTP screen for deleted accounts
          try {
            final statusData = await authService.checkUserStatus().timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );
            
            if (statusData == null) {
              // Account doesn't exist (404) or API failed - clear cache and show login
              log('⚠️ Account not found in database, clearing cache');
              await authService.logout();
              targetRoute = AppRoutes.login;
            } else {
              // Account exists - check if email is still not verified
              final emailVerified = statusData['email_verified'] ?? false;
              if (!emailVerified) {
                // Email still not verified - show OTP screen
                targetRoute = AppRoutes.emailOtpVerify;
                routeArguments = {
                  'email': registrationEmail,
                  'isRegistration': true,
                };
              } else {
                // Email was verified but account might be pending - check status
                final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
                if (washerStatus == 'pending') {
                  targetRoute = AppRoutes.dashboard;
                  routeArguments = {'isPending': true};
                } else if (washerStatus == 'suspended') {
                  // Account is suspended - logout and show suspended overlay
                  await authService.logout();
                  targetRoute = AppRoutes.dashboard;
                  routeArguments = {'isSuspended': true};
                } else if (washerStatus == 'active') {
                  targetRoute = AppRoutes.dashboard;
                } else {
                  // Unknown status - clear cache and show login
                  await authService.logout();
                  targetRoute = AppRoutes.login;
                }
              }
            }
          } catch (e) {
            // On error checking status, clear cache and show login
            log('❌ Error checking account status: $e');
            await authService.logout();
            targetRoute = AppRoutes.login;
          }
        } else {
        // Not logged in - check cached status
        // CRITICAL: Verify account exists before using cached status
        if (cachedStatus != null || registrationEmail != null) {
          try {
            final statusData = await authService.checkUserStatus().timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );
            
            if (statusData == null) {
              // Account doesn't exist (404) or API failed - clear cache and show login
              log('⚠️ Account not found in database, clearing cache');
              await authService.logout();
              targetRoute = AppRoutes.login;
            } else {
              // Account exists - use status from API
              final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
              if (washerStatus == 'pending') {
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isPending': true};
              } else if (washerStatus == 'suspended') {
                // Account is suspended - logout and show suspended overlay
                await authService.logout();
                targetRoute = AppRoutes.dashboard;
                routeArguments = {'isSuspended': true};
              } else if (washerStatus == 'active') {
                // Account is active but no token - user needs to login
                targetRoute = AppRoutes.login;
              } else {
                // Unknown status - clear cache and show login
                await authService.logout();
                targetRoute = AppRoutes.login;
              }
            }
          } catch (e) {
            // On error checking status, clear cache and show login
            log('❌ Error checking account status: $e');
            await authService.logout();
            targetRoute = AppRoutes.login;
          }
        }
        // If no cached status, show login screen (default)
      }}
    } catch (e) {
      // On any error, navigate to login
      targetRoute = AppRoutes.login;
    }

    // Navigate to target route
    if (routeArguments != null) {
      Get.offAllNamed(targetRoute, arguments: routeArguments);
    } else {
      Get.offAllNamed(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031E3D), // App primary color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_car_wash,
                size: 70,
                color: Color(0xFF031E3D),
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            const Text(
              'Car Wash Pro',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional Car Washing Service',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
