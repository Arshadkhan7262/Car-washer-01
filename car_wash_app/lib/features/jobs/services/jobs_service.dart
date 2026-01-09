import '../../../api/api_client.dart';

/// Jobs Screen Service
/// Handles API calls for job management
class JobsService {
  final ApiClient _apiClient = ApiClient();

  /// Get all jobs for washer
  Future<Map<String, dynamic>?> getWasherJobs({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        '/washer/jobs',
        queryParameters: queryParams,
      );

      if (!response.success) {
        print('Error fetching jobs: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching jobs: $e');
      return null;
    }
  }

  /// Get job by ID
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final response = await _apiClient.get('/washer/jobs/$jobId');

      if (!response.success) {
        print('Error fetching job: ${response.error}');
        return null;
      }

      return response.data['data'];
    } catch (e) {
      print('Exception fetching job: $e');
      return null;
    }
  }

  /// Accept a job
  Future<bool> acceptJob(String jobId) async {
    try {
      final response = await _apiClient.post(
        '/washer/jobs/$jobId/accept',
        body: {},
      );

      if (!response.success) {
        print('Error accepting job: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception accepting job: $e');
      return false;
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(
    String jobId,
    String status, {
    String? note,
  }) async {
    try {
      final response = await _apiClient.put(
        '/washer/jobs/$jobId/status',
        body: {
          'status': status,
          if (note != null) 'note': note,
        },
      );

      if (!response.success) {
        print('Error updating job status: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception updating job status: $e');
      return false;
    }
  }

  /// Reject a job
  Future<bool> rejectJob(String jobId, {String? reason}) async {
    try {
      final response = await _apiClient.post(
        '/washer/jobs/$jobId/reject',
        body: {
          if (reason != null) 'reason': reason,
        },
      );

      if (!response.success) {
        print('Error rejecting job: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception rejecting job: $e');
      return false;
    }
  }

  /// Complete a job
  Future<bool> completeJob(String jobId, {String? note}) async {
    try {
      final response = await _apiClient.post(
        '/washer/jobs/$jobId/complete',
        body: {
          if (note != null) 'note': note,
        },
      );

      if (!response.success) {
        print('Error completing job: ${response.error}');
        return false;
      }

      return true;
    } catch (e) {
      print('Exception completing job: $e');
      return false;
    }
  }
}

