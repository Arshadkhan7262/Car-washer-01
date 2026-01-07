import 'dart:developer';
import '../../../api/api_client.dart';
import '../../../models/add_vehicle_model.dart';

class VehicleService {
  final ApiClient _apiClient = ApiClient();

  /// Get all customer vehicles
  Future<List<AddVehicleModel>> getVehicles() async {
    try {
      final response = await _apiClient.get('/customer/vehicles');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch vehicles');
      }

      final List<dynamic> vehiclesData = response.data['data'] as List<dynamic>;
      final vehicles = vehiclesData.map((json) => AddVehicleModel.fromJson(json as Map<String, dynamic>)).toList();
      
      log('✅ [getVehicles] Fetched ${vehicles.length} vehicles');
      return vehicles;
    } catch (e) {
      log('❌ [getVehicles] Error: $e');
      throw Exception('Failed to fetch vehicles: ${e.toString()}');
    }
  }

  /// Create a new vehicle
  Future<AddVehicleModel> createVehicle({
    required String make,
    required String model,
    required String plateNumber,
    required String color,
    required String type,
    bool isDefault = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/vehicles',
        body: {
          'make': make,
          'model': model,
          'plate_number': plateNumber,
          'color': color,
          'type': type,
          'is_default': isDefault,
        },
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to create vehicle');
      }

      final vehicleData = response.data['data'] as Map<String, dynamic>;
      final vehicle = AddVehicleModel.fromJson(vehicleData);
      
      log('✅ [createVehicle] Vehicle created: ${vehicle.id}');
      return vehicle;
    } catch (e) {
      log('❌ [createVehicle] Error: $e');
      throw Exception('Failed to create vehicle: ${e.toString()}');
    }
  }

  /// Update a vehicle
  Future<AddVehicleModel> updateVehicle({
    required String vehicleId,
    String? make,
    String? model,
    String? plateNumber,
    String? color,
    String? type,
    bool? isDefault,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (make != null) body['make'] = make;
      if (model != null) body['model'] = model;
      if (plateNumber != null) body['plate_number'] = plateNumber;
      if (color != null) body['color'] = color;
      if (type != null) body['type'] = type;
      if (isDefault != null) body['is_default'] = isDefault;

      final response = await _apiClient.put(
        '/customer/vehicles/$vehicleId',
        body: body,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update vehicle');
      }

      final vehicleData = response.data['data'] as Map<String, dynamic>;
      final vehicle = AddVehicleModel.fromJson(vehicleData);
      
      log('✅ [updateVehicle] Vehicle updated: ${vehicle.id}');
      return vehicle;
    } catch (e) {
      log('❌ [updateVehicle] Error: $e');
      throw Exception('Failed to update vehicle: ${e.toString()}');
    }
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      final response = await _apiClient.delete('/customer/vehicles/$vehicleId');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to delete vehicle');
      }

      log('✅ [deleteVehicle] Vehicle deleted: $vehicleId');
    } catch (e) {
      log('❌ [deleteVehicle] Error: $e');
      throw Exception('Failed to delete vehicle: ${e.toString()}');
    }
  }

  /// Set vehicle as default
  Future<AddVehicleModel> setDefaultVehicle(String vehicleId) async {
    try {
      final response = await _apiClient.put(
        '/customer/vehicles/$vehicleId/default',
        body: {},
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to set default vehicle');
      }

      final vehicleData = response.data['data'] as Map<String, dynamic>;
      final vehicle = AddVehicleModel.fromJson(vehicleData);
      
      log('✅ [setDefaultVehicle] Default vehicle set: ${vehicle.id}');
      return vehicle;
    } catch (e) {
      log('❌ [setDefaultVehicle] Error: $e');
      throw Exception('Failed to set default vehicle: ${e.toString()}');
    }
  }
}

