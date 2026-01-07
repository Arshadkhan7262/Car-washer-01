// --- Data Model for Booking Card ---
class Booking {
  final String id; // MongoDB _id
  final String bookingId; // Booking ID like CW-2024-1234
  final String service;
  final String date;
  final String location;
  final String vehicle;
  final String price;
  final String status; // pending, accepted, on_the_way, arrived, in_progress, completed, cancelled

  Booking({
    required this.id,
    required this.bookingId,
    required this.service,
    required this.date,
    required this.location,
    required this.vehicle,
    required this.price,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Format date and time
    String formattedDate = 'N/A';
    if (json['booking_date'] != null && json['time_slot'] != null) {
      try {
        final date = DateTime.parse(json['booking_date'].toString());
        // Use simple date formatting if intl is not available
        final year = date.year;
        final month = _getMonthName(date.month);
        final day = date.day;
        formattedDate = '$month $day, $year at ${json['time_slot']}';
      } catch (e) {
        formattedDate = '${json['booking_date']} at ${json['time_slot']}';
      }
    }

    // Get service name
    String serviceName = 'Service';
    if (json['service_id'] != null) {
      if (json['service_id'] is Map) {
        serviceName = json['service_id']['name'] ?? 'Service';
      } else {
        serviceName = json['service_name'] ?? 'Service';
      }
    }

    // Get vehicle type
    String vehicleType = json['vehicle_type']?.toString().toUpperCase() ?? 'N/A';

    // Get address
    String address = json['address']?.toString() ?? 'N/A';

    // Get price
    double totalPrice = (json['total'] ?? 0.0).toDouble();
    String priceStr = '\$${totalPrice.toStringAsFixed(2)}';

    // Get status
    String statusStr = json['status']?.toString() ?? 'pending';

    return Booking(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? json['_id']?.toString().substring(18) ?? '',
      service: serviceName,
      date: formattedDate,
      location: address,
      vehicle: vehicleType,
      price: priceStr,
      status: statusStr,
    );
  }

  // Helper to check if booking is active (not completed or cancelled)
  bool get isActive {
    return status != 'completed' && status != 'cancelled';
  }

  // Helper to check if booking is completed
  bool get isCompleted {
    return status == 'completed';
  }

  // Helper to check if booking is pending
  bool get isPending {
    return status == 'pending' || status == 'accepted' || 
           status == 'on_the_way' || status == 'arrived' || status == 'in_progress';
  }

  // Helper to get month name
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}