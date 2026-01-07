import 'dart:developer';
import '../../../api/api_client.dart';
import '../../../models/vehicle_type_model.dart';

class VehicleTypeService {
  final ApiClient _apiClient = ApiClient();

  /// Get all active vehicle types
  Future<List<VehicleType>> getAllVehicleTypes() async {
    try {
      final response = await _apiClient.get('/customer/vehicle-types');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch vehicle types');
      }

      final List<dynamic> vehicleTypesData = response.data['data'] ?? [];
      final List<VehicleType> vehicleTypes = vehicleTypesData
          .map((json) => VehicleType.fromJson(json as Map<String, dynamic>))
          .toList();

      log('✅ [getAllVehicleTypes] Fetched ${vehicleTypes.length} vehicle types');
      return vehicleTypes;
    } catch (e) {
      log('❌ [getAllVehicleTypes] Error: $e');
      throw Exception('Failed to fetch vehicle types: ${e.toString()}');
    }
  }
}


