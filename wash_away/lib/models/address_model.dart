// --- Address Data Model ---
class Address {
  final String? id;
  final String label; // e.g., Home, Office
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  bool isDefault;

  Address({
    this.id,
    required this.label,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      label: json['label'] ?? '',
      fullAddress: json['full_address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'full_address': fullAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}