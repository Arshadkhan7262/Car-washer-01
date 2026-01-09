import '../../../api/api_client.dart';

/// Home Screen Service
/// Handles API calls for home screen dashboard stats
class HomeService {
  final ApiClient _apiClient = ApiClient();

  /// Get dashboard stats (today's jobs, earnings, total stats)
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/washer/home/stats');

      if (!response.success) {
        print('Error fetching dashboard stats: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching dashboard stats: $e');
      return null;
    }
  }

  /// Get period-based stats (today, week, month)
  Future<Map<String, dynamic>?> getPeriodStats(String period) async {
    try {
      final response = await _apiClient.get('/washer/home/stats/$period');

      if (!response.success) {
        print('Error fetching period stats: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching period stats: $e');
      return null;
    }
  }
}

