import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class PendingApprovalOverlay extends StatefulWidget {
  const PendingApprovalOverlay({super.key});

  @override
  State<PendingApprovalOverlay> createState() => _PendingApprovalOverlayState();
}

class _PendingApprovalOverlayState extends State<PendingApprovalOverlay>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Timer? _pollingTimer;
  bool _isChecking = false;
  bool _isApproved = false;
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
    _checkApprovalStatus();

    // Then check every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkApprovalStatus();
    });
  }

  Future<void> _checkApprovalStatus() async {
    if (_isChecking || _isApproved) return;

    setState(() {
      _isChecking = true;
    });

    try {
      log('═══════════════════════════════════════════════════════════');
      log('🔄 PENDING APPROVAL OVERLAY - Checking Status');
      log('───────────────────────────────────────────────────────────');
      
      final statusData = await _authService.checkUserStatus();

      if (statusData != null) {
        // Check status from washer object first, then fallback to direct status
        final washerStatus = statusData['washer']?['status'] ?? statusData['status'];
        
        // Log full response for debugging
        log('📥 API RESPONSE RECEIVED:');
        log('Full Response Data: $statusData');
        log('───────────────────────────────────────────────────────────');
        log('📊 Status Details:');
        log('  - Washer Status: ${statusData['washer']?['status'] ?? 'N/A'}');
        log('  - Direct Status: ${statusData['status'] ?? 'N/A'}');
        log('  - Online Status: ${statusData['online_status'] ?? 'N/A'}');
        log('  - User ID: ${statusData['user']?['id'] ?? 'N/A'}');
        log('  - User Email: ${statusData['user']?['email'] ?? 'N/A'}');
        log('  - Washer ID: ${statusData['washer']?['id'] ?? 'N/A'}');
        log('───────────────────────────────────────────────────────────');
        log('🔍 Final Status Check: $washerStatus');
        log('═══════════════════════════════════════════════════════════');

        if (washerStatus == 'active') {
          log('✅ STATUS IS ACTIVE! Removing overlay...');
          setState(() {
            _isApproved = true;
          });
          _pollingTimer?.cancel();
          _animationController.stop();

          // Wait a moment then hide overlay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            // Use Navigator.of(context, rootNavigator: true) to ensure we pop the dialog
            Navigator.of(context, rootNavigator: true).pop(); // Remove overlay
            log('✅ Overlay removed successfully');
          }
        } else if (washerStatus == 'suspended') {
          log('🚫 STATUS IS SUSPENDED! Closing pending overlay...');
          // Close this overlay - suspended overlay will be shown by dashboard
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } else {
          log('⏳ Status is still: $washerStatus (waiting for approval...)');
          log('   Next check in 2 seconds...');
        }
      } else {
        log('⚠️ STATUS DATA IS NULL');
        log('   Response was null - token may be invalid or user not authenticated');
        log('═══════════════════════════════════════════════════════════');
      }
    } catch (e, stackTrace) {
      // Log errors for debugging
      log('❌ ERROR CHECKING APPROVAL STATUS');
      log('Error: $e');
      log('Stack Trace: $stackTrace');
      log('═══════════════════════════════════════════════════════════');
      // Keep polling even on error
    } finally {
      if (mounted && !_isApproved) {
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
                  Icons.pending_outlined,
                  size: 64,
                  color: Color(0xFF031E3D),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Account Status is Pending",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0E16),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Waiting for admin approval",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
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
                            color: const Color(0xFF031E3D).withOpacity(opacity),
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

