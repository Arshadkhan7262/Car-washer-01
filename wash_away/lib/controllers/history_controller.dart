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
    // If we don't have bookings yet, fetch them
    // Otherwise, filtering is done on frontend via filteredBookings getter
    if (allBookings.isEmpty && !isLoading.value) {
      fetchBookings();
    }
  }

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;
      error.value = null;

      // Always fetch all bookings and filter on frontend
      // This ensures Active tab works correctly (backend doesn't support multiple statuses)
      log('📋 [HistoryController] Fetching all bookings (status: null)');
      final responseData = await _bookingService.getCustomerBookings(status: null);
      log('✅ [HistoryController] Fetched ${responseData.length} bookings');

      allBookings.value = responseData.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching bookings: $e');
      error.value = 'Failed to load bookings: $e';
      allBookings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Filtered bookings based on tab
  List<Booking> get filteredBookings {
    final currentTab = tabs[selectedTabIndex];
    log('🔍 [HistoryController] Filtering bookings for tab: $currentTab (Total: ${allBookings.length})');
    
    switch (currentTab) {
      case 'All':
        return allBookings.toList();
      case 'Active':
        // Filter for active statuses: pending, accepted, on_the_way, arrived, in_progress
        final activeBookings = allBookings.where((booking) {
          return booking.status == 'pending' ||
                 booking.status == 'accepted' ||
                 booking.status == 'on_the_way' ||
                 booking.status == 'arrived' ||
                 booking.status == 'in_progress';
        }).toList();
        log('✅ [HistoryController] Found ${activeBookings.length} active bookings');
        return activeBookings;
      case 'Completed':
        return allBookings.where((booking) => booking.status == 'completed').toList();
      case 'Cancelled':
        return allBookings.where((booking) => booking.status == 'cancelled').toList();
      default:
        return allBookings.toList();
    }
  }
}