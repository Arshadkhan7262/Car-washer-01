/// Application Constants
class AppConstants {
  // API Configuration
  static const String baseUrl =
      'http://192.168.18.40:3000/api/v1'; // Backend API URL - Update with your network IP
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

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
}




