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

  /// Request withdrawal
  Future<bool> requestWithdrawal(double amount) async {
    try {
      final response = await _apiClient.post(
        '/washer/wallet/withdraw',
        body: {
          'amount': amount,
        },
      );

      if (!response.success) {
        print('Error requesting withdrawal: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception requesting withdrawal: $e');
      return false;
    }
  }
}

