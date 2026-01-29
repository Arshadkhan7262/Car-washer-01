// --- GetX Controller ---
import 'dart:developer';
import 'package:get/get.dart';
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

  // Search query for filtering bookings
  final RxString searchQuery = ''.obs;

  // Reactive filtered bookings list
  final RxList<Booking> filteredBookings = <Booking>[].obs;

  final List<String> tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
    
    // Watch for changes in dependencies and update filtered bookings
    ever(_selectedTabIndex, (_) => _updateFilteredBookings());
    ever(searchQuery, (_) => _updateFilteredBookings());
    ever(allBookings, (_) => _updateFilteredBookings());
  }

  void setTabIndex(int index) {
    _selectedTabIndex.value = index;
    // If we don't have bookings yet, fetch them
    // Otherwise, filtering is done on frontend via filteredBookings getter
    if (allBookings.isEmpty && !isLoading.value) {
      fetchBookings();
    }
  }

  /// Update search query (triggers immediately on each keystroke)
  void updateSearchQuery(String query) {
    // Update immediately without trimming to allow single character search
    searchQuery.value = query;
    log('🔍 [HistoryController] Search query updated: "${searchQuery.value}"');
  }

  /// Clear search query
  void clearSearch() {
    searchQuery.value = '';
    log('🔍 [HistoryController] Search cleared');
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
      // Update filtered bookings after fetching
      _updateFilteredBookings();
    } catch (e) {
      log('Error fetching bookings: $e');
      error.value = 'Failed to load bookings: $e';
      allBookings.clear();
      filteredBookings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update filtered bookings based on tab and search query
  void _updateFilteredBookings() {
    final currentTab = tabs[selectedTabIndex];
    // Trim only for comparison, but allow single character searches
    final query = searchQuery.value.trim().toLowerCase();
    log('🔍 [HistoryController] Filtering bookings for tab: $currentTab, search: "$query" (Total: ${allBookings.length})');
    
    // First filter by tab
    List<Booking> tabFilteredBookings;
    switch (currentTab) {
      case 'All':
        tabFilteredBookings = allBookings.toList();
        break;
      case 'Active':
        // Filter for active statuses: pending, accepted, on_the_way, arrived, in_progress
        tabFilteredBookings = allBookings.where((booking) {
          return booking.status == 'pending' ||
                 booking.status == 'accepted' ||
                 booking.status == 'on_the_way' ||
                 booking.status == 'arrived' ||
                 booking.status == 'in_progress';
        }).toList();
        log('✅ [HistoryController] Found ${tabFilteredBookings.length} active bookings');
        break;
      case 'Completed':
        tabFilteredBookings = allBookings.where((booking) => booking.status == 'completed').toList();
        break;
      case 'Cancelled':
        tabFilteredBookings = allBookings.where((booking) => booking.status == 'cancelled').toList();
        break;
      default:
        tabFilteredBookings = allBookings.toList();
    }
    
    // Then filter by search query if provided
    if (query.isEmpty) {
      filteredBookings.value = tabFilteredBookings;
      log('✅ [HistoryController] Filtered bookings (no search): ${filteredBookings.length}');
      return;
    }
    
    final searchFiltered = tabFilteredBookings.where((booking) {
      // Search in service name (primary search field)
      final serviceMatch = booking.service.toLowerCase().contains(query);
      
      // Search in location/address
      final locationMatch = booking.location.toLowerCase().contains(query);
      
      // Search in vehicle type
      final vehicleMatch = booking.vehicle.toLowerCase().contains(query);
      
      // Search in booking ID
      final bookingIdMatch = booking.bookingId.toLowerCase().contains(query);
      
      // Search in date
      final dateMatch = booking.date.toLowerCase().contains(query);
      
      return serviceMatch || locationMatch || vehicleMatch || bookingIdMatch || dateMatch;
    }).toList();
    
    filteredBookings.value = searchFiltered;
    log('✅ [HistoryController] Found ${filteredBookings.length} bookings matching search query');
  }
}