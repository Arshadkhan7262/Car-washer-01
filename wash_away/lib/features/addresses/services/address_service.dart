import 'dart:developer';
import '../../../api/api_client.dart';
import '../../../models/address_model.dart';

class AddressService {
  final ApiClient _apiClient = ApiClient();

  /// Get all customer addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _apiClient.get('/customer/addresses');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to fetch addresses');
      }

      final List<dynamic> addressesData = response.data['data'] as List<dynamic>;
      final addresses = addressesData.map((json) => Address.fromJson(json as Map<String, dynamic>)).toList();
      
      log('✅ [getAddresses] Fetched ${addresses.length} addresses');
      return addresses;
    } catch (e) {
      log('❌ [getAddresses] Error: $e');
      throw Exception('Failed to fetch addresses: ${e.toString()}');
    }
  }

  /// Create a new address
  Future<Address> createAddress({
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/addresses',
        body: {
          'label': label,
          'full_address': fullAddress,
          'latitude': latitude,
          'longitude': longitude,
          'is_default': isDefault,
        },
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to create address');
      }

      final addressData = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressData);
      
      log('✅ [createAddress] Address created: ${address.id}');
      return address;
    } catch (e) {
      log('❌ [createAddress] Error: $e');
      throw Exception('Failed to create address: ${e.toString()}');
    }
  }

  /// Update an address
  Future<Address> updateAddress({
    required String addressId,
    String? label,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (label != null) body['label'] = label;
      if (fullAddress != null) body['full_address'] = fullAddress;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (isDefault != null) body['is_default'] = isDefault;

      final response = await _apiClient.put(
        '/customer/addresses/$addressId',
        body: body,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update address');
      }

      final addressData = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressData);
      
      log('✅ [updateAddress] Address updated: ${address.id}');
      return address;
    } catch (e) {
      log('❌ [updateAddress] Error: $e');
      throw Exception('Failed to update address: ${e.toString()}');
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      final response = await _apiClient.delete('/customer/addresses/$addressId');

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to delete address');
      }

      log('✅ [deleteAddress] Address deleted: $addressId');
    } catch (e) {
      log('❌ [deleteAddress] Error: $e');
      throw Exception('Failed to delete address: ${e.toString()}');
    }
  }

  /// Set address as default
  Future<Address> setDefaultAddress(String addressId) async {
    try {
      final response = await _apiClient.put(
        '/customer/addresses/$addressId/default',
        body: {},
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to set default address');
      }

      final addressData = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressData);
      
      log('✅ [setDefaultAddress] Default address set: ${address.id}');
      return address;
    } catch (e) {
      log('❌ [setDefaultAddress] Error: $e');
      throw Exception('Failed to set default address: ${e.toString()}');
    }
  }
}

