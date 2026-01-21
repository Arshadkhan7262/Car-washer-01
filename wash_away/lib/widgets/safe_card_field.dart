import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

/// Safe wrapper for Stripe CardField that handles initialization errors
class SafeCardField extends StatefulWidget {
  final CardChangedCallback? onCardChanged;

  const SafeCardField({
    super.key,
    this.onCardChanged,
  });

  @override
  State<SafeCardField> createState() => _SafeCardFieldState();
}

class _SafeCardFieldState extends State<SafeCardField> {
  bool _isInitialized = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ensureStripeInitialized();
  }

  Future<void> _ensureStripeInitialized() async {
    try {
      // Check if publishable key is set
      final publishableKey = Stripe.publishableKey;
      if (publishableKey.isEmpty || 
          publishableKey == 'pk_test_your_publishable_key_here' ||
          !publishableKey.startsWith('pk_')) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Stripe publishable key not configured';
          });
        }
        return;
      }

      // Ensure Stripe SDK is initialized on native side
      // This is critical for Android - the native SDK must be initialized before CardField
      try {
        await Stripe.instance.applySettings();
        // Add a small delay to ensure native initialization completes
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Failed to initialize Stripe: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Stripe initialization error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading while initializing
    if (_isInitializing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if initialization failed
    if (!_isInitialized || _errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(height: 12),
            Text(
              'Card Payment Unavailable',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please configure Stripe publishable key in util/constants.dart',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can still use Wallet, Cash, or other payment methods.',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textTertiary : LightTheme.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Only render CardField after Stripe is fully initialized
    return _CardFieldWrapper(
      onCardChanged: widget.onCardChanged,
      isDark: isDark,
    );
  }
}

/// Wrapper widget to catch platform view errors
class _CardFieldWrapper extends StatefulWidget {
  final CardChangedCallback? onCardChanged;
  final bool isDark;

  const _CardFieldWrapper({
    required this.onCardChanged,
    required this.isDark,
  });

  @override
  State<_CardFieldWrapper> createState() => _CardFieldWrapperState();
}

class _CardFieldWrapperState extends State<_CardFieldWrapper> {
  bool _hasPlatformError = false;
  void Function(FlutterErrorDetails)? _originalErrorHandler;

  @override
  void initState() {
    super.initState();
    // Set up error handler to catch platform view errors
    _originalErrorHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is a platform view error
      if (details.exception.toString().contains('platform_views') ||
          details.exception.toString().contains('CardField') ||
          details.exception.toString().contains('MethodChannel')) {
        if (mounted) {
          setState(() {
            _hasPlatformError = true;
          });
        }
        // Don't call original handler for platform view errors to prevent crash
        return;
      }
      // Call original handler for other errors
      _originalErrorHandler?.call(details);
    };
  }

  @override
  void dispose() {
    // Restore original error handler
    if (_originalErrorHandler != null) {
      FlutterError.onError = _originalErrorHandler;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPlatformError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 12),
            Text(
              'Unable to load card input',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please use another payment method or configure Stripe properly.',
              style: GoogleFonts.inter(
                color: widget.isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Render CardField - it should be safe now after all initialization checks
    return CardField(
      onCardChanged: widget.onCardChanged,
    );
  }
}

