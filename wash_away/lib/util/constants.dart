import '../config/env_config.dart';

/// Application Constants
/// Now uses .env file for configuration via EnvConfig
class AppConstants {
  // API Configuration - Now loaded from .env file
  // Configure in .env file: API_BASE_URL
  static String get baseUrl => EnvConfig.baseUrl;
  
  static int get connectionTimeout => EnvConfig.connectionTimeout;
  static int get receiveTimeout => EnvConfig.receiveTimeout;

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';

  // App Configuration
  static const String appName = 'Wash Away';
  static const String appVersion = '1.0.0';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // Stripe Configuration - Now loaded from .env file
  // Configure in .env file: STRIPE_PUBLISHABLE_KEY
  // IMPORTANT: Must match your backend STRIPE_SECRET_KEY account
  // Get from: https://dashboard.stripe.com/test/apikeys
  static String get stripePublishableKey => EnvConfig.stripePublishableKey;
  
  // Apple Pay Configuration - Now loaded from .env file
  // Configure in .env file: APPLE_PAY_MERCHANT_IDENTIFIER
  // Format: merchant.com.yourcompany.appname
  static String get applePayMerchantIdentifier => EnvConfig.applePayMerchantIdentifier;
  
  /// Validate Stripe configuration
  /// Returns true if Stripe keys are properly configured
  static bool validateStripeConfig() => EnvConfig.validateStripeConfig();
  
  /// Check if using Stripe test mode
  static bool get isStripeTestMode => EnvConfig.isStripeTestMode;
}




