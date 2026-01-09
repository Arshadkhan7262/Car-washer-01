enum JobStep { assigned, onTheWay, arrived, washing, completed }

class JobDetailModel {
  final String bookingId;
  final String schedule;
  final String customerName;
  final String customerPhone;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleColor;
  final String packageName;
  final double totalPrice;
  final String paymentMethod;
  final String address;
  final JobStep currentStep;

  JobDetailModel({
    required this.bookingId,
    required this.schedule,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.packageName,
    required this.totalPrice,
    required this.paymentMethod,
    required this.address,
    required this.currentStep,
  });
}
