import 'dart:developer';
import '../../../api/api_client.dart';

class CouponService {
  final ApiClient _apiClient = ApiClient();

  /// Get available coupons for the current customer
  /// Returns list of available coupons
  Future<List<Map<String, dynamic>>> getAvailableCoupons() async {
    try {
      final response = await _apiClient.get('/customer/coupons');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to get coupons');
      }

      final couponsData = response.data['data'] as List<dynamic>;
      final coupons = couponsData.map((c) => c as Map<String, dynamic>).toList();
      log('✅ [getAvailableCoupons] Retrieved ${coupons.length} available coupons');
      
      return coupons;
    } catch (e) {
      log('❌ [getAvailableCoupons] Error: $e');
      throw Exception('Failed to get coupons: ${e.toString()}');
    }
  }

  /// Validate coupon code
  /// Returns coupon details with discount calculation
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double orderValue,
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/coupons/validate',
        body: {
          'code': code.toUpperCase().trim(),
          'order_value': orderValue,
        },
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to validate coupon');
      }

      final couponData = response.data['data'] as Map<String, dynamic>;
      log('✅ [validateCoupon] Coupon validated: ${couponData['coupon']['code']}');
      log('💰 [validateCoupon] Discount: \$${couponData['discount']}, Final Total: \$${couponData['total']}');
      
      return couponData;
    } catch (e) {
      log('❌ [validateCoupon] Error: $e');
      throw Exception('Failed to validate coupon: ${e.toString()}');
    }
  }
}
