import 'dart:developer';
import '../api/api_client.dart';
import '../models/banner_model.dart';

class BannerService {
  final ApiClient _apiClient = ApiClient();

  /// Get active banners for home screen carousel (public endpoint)
  Future<List<Banner>> getActiveBanners() async {
    try {
      final response = await _apiClient.get('/customer/banners');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch banners');
      }

      final List<dynamic> bannersData = response.data['data'] ?? [];
      final List<Banner> banners = bannersData
          .map((json) => Banner.fromJson(json as Map<String, dynamic>))
          .toList();

      log('✅ [BannerService] Fetched ${banners.length} banners');
      return banners;
    } catch (e) {
      log('❌ [BannerService] Error: $e');
      rethrow;
    }
  }
}
