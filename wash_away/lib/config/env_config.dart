import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

/// Environment Configuration
/// Loads configuration from .env file
class EnvConfig {
  static bool _initialized = false;

  /// Initialize environment variables from .env file
  /// Call this in main() before using any env variables
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
      print('✅ Environment variables loaded from .env');
    } catch (e) {
      print('⚠️ Failed to load .env file: $e');
      print('⚠️ Using default values. Please create .env file from .env.example');
      _initialized = false;
    }
  }

  /// Get API base URL from .env or use default
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url != null && url.isNotEmpty) {
      return url;
    }
    
    // Fallback when .env missing: set to your PC IP (same WiFi as device)
    if (Platform.isAndroid) {
      return 'http://192.168.18.29:3000/api/v1';
    } else if (Platform.isIOS) {
      return 'http://192.168.18.29:3000/api/v1';
    }
    return 'http://192.168.18.29:3000/api/v1';
  }

  /// Get Stripe publishable key from .env
  /// Returns empty string if not found (will be handled by Stripe initialization)
  static String get stripePublishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key != null && key.isNotEmpty && key != 'pk_test_your_publishable_key_here') {
      return key;
    }
    return '';
  }

  /// Get Apple Pay merchant identifier from .env
  static String get applePayMerchantIdentifier {
    return dotenv.env['APPLE_PAY_MERCHANT_IDENTIFIER'] ?? '';
  }

  /// Get connection timeout from .env (default: 60000ms)
  static int get connectionTimeout {
    final timeout = dotenv.env['CONNECTION_TIMEOUT'];
    if (timeout != null) {
      return int.tryParse(timeout) ?? 60000;
    }
    return 60000;
  }

  /// Get receive timeout from .env (default: 60000ms)
  static int get receiveTimeout {
    final timeout = dotenv.env['RECEIVE_TIMEOUT'];
    if (timeout != null) {
      return int.tryParse(timeout) ?? 60000;
    }
    return 60000;
  }

  /// Validate Stripe configuration
  /// Returns true if Stripe is properly configured
  static bool validateStripeConfig() {
    final key = stripePublishableKey;
    if (key.isEmpty) {
      print('❌ Stripe publishable key not found in .env');
      print('   Please add STRIPE_PUBLISHABLE_KEY to your .env file');
      print('   Get it from: https://dashboard.stripe.com/test/apikeys');
      print('   ⚠️  IMPORTANT: Must match your backend STRIPE_SECRET_KEY account!');
      return false;
    }
    
    // Validate key format
    if (!key.startsWith('pk_test_') && !key.startsWith('pk_live_')) {
      print('❌ Invalid Stripe publishable key format. Must start with pk_test_ or pk_live_');
      print('   Current key: ${key.length > 20 ? key.substring(0, 20) + "..." : key}');
      return false;
    }
    
    // Extract key ID for validation (the part after pk_test_ or pk_live_)
    final keyParts = key.split('_');
    if (keyParts.length >= 3) {
      final keyId = keyParts[2];
      print('✅ Stripe publishable key validated');
      print('   Mode: ${key.startsWith('pk_test_') ? 'TEST' : 'LIVE'}');
      print('   Key ID: ${keyId.length > 12 ? keyId.substring(0, 12) + "..." : keyId}');
      print('   ⚠️  Ensure backend STRIPE_SECRET_KEY matches this account!');
      print('   Backend key should start with: ${key.startsWith('pk_test_') ? 'sk_test_' : 'sk_live_'}$keyId');
    } else {
      print('✅ Stripe publishable key validated: ${key.substring(0, 12)}...');
    }
    
    return true;
  }

  /// Check if using test or live Stripe keys
  static bool get isStripeTestMode {
    final key = stripePublishableKey;
    return key.startsWith('pk_test_');
  }
}

