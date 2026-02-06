import 'dart:developer';
import '../../../api/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Bank Account Service
/// Handles bank account management for washers
class BankAccountService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  /// Get bank account details
  Future<Map<String, dynamic>?> getBankAccount() async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) {
        // Return null if not authenticated instead of throwing
        return null;
      }
      
      _apiClient.setAuthToken(token);

      final response = await _apiClient.get('/washer/bank-account');

      if (!response.success) {
        // If 404 or no account, return null instead of throwing
        if (response.statusCode == 404 || response.error?.contains('not found') == true) {
          return null;
        }
        String errorMessage = response.error ?? 'Failed to get bank account';
        throw Exception(errorMessage);
      }

      return response.data['data'];
    } catch (e) {
      log('❌ [BankAccountService] Error getting bank account: $e');
      // Return null instead of throwing to prevent crashes
      return null;
    }
  }

  /// Save bank account details
  Future<Map<String, dynamic>?> saveBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String routingNumber,
    required String accountType,
    String? bankName,
  }) async {
    try {
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await _apiClient.post(
        '/washer/bank-account',
        body: {
          'account_holder_name': accountHolderName,
          'account_number': accountNumber,
          'routing_number': routingNumber,
          'account_type': accountType, // 'checking' or 'savings'
          if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName,
        },
      );

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to save bank account';
        throw Exception(errorMessage);
      }

      return response.data['data'];
    } catch (e) {
      log('❌ [BankAccountService] Error saving bank account: $e');
      throw Exception('Failed to save bank account: ${e.toString()}');
    }
  }

  /// Delete bank account
  Future<bool> deleteBankAccount() async {
    try {
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await _apiClient.delete('/washer/bank-account');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to delete bank account';
        throw Exception(errorMessage);
      }

      return true;
    } catch (e) {
      log('❌ [BankAccountService] Error deleting bank account: $e');
      throw Exception('Failed to delete bank account: ${e.toString()}');
    }
  }
}
