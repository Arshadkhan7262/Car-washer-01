import 'dart:io';

/// Application Constants
class AppConstants {
  // API Configuration
  // IMPORTANT: Choose the correct URL based on your setup:
  // 
  // For Android Emulator: 'http://10.0.2.2:3000/api/v1'
  //   (10.0.2.2 is a special IP that maps to host's localhost)
  //
  // For Physical Android Device: 'http://192.168.18.31:3000/api/v1'
  //   (Use your computer's network IP address)
  //
  // For iOS Simulator: 'http://localhost:3000/api/v1'
  //
  // For Physical iOS Device: 'http://192.168.18.31:3000/api/v1'
  //
  // To switch: Change the value below and restart the app
  
  // Set to true if using Android Emulator, false for physical device
  static const bool isAndroidEmulator = false; // Change to true if using emulator
  
  static String get baseUrl {
    if (Platform.isAndroid) {
      if (isAndroidEmulator) {
        // Android Emulator uses special IP to access host machine
        return 'http://10.0.2.2:3000/api/v1';
      } else {
        // Physical Android device uses network IP
        return 'http://192.168.18.31:3000/api/v1';
      }
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost, physical device needs network IP
      // You may need to detect if it's simulator or device
      return 'http://192.168.18.31:3000/api/v1';
    } else {
      // Default to network IP
      return 'http://192.168.18.31:3000/api/v1';
    }
  }
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




