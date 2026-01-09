import '../../../api/api_client.dart';

/// Profile Screen Service
/// Handles API calls for profile management
class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Get washer profile
  Future<Map<String, dynamic>?> getWasherProfile() async {
    try {
      final response = await _apiClient.get('/washer/profile');

      if (!response.success) {
        print('Error fetching profile: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching profile: $e');
      return null;
    }
  }

  /// Update washer profile
  Future<bool> updateWasherProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final response = await _apiClient.put(
        '/washer/profile',
        body: body,
      );

      if (!response.success) {
        print('Error updating profile: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception updating profile: $e');
      return false;
    }
  }

  /// Toggle online status
  Future<bool> toggleOnlineStatus(bool onlineStatus) async {
    try {
      final response = await _apiClient.put(
        '/washer/profile/online-status',
        body: {
          'online_status': onlineStatus,
        },
      );

      if (!response.success) {
        print('Error updating online status: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception updating online status: $e');
      return false;
    }
  }
}

