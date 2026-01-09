import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../util/constants.dart';
import 'api_checker.dart';

/// API Client for making HTTP requests
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get authentication token
  String? get authToken => _authToken;

  /// Check if backend server is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final healthUrl = Uri.parse('${AppConstants.baseUrl}/health');
      final response = await http
          .get(healthUrl)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      log('⚠️ Backend health check failed: $e');
      return false;
    }
  }

  /// Get base headers
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      // Check connectivity
      if (!await ApiChecker.hasConnection()) {
        return ApiResponse(success: false, error: 'No internet connection');
      }

      // Build URL
      Uri uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final requestHeaders = _getHeaders(additionalHeaders: headers);

      // Log request
      log('═══════════════════════════════════════════════════════════');
      log('🌐 API REQUEST [GET]');
      log('URL: $uri');
      log('Headers: ${jsonEncode(requestHeaders)}');
      log('───────────────────────────────────────────────────────────');

      // Make request with timeout
      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout after ${AppConstants.connectionTimeout}ms. '
                'Please check if the backend server is running at $uri',
                Duration(milliseconds: AppConstants.connectionTimeout),
              );
            },
          );

      // Log response
      log('📥 API RESPONSE [GET]');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');
      log('═══════════════════════════════════════════════════════════');

      return _handleResponse(response);
    } catch (e) {
      log('❌ API ERROR [GET]');
      log('Error: $e');
      log('═══════════════════════════════════════════════════════════');
      
      // Provide more helpful error messages
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout. Please ensure the backend server is running at ${AppConstants.baseUrl}';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your network connection and ensure the backend is running.';
      }
      
      return ApiResponse(success: false, error: errorMessage);
    }
  }

  /// POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      // Check connectivity
      if (!await ApiChecker.hasConnection()) {
        return ApiResponse(success: false, error: 'No internet connection');
      }

      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final requestHeaders = _getHeaders(additionalHeaders: headers);
      final requestBody = body != null ? jsonEncode(body) : null;

      // Log request
      log('═══════════════════════════════════════════════════════════');
      log('🌐 API REQUEST [POST]');
      log('URL: $url');
      log('Headers: ${jsonEncode(requestHeaders)}');
      log('Request Body: $requestBody');
      log('───────────────────────────────────────────────────────────');

      // Make request with timeout
      final response = await http
          .post(url, headers: requestHeaders, body: requestBody)
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout after ${AppConstants.connectionTimeout}ms. '
                'Please check if the backend server is running at $url',
                Duration(milliseconds: AppConstants.connectionTimeout),
              );
            },
          );

      // Log response
      log('📥 API RESPONSE [POST]');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');
      log('═══════════════════════════════════════════════════════════');

      return _handleResponse(response);
    } catch (e) {
      log('❌ API ERROR [POST]');
      log('Error: $e');
      log('═══════════════════════════════════════════════════════════');
      
      // Provide more helpful error messages
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout. Please ensure the backend server is running at ${AppConstants.baseUrl}';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your network connection and ensure the backend is running.';
      }
      
      return ApiResponse(success: false, error: errorMessage);
    }
  }

  /// PUT request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      // Check connectivity
      if (!await ApiChecker.hasConnection()) {
        return ApiResponse(success: false, error: 'No internet connection');
      }

      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final requestHeaders = _getHeaders(additionalHeaders: headers);
      final requestBody = body != null ? jsonEncode(body) : null;

      // Log request
      log('═══════════════════════════════════════════════════════════');
      log('🌐 API REQUEST [PUT]');
      log('URL: $url');
      log('Headers: ${jsonEncode(requestHeaders)}');
      log('Request Body: $requestBody');
      log('───────────────────────────────────────────────────────────');

      // Make request with timeout
      final response = await http
          .put(url, headers: requestHeaders, body: requestBody)
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout after ${AppConstants.connectionTimeout}ms. '
                'Please check if the backend server is running at $url',
                Duration(milliseconds: AppConstants.connectionTimeout),
              );
            },
          );

      // Log response
      log('📥 API RESPONSE [PUT]');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');
      log('═══════════════════════════════════════════════════════════');

      return _handleResponse(response);
    } catch (e) {
      log('❌ API ERROR [PUT]');
      log('Error: $e');
      log('═══════════════════════════════════════════════════════════');
      
      // Provide more helpful error messages
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout. Please ensure the backend server is running at ${AppConstants.baseUrl}';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your network connection and ensure the backend is running.';
      }
      
      return ApiResponse(success: false, error: errorMessage);
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      // Check connectivity
      if (!await ApiChecker.hasConnection()) {
        return ApiResponse(success: false, error: 'No internet connection');
      }

      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final requestHeaders = _getHeaders(additionalHeaders: headers);

      // Log request
      log('═══════════════════════════════════════════════════════════');
      log('🌐 API REQUEST [DELETE]');
      log('URL: $url');
      log('Headers: ${jsonEncode(requestHeaders)}');
      log('───────────────────────────────────────────────────────────');

      // Make request with timeout
      final response = await http
          .delete(url, headers: requestHeaders)
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout after ${AppConstants.connectionTimeout}ms. '
                'Please check if the backend server is running at $url',
                Duration(milliseconds: AppConstants.connectionTimeout),
              );
            },
          );

      // Log response
      log('📥 API RESPONSE [DELETE]');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');
      log('═══════════════════════════════════════════════════════════');

      return _handleResponse(response);
    } catch (e) {
      log('❌ API ERROR [DELETE]');
      log('Error: $e');
      log('═══════════════════════════════════════════════════════════');
      
      // Provide more helpful error messages
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout. Please ensure the backend server is running at ${AppConstants.baseUrl}';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your network connection and ensure the backend is running.';
      }
      
      return ApiResponse(success: false, error: errorMessage);
    }
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        // Extract error message from various possible response formats
        String errorMessage = 'Request failed';
        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['error'] != null) {
          if (data['error'] is String) {
            errorMessage = data['error'];
          } else if (data['error']['message'] != null) {
            errorMessage = data['error']['message'];
          }
        }
        return ApiResponse(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }
}

/// API Response Model
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}

