class AddVehicleModel {
  final String? id;
  final String make;
  final String model;
  final String plateNumber;
  final String color;
  final String type; // e.g., Sedan, SUV
  bool isDefault;

  AddVehicleModel({
    this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  // Helper method to display name and basic details
  String get nameAndDetails => '$make $model';
  String get detailsLine => '$plateNumber · $color · $type';

  factory AddVehicleModel.fromJson(Map<String, dynamic> json) {
    return AddVehicleModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      color: json['color'] ?? '',
      type: json['type'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'make': make,
      'model': model,
      'plate_number': plateNumber,
      'color': color,
      'type': type,
      'is_default': isDefault,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddVehicleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}