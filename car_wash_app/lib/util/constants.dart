/// Application Constants
class AppConstants {
  // API Configuration - use the IP of the machine where the backend runs.
  // When backend starts it logs "Network API URL: http://YOUR_IP:3000/api/v1" - use that.
  // For Android emulator use: http://10.0.2.2:3000/api/v1
  static const String baseUrl =
      'http://192.168.18.7:3000/api/v1'; // Backend API URL (same PC as wash_away backend)
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

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
}
