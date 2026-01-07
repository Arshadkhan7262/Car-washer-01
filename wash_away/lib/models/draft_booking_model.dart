class DraftBooking {
  final String? id;
  final int step;
  final String? serviceId;
  final String? vehicleTypeId;
  final String? vehicleTypeName;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? address;
  final String? additionalLocation;
  final String? paymentMethod;
  final String? couponCode;
  final DateTime? lastUpdated;

  DraftBooking({
    this.id,
    required this.step,
    this.serviceId,
    this.vehicleTypeId,
    this.vehicleTypeName,
    this.selectedDate,
    this.selectedTime,
    this.address,
    this.additionalLocation,
    this.paymentMethod,
    this.couponCode,
    this.lastUpdated,
  });

  factory DraftBooking.fromJson(Map<String, dynamic> json) {
    return DraftBooking(
      id: json['_id'] ?? json['id'],
      step: json['step'] ?? 0,
      serviceId: json['service_id']?['_id'] ?? json['service_id'],
      vehicleTypeId: json['vehicle_type_id']?['_id'] ?? json['vehicle_type_id'],
      vehicleTypeName: json['vehicle_type_name'] ?? json['vehicle_type_id']?['display_name'],
      selectedDate: json['selected_date'] != null 
          ? DateTime.parse(json['selected_date'])
          : null,
      selectedTime: json['selected_time'],
      address: json['address'],
      additionalLocation: json['additional_location'],
      paymentMethod: json['payment_method'],
      couponCode: json['coupon_code'],
      lastUpdated: json['updated_date'] != null
          ? DateTime.parse(json['updated_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      if (serviceId != null) 'service_id': serviceId,
      if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
      if (vehicleTypeName != null) 'vehicle_type_name': vehicleTypeName,
      if (selectedDate != null) 'selected_date': selectedDate!.toIso8601String().split('T')[0],
      if (selectedTime != null) 'selected_time': selectedTime,
      if (address != null) 'address': address,
      if (additionalLocation != null) 'additional_location': additionalLocation,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (couponCode != null) 'coupon_code': couponCode,
    };
  }
}


