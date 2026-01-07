// --- GetX Controller ---
import 'dart:developer';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/booking_model.dart';
import '../features/bookings/services/booking_service.dart';

class HistoryController extends GetxController {
  final BookingService _bookingService = BookingService();

  // Use RxInt to make the selected tab index observable
  final RxInt _selectedTabIndex = 0.obs;

  int get selectedTabIndex => _selectedTabIndex.value;

  final RxList<Booking> allBookings = <Booking>[].obs;
  var isLoading = true.obs;
  var error = RxnString();

  final List<String> tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  void setTabIndex(int index) {
    _selectedTabIndex.value = index;
    fetchBookings(); // Fetch data based on the new tab
  }

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;
      error.value = null;

      String? statusFilter;
      switch (tabs[selectedTabIndex]) {
        case 'All':
          statusFilter = null; // Fetch all statuses
          break;
        case 'Active':
          // Fetch active bookings (pending, accepted, on_the_way, arrived, in_progress)
          statusFilter = 'pending,accepted,on_the_way,arrived,in_progress';
          break;
        case 'Completed':
          statusFilter = 'completed';
          break;
        case 'Cancelled':
          statusFilter = 'cancelled';
          break;
      }

      final responseData = await _bookingService.getCustomerBookings(status: statusFilter);

      if (responseData is List) {
        allBookings.value = responseData.map((json) => Booking.fromJson(json)).toList();
      } else {
        allBookings.clear();
      }
    } catch (e) {
      log('Error fetching bookings: $e');
      error.value = 'Failed to load bookings: $e';
      allBookings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Filtered bookings based on tab (now handled by API, but keeping for compatibility)
  List<Booking> get filteredBookings => allBookings;
}