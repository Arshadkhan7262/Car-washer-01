import 'package:intl/intl.dart';

/// Date and Time Formatting Helper
class DateFormatter {
  /// Format date to yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  /// Format time to HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  /// Format date and time to yyyy-MM-dd HH:mm
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
  
  /// Format date to readable format (e.g., "Jan 15, 2024")
  static String formatDateReadable(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  /// Format date to readable format with time (e.g., "Jan 15, 2024 at 3:30 PM")
  static String formatDateTimeReadable(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(date);
  }
  
  /// Format currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }
  
  /// Format number
  static String formatNumber(double number) {
    return NumberFormat('#,##0.00').format(number);
  }
  
  /// Parse date string to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse date time string to DateTime
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
}

