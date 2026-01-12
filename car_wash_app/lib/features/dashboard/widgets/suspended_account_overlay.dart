import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class SuspendedAccountOverlay extends StatefulWidget {
  const SuspendedAccountOverlay({super.key});

  @override
  State<SuspendedAccountOverlay> createState() => _SuspendedAccountOverlayState();
}

class _SuspendedAccountOverlayState extends State<SuspendedAccountOverlay>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Timer? _pollingTimer;
  bool _isChecking = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Check immediately
    _checkAccountStatus();

    // Then check every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAccountStatus();
    });
  }

  Future<void> _checkAccountStatus() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      log('═══════════════════════════════════════════════════════════');
      log('🔄 SUSPENDED ACCOUNT OVERLAY - Checking Status');
      log('───────────────────────────────────────────────────────────');
      
      final statusData = await _authService.checkUserStatus();

      if (statusData != null) {
        final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
        
        log('📥 API RESPONSE RECEIVED:');
        log('Full Response Data: $statusData');
        log('───────────────────────────────────────────────────────────');
        log('🔍 Final Status Check: $washerStatus');
        log('═══════════════════════════════════════════════════════════');

        if (washerStatus == 'active') {
          log('✅ STATUS IS ACTIVE! Removing suspended overlay...');
          _pollingTimer?.cancel();
          _animationController.stop();

          // Wait a moment then hide overlay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            log('✅ Suspended overlay removed successfully');
          }
        } else if (washerStatus == 'pending') {
          log('⏳ Status changed to pending - closing suspended overlay');
          // Close suspended overlay - pending overlay will be shown
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
        // If still suspended, keep showing overlay
      }
    } catch (e, stackTrace) {
      log('❌ ERROR CHECKING ACCOUNT STATUS');
      log('Error: $e');
      log('Stack Trace: $stackTrace');
      log('═══════════════════════════════════════════════════════════');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.block,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Account Suspended",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0E16),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your account has been suspended by admin",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please contact admin for assistance",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Animated dots
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final animationValue = (_animationController.value + delay) % 1.0;
                        final opacity = (animationValue < 0.5)
                            ? animationValue * 2
                            : 2 - (animationValue * 2);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

