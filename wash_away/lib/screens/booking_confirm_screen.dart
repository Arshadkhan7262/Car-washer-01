import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wash_away/screens/dashboard_screen.dart';
import 'package:wash_away/screens/home_screen.dart';
import 'package:wash_away/screens/track_order_screen.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

// Assuming you have defined your themes and colors elsewhere.
// For this example, I'll use simple definitions for demonstration.
// You should replace these with your actual theme definitions.
class AppColors {
  static const Color primaryBlue = Color(0xFF4E76E1);
  static const Color secondaryBlue = Color(0xFF2A7EAC);
  static const Color tertiaryGreen = Color(0xFF00866E);
  static const Color successGreen = Color(0xFF24E2A9); // Color for the large checkmark
  static const Color iconColor = Colors.grey; // Color for the small detail icons

  // NEW: Colors for the icon background containers
  static const Color iconBgDate = Color(0xFFE8F0FF); // Light Blue/Purple
  static const Color iconBgLocation = Color(0xFFFFF2E6); // Light Orange/Yellow
  static const Color iconBgService = Color(0xFFE6FFFB); // Light Teal/Cyan
}

class AppStyles {
  static TextStyle headlineBold = GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle bodyText = GoogleFonts.inter(fontSize: 20,fontWeight: FontWeight.w600);
  static TextStyle detailLabel = GoogleFonts.inter(fontSize: 14, color: Colors.grey,fontWeight: FontWeight.w400);
  static TextStyle detailValue = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);
}

// --- Booking Confirmation Screen Code ---

class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic>? bookingData;
  
  const BookingConfirmationScreen({super.key, this.bookingData});

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary;
    final Color cardBackgroundColor = isDarkTheme ? DarkTheme.card : LightTheme.card;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? DarkTheme.background 
          : LightTheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 40), // Space from top

              // 1. Large Checkmark Icon
              _buildSuccessIndicator(),

              const SizedBox(height: 15),

              // 2. Booking Confirmed Text
              Text(
                'Booking Confirmed!',
                textAlign: TextAlign.center,

                style: AppStyles.headlineBold.copyWith(color: textColor),
              ),

              const SizedBox(height: 4),

              // 3. Subtext
              Text(
                'Your car wash has been scheduled successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
              ),

              const SizedBox(height: 10),

              // 4. Booking Details Card
              _buildBookingDetailsCard(context, cardBackgroundColor, textColor),

              const SizedBox(height: 20),

              // 5. Track Your Order Button
              ElevatedButton(
                onPressed: () {
                  final bookingId = bookingData?['booking_id']?.toString() ?? 
                                   bookingData?['booking']?['booking_id']?.toString() ?? 
                                   bookingData?['_id']?.toString() ?? '';
                  if (bookingId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackerOrderScreen(bookingId: bookingId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Booking ID not available')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue, // Use one of the gradient colors
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Track Your Order',
                      style: AppStyles.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Back to Home Text Button
              TextButton(
                onPressed: () {
                  // Handle navigation back to home
Get.offAll(DashboardScreen());                },
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.inter(
                    color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.successGreen,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard(BuildContext context, Color cardBackgroundColor, Color textColor) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness== Brightness.dark? DarkTheme.card: LightTheme.card, // Use card background for the main card body
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme 
              ? Colors.white.withValues(alpha: 0.25) 
              : Colors.black.withValues(alpha: 0.25),
          width: 1,
        ),
        // The image shows a very subtle shadow.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkTheme ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Top section with Booking ID and Total Amount (Gradient) - KEEP SAME FOR BOTH THEMES
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4E76E1), // Left: 4E76E1
                  const Color(0xFF2A7EAC), // Center: 2A7EAC
                  const Color(0xFF00866E), // Right: 00866E
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                     Text(
                      'Booking ID',
                      style: GoogleFonts.inter(
                        color: Color(0xffffffff),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '#693C09AC',
                      style: AppStyles.headlineBold.copyWith(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                     Text(
                      'Total Amount',
                      style: GoogleFonts.inter(
                        color: Color(0xffffffff),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$29.00',
                      style: AppStyles.headlineBold.copyWith(color: Colors.white,),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom section with details (White/Themed background)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                // Updated calls with different background colors
                _buildDetailRow(
                  iconPath: 'assets/images/date.png',
                  label: 'Date & Time',
                  value: 'Friday, December 12 at 10:00 AM',
                  backgroundColor: Color(0xff4E76E1).withValues(alpha: 0.1),
                  carColor: Colors.blue
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/locate.png',
                  label: 'Location',
                  value: '1 hr',
                  backgroundColor: Color(0xff24E2A9).withValues(alpha: 0.12),
                  carColor: Colors.green
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/car3.png',
                  label: 'Service',
                  value: 'Express Wash',
                  backgroundColor: Color(0xffCA95FF).withValues(alpha: 0.13),
                  carColor: Color(0xff8844CD),
                ),

                const SizedBox(height: 16),

                // Receipt and Share Buttons
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset('assets/images/download.png',width: 24,height: 24,color: Theme.of(context).brightness==Brightness.dark? Colors.white:Colors.black ,),
                        label: Text(
                          'Receipt',
                          style: AppStyles.detailValue.copyWith(
                            color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDarkTheme 
                                ? Colors.white.withValues(alpha: 0.1) 
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon:Image.asset(
                          'assets/images/share.png',
                          width: 24,
                          height: 24,
                          color:Theme.of(context).brightness==Brightness.dark? Colors.white:Colors.black,
                        ),
                        label: Text(
                          'Share',
                          style: AppStyles.detailValue.copyWith(
                            color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDarkTheme 
                                ? Colors.white.withValues(alpha: 0.1) 
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED Widget: _buildDetailRow ---
  Widget _buildDetailRow({
    required String iconPath,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color carColor// New parameter for background color
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // NEW Container for the Square Colored Background
          Container(
            width: 48, // Size of the square container
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10), // Slightly rounded corners for the square
            ),
            child: Center(
              child: SizedBox(
                width: 24, // Size of the icon inside the container
                height: 24,
                child: Opacity(
                  opacity: 0.8, // Slightly more prominent icon
                  child: Image.asset(
                    iconPath,
                    color: carColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppStyles.detailLabel.copyWith(
                    color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppStyles.detailValue.copyWith(
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}