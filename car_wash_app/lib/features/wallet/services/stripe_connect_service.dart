import 'dart:developer';
import '../../../api/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Stripe Connect Service
/// Handles Stripe Connect account setup for washer payouts
class StripeConnectService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  /// Create Stripe Connect account
  Future<Map<String, dynamic>?> createAccount() async {
    try {
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await _apiClient.post('/washer/stripe-connect/create');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to create Stripe Connect account';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'account_id': data['account_id'],
        'onboarding_url': data['onboarding_url'],
        'expires_at': data['expires_at'],
      };
    } catch (e) {
      log('❌ [StripeConnectService] Error creating account: $e');
      throw Exception('Failed to create Stripe Connect account: ${e.toString()}');
    }
  }

  /// Get onboarding link for existing account
  Future<Map<String, dynamic>?> getOnboardingLink() async {
    try {
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await _apiClient.get('/washer/stripe-connect/onboarding-link');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to get onboarding link';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'account_id': data['account_id'],
        'onboarding_url': data['onboarding_url'],
        'expires_at': data['expires_at'],
        'status': data['status'],
      };
    } catch (e) {
      log('❌ [StripeConnectService] Error getting onboarding link: $e');
      throw Exception('Failed to get onboarding link: ${e.toString()}');
    }
  }

  /// Get account status
  Future<Map<String, dynamic>?> getAccountStatus() async {
    try {
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await _apiClient.get('/washer/stripe-connect/status');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to get account status';
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      return {
        'success': true,
        'has_account': data['has_account'] ?? false,
        'status': data['status'] ?? 'none',
        'can_withdraw': data['can_withdraw'] ?? false,
        'account_id': data['account_id'],
        'message': data['message'] ?? '',
      };
    } catch (e) {
      log('❌ [StripeConnectService] Error getting account status: $e');
      throw Exception('Failed to get account status: ${e.toString()}');
    }
  }
}
