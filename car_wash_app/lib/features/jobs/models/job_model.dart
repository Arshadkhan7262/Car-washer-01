enum JobStatus { newJob, active, done }

class JobModel {
  final String id;
  final String customerName;
  final String vehicleType;
  final String vehicleModel;
  final String serviceName;
  final String dateTime;
  final String address;
  final double price;
  final JobStatus status;

  JobModel({
    required this.id,
    required this.customerName,
    required this.vehicleType,
    required this.vehicleModel,
    required this.serviceName,
    required this.dateTime,
    required this.address,
    required this.price,
    required this.status,
  });
}
