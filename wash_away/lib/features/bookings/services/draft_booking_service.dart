// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
/*
import 'dart:developer';
import '../../../api/api_client.dart';
import '../../../models/draft_booking_model.dart';

class DraftBookingService {
  final ApiClient _apiClient = ApiClient();

  /// Save draft booking
  Future<void> saveDraft(DraftBooking draft) async {
    try {
      final response = await _apiClient.post(
        '/customer/bookings/draft',
        body: draft.toJson(),
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to save draft');
      }

      log('✅ [saveDraft] Draft saved successfully at step ${draft.step}');
    } catch (e) {
      log('❌ [saveDraft] Error: $e');
      throw Exception('Failed to save draft: ${e.toString()}');
    }
  }

  /// Get draft booking
  Future<DraftBooking?> getDraft() async {
    try {
      final response = await _apiClient.get('/customer/bookings/draft');

      if (!response.success) {
        if (response.statusCode == 404) {
          return null; // No draft exists
        }
        throw Exception(response.error ?? 'Failed to get draft');
      }

      final draftData = response.data['data'] as Map<String, dynamic>;
      log('✅ [getDraft] Draft retrieved: step ${draftData['step']}');
      return DraftBooking.fromJson(draftData);
    } catch (e) {
      log('❌ [getDraft] Error: $e');
      return null;
    }
  }

  /// Check if draft exists
  Future<bool> checkDraftExists() async {
    try {
      final response = await _apiClient.get('/customer/bookings/draft/check');

      if (!response.success) {
        return false;
      }

      return response.data['has_draft'] ?? false;
    } catch (e) {
      log('❌ [checkDraftExists] Error: $e');
      return false;
    }
  }

  /// Delete draft booking
  Future<void> deleteDraft() async {
    try {
      final response = await _apiClient.delete('/customer/bookings/draft');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to delete draft');
      }

      log('✅ [deleteDraft] Draft deleted successfully');
    } catch (e) {
      log('❌ [deleteDraft] Error: $e');
      throw Exception('Failed to delete draft: ${e.toString()}');
    }
  }
}
*/
