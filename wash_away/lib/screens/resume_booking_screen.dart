// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/book_controller.dart';
import '../screens/book_screen.dart';
import '../features/bookings/services/draft_booking_service.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class ResumeBookingScreen extends StatelessWidget {
  const ResumeBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final draftBookingService = DraftBookingService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Continue Your Booking?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'You have an incomplete booking. Would you like to resume or start a new one?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Resume Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🔄 [ResumeBooking] Starting resume flow...');
                    
                    // Set static flag BEFORE creating controller to prevent onInit interference
                    BookController.setWillResume(true);
                    
                    // Load draft and navigate to booking screen
                    // Use Get.find if controller exists, otherwise create
                    BookController bookController;
                    if (Get.isRegistered<BookController>()) {
                      bookController = Get.find<BookController>();
                      print('🔄 [ResumeBooking] Using existing controller');
                    } else {
                      bookController = Get.put(BookController(), permanent: false);
                      print('🔄 [ResumeBooking] Created new controller');
                    }
                    
                    // Set instance resuming flag
                    bookController.isResuming = true;
                    
                    // IMPORTANT: Ensure services and vehicle types are loaded before loading draft
                    print('🔄 [ResumeBooking] Fetching services and vehicle types...');
                    await bookController.fetchServices();
                    await bookController.fetchVehicleTypes();
                    
                    // Load saved addresses and vehicles (needed for stage 3)
                    print('🔄 [ResumeBooking] Fetching addresses and vehicles...');
                    await bookController.fetchSavedAddresses();
                    await bookController.fetchSavedVehicles();
                    
                    // Now load the draft (which will restore selections and set currentPage)
                    // Skip PageController reset here - it will be handled when BookScreen builds
                    print('🔄 [ResumeBooking] Loading draft...');
                    await bookController.loadDraftBooking(skipPageControllerReset: true);
                    
                    // Reset PageController AFTER draft is loaded so it uses the correct initialPage
                    // This ensures the new PageController will be created with the correct initialPage
                    print('🔄 [ResumeBooking] Resetting PageController. Current page: ${bookController.currentPage.value}');
                    bookController.resetPageController();
                    
                    print('🔄 [ResumeBooking] Navigating to BookScreen...');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Resume Booking',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Start New Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // Clear draft and navigate to booking screen
                    await draftBookingService.deleteDraft();
                    // Use Get.find if controller exists, otherwise create
                    BookController bookController;
                    if (Get.isRegistered<BookController>()) {
                      bookController = Get.find<BookController>();
                      // Reset controller state for fresh start
                      bookController.resetPageController();
                      // Clear all booking data
                      bookController.selectedService.value = null;
                      bookController.selectedVehicleType.value = null;
                      bookController.selectedVehicle.value = null;
                      bookController.selectedDate.value = null;
                      bookController.selectedTime.value = '';
                      bookController.addressController.clear();
                      bookController.additionalLocationController.clear();
                      bookController.selectedPaymentMethod.value = 'Credit Card';
                      bookController.currentPage.value = 0;
                    } else {
                      bookController = Get.put(BookController(), permanent: false);
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isDarkTheme 
                          ? Colors.white.withOpacity(0.25) 
                          : Colors.black.withOpacity(0.25),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start New Booking',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
