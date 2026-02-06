/// Application Constants
class AppConstants {
  // API Configuration
  // IMPORTANT: localhost doesn't work on Android emulator or physical devices!
  // 
  // Choose the correct URL based on your setup:
  // 
  // 1. Android Emulator: Use 10.0.2.2 (maps to host machine's localhost)
  //    Example: 'http://10.0.2.2:3000/api/v1'
  // 
  // 2. Physical Device (same network): Use your computer's network IP
  //    Example: 'http://192.168.168.196:3000/api/v1'
  //    To find IP: Check backend terminal - it shows "Network API URL: http://YOUR_IP:3000/api/v1"
  // 
  // 3. ngrok: Use the ngrok HTTPS URL
  //    Example: 'https://abc123.ngrok-free.app/api/v1'
  //    Note: If using ngrok, make sure to add /api/v1 at the end
  // 
  // 4. iOS Simulator: Use localhost (works on iOS Simulator)
  //    Example: 'http://localhost:3000/api/v1'
  // 
  // Current setting: Physical Device - Use your computer's network IP
  // IMPORTANT: Replace 192.168.168.196 with YOUR computer's IP address
  // To find your IP: Check backend terminal when server starts
  // It shows: "Network API URL: http://YOUR_IP:3000/api/v1"
  static const String baseUrl =
      'https://weepy-unprotected-celestina.ngrok-free.dev/api/v1'; // Physical device - use your network IP
  static const int connectionTimeout = 60000; // 60 seconds (increased for withdrawal requests)
  static const int receiveTimeout = 60000; // 60 seconds

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';

  // App Configuration
  static const String appName = 'Car Wash Pro';
  static const String appVersion = '1.0.0';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;

  // Stripe Configuration
  static const String stripePublishableKey =
      'pk_test_51RLB5nPdbAWpbZ8zjW263HT7LnFIcz813twUFCpk5T6PR2MqGuoWdR8wmeWuHc19Gmb7zxWXWLL3pKEdqVMCHyVQ00XH7POBCZ';
  static const bool isStripeTestMode = true;
}
