import 'dart:developer';
import '../../../api/api_client.dart';
import '../../../models/service_model.dart';

class ServiceService {
  final ApiClient _apiClient = ApiClient();

  /// Get all active services
  Future<List<Service>> getAllServices({bool? isPopular}) async {
    try {
      final queryParams = <String, String>{
        'is_active': 'true',
        'sort': 'display_order',
        'limit': '50',
      };

      if (isPopular != null) {
        queryParams['is_popular'] = isPopular.toString();
      }

      final response = await _apiClient.get(
        '/customer/services',
        queryParameters: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch services');
      }

      final List<dynamic> servicesData = response.data['data'] ?? [];
      final List<Service> services = servicesData
          .map((json) => Service.fromJson(json as Map<String, dynamic>))
          .toList();

      log('✅ [getAllServices] Fetched ${services.length} services');
      return services;
    } catch (e) {
      log('❌ [getAllServices] Error: $e');
      throw Exception('Failed to fetch services: ${e.toString()}');
    }
  }

  /// Get service by ID
  Future<Service> getServiceById(String serviceId) async {
    try {
      final response = await _apiClient.get('/customer/services/$serviceId');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch service');
      }

      final serviceData = response.data['data'] as Map<String, dynamic>;
      final service = Service.fromJson(serviceData);

      log('✅ [getServiceById] Fetched service: ${service.name}');
      return service;
    } catch (e) {
      log('❌ [getServiceById] Error: $e');
      throw Exception('Failed to fetch service: ${e.toString()}');
    }
  }
}




