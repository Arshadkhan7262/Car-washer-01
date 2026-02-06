import '../../../api/api_client.dart';

/// Wallet Screen Service
/// Handles API calls for wallet management
class WalletService {
  final ApiClient _apiClient = ApiClient();

  /// Get wallet balance
  Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final response = await _apiClient.get('/washer/wallet/balance');

      if (!response.success) {
        print('Error fetching wallet balance: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching wallet balance: $e');
      return null;
    }
  }

  /// Get wallet stats by period (today, week, month)
  Future<Map<String, dynamic>?> getWalletStats(String period) async {
    try {
      final response = await _apiClient.get(
        '/washer/wallet/stats',
        queryParameters: {'period': period},
      );

      if (!response.success) {
        print('Error fetching wallet stats: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching wallet stats: $e');
      return null;
    }
  }

  /// Get transaction history
  Future<Map<String, dynamic>?> getTransactions({
    String period = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/washer/wallet/transactions',
        queryParameters: {
          'period': period,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (!response.success) {
        print('Error fetching transactions: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching transactions: $e');
      return null;
    }
  }

  /// Get minimum withdrawal limit
  Future<double?> getWithdrawalLimit() async {
    try {
      final response = await _apiClient.get('/washer/withdrawal/limit');

      if (!response.success) {
        print('Error fetching withdrawal limit: ${response.error}');
        return null;
      }

      return (response.data['data']['minimum_limit'] ?? 2000).toDouble();
    } catch (e) {
      print('Exception fetching withdrawal limit: $e');
      return 2000.0; // Default fallback
    }
  }

  /// Request withdrawal
  Future<Map<String, dynamic>?> requestWithdrawal(double amount) async {
    try {
      // Use longer timeout for withdrawal requests (60 seconds)
      // The timeout is handled in api_client.dart for withdrawal endpoints
      final response = await _apiClient.post(
        '/washer/withdrawal/request',
        body: {
          'amount': amount,
          'currency': 'usd',
        },
      );

      if (!response.success) {
        return {
          'success': false,
          'error': response.error ?? 'Failed to request withdrawal',
        };
      }

      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      print('Exception requesting withdrawal: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get withdrawal history
  Future<List<dynamic>?> getWithdrawalHistory({String? status}) async {
    try {
      final response = await _apiClient.get(
        '/washer/withdrawal',
        queryParameters: status != null ? {'status': status} : null,
      );

      if (!response.success) {
        print('Error fetching withdrawal history: ${response.error}');
        return null;
      }

      return response.data['data'] as List<dynamic>?;
    } catch (e) {
      print('Exception fetching withdrawal history: $e');
      return null;
    }
  }

  /// Cancel withdrawal request
  Future<bool> cancelWithdrawal(String withdrawalId) async {
    try {
      final response = await _apiClient.put(
        '/washer/withdrawal/$withdrawalId/cancel',
      );

      if (!response.success) {
        print('Error cancelling withdrawal: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception cancelling withdrawal: $e');
      return false;
    }
  }

  /// Process approved withdrawal via Stripe
  Future<Map<String, dynamic>?> processApprovedWithdrawal(String withdrawalId) async {
    try {
      final response = await _apiClient.post(
        '/washer/withdrawal/$withdrawalId/process',
      );

      if (!response.success) {
        return {
          'success': false,
          'error': response.error ?? 'Failed to process withdrawal',
        };
      }

      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      print('Exception processing withdrawal: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

