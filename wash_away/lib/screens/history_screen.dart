// File: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// Assuming your controller file path is correct
import '../controllers/history_controller.dart';
import '../models/booking_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../widgets/custom_text_field.dart';
import 'track_order_screen.dart';
import 'completed_booking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Initialize and inject the controller instance
  final HistoryController controller = Get.put(HistoryController());
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Listen to search controller changes and update search query immediately
    // This ensures search starts on the first keystroke
    _searchController.addListener(() {
      // Update immediately on every character change
      controller.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Light background color matching the image
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:  Text(
          'My Bookings',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 20,fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // No back button shown in the image
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar ---
            _buildSearchBar(),

            const SizedBox(height: 16),

            // --- Tabs (Uses Obx for reactive state update) ---
            Obx(() => _buildTabBar(controller)),

            const SizedBox(height: 16),

            // --- Booking List (Uses Obx for reactive list update) ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.value != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.error.value ?? 'Error loading bookings',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => controller.fetchBookings(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Use the reactive filteredBookings list
                final bookings = controller.filteredBookings;

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      controller.searchQuery.value.isNotEmpty
                          ? "No bookings found matching your search."
                          : "No bookings for this tab.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.fetchBookings(),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildBookingCard(booking, context);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSearchBar() {
    return Obx(() => CustomTextField(
      controller: _searchController,
      hintText: 'Search by service, location, vehicle...',
      prefixIcon: Icons.search,
      suffixIcon: controller.searchQuery.value.trim().isNotEmpty
          ? Icons.clear
          : null,
      onSuffixIconTap: controller.searchQuery.value.trim().isNotEmpty
          ? () {
              _searchController.clear();
              controller.clearSearch();
            }
          : null,
      borderRadius: 12,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    ));
  }

  Widget _buildTabBar(HistoryController controller) {
    return Container(
      // Light grey/white background for the entire tab bar area
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.1): LightTheme.textPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(controller.tabs.length, (index) {
          final isSelected = controller.selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setTabIndex(index),
              child: Container(
                // The selected tab has a white background
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Text(
                  controller.tabs[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // The Booking model and _buildDetailRow are assumed to be present and correct.

  Widget _buildBookingCard(Booking booking, BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;
    String displayStatus;

    // Map backend status to display status
    if (booking.status == 'completed') {
      statusBgColor = const Color(0xFFE6FFFB);
      statusTextColor = const Color(0xFF00866E);
      displayStatus = 'Completed';
    } else if (booking.status == 'cancelled') {
      statusBgColor = const Color(0xFFFFE6E6);
      statusTextColor = Colors.red;
      displayStatus = 'Cancelled';
    } else if (booking.status == 'pending' || booking.status == 'accepted' || 
               booking.status == 'on_the_way' || booking.status == 'arrived' || 
               booking.status == 'in_progress') {
      statusBgColor = const Color(0xFFFFEFBD);
      statusTextColor = const Color(0xFFFFB300);
      displayStatus = 'Active';
    } else {
      statusBgColor = Colors.grey.shade200;
      statusTextColor = Colors.grey.shade700;
      displayStatus = booking.status;
    }

    const Color gradientLeft = Color(0xFF2E70F0);
    const Color gradientCenter = Color(0xFF29ACCA);
    const Color gradientRight = Color(0xFF24E2A9);

    final List<Color> gradientColors = [
      gradientLeft,
      gradientCenter,
      gradientRight,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          // ================= MAIN CARD =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DarkTheme.surface
                  : LightTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 5),
                  blurRadius: 10,
                ),
              ],
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.date,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? DarkTheme.textTertiary
                                : LightTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),

                    // STATUS BADGE
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusTextColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayStatus,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  value: booking.location,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.directions_car_outlined,
                  value: booking.vehicle,
                ),
                  Divider(color: Theme.of(context).brightness==Brightness.dark?Color(0xffffffff).withValues(alpha: 0.1):Color(0xff000000).withValues(alpha: 0.1),indent: 10,endIndent: 10,),
                // const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.price,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                        Theme.of(context).brightness == Brightness.dark
                            ? DarkTheme.textPrimary
                            : LightTheme.textPrimary,
                      ),
                    ),
                    // Show different actions based on booking status
                    if (booking.isCompleted)
                      GestureDetector(
                        onTap: () {
                          // Navigate to completed booking screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompletedBookingScreen(booking: booking),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                          ],
                        ),
                      )
                    else if (booking.isPending)
                      GestureDetector(
                        onTap: () {
                          // Navigate to tracking screen for active bookings
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              TrackerOrderScreen(bookingId: booking.id),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Track Order',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ================= GRADIENT LINE WITH ROUNDED CORNERS =================
         Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: SizedBox(
    height: 6, // slightly more height for curve
    child: CustomPaint(
      painter: _TopGradientPainter(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    ),
  ),
),

        ],
      ),
    );
  }


  // Helper widget for location and car details
  Widget _buildDetailRow({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18,),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.48):LightTheme.textPrimary.withValues(alpha: 0.48),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }


  
}

class _TopGradientPainter extends CustomPainter {
  final Gradient gradient;

  _TopGradientPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final path = Path()
      ..moveTo(16, 0) // left radius start
      ..lineTo(size.width - 16, 0)
      ..quadraticBezierTo(
        size.width,
        0,
        size.width,
        3, // slight downward curve on right
      )
      ..lineTo(0, 3)
      ..quadraticBezierTo(
        0,
        0,
        16,
        0, // slight downward curve on left
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// NOTE: Remember to import the necessary packages and place the controller 
// and screen files in their respective folders in your project.