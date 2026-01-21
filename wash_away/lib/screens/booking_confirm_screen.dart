import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wash_away/screens/dashboard_screen.dart';
import 'package:wash_away/screens/track_order_screen.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../controllers/book_controller.dart';

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
    
    // Get BookController to access selected values (primary source)
    final BookController? bookController = Get.isRegistered<BookController>() 
        ? Get.find<BookController>() 
        : null;
    
    // Extract booking ID from API response
    final bookingId = bookingData?['booking_id']?.toString() ?? 
                     bookingData?['_id']?.toString() ?? 
                     bookingData?['id']?.toString() ?? 
                     '#N/A';
    
    // Format booking ID to show only last 8 characters if it's longer
    final String displayBookingId = bookingId.length > 8 
        ? '#${bookingId.substring(bookingId.length - 8).toUpperCase()}'
        : '#${bookingId.toUpperCase()}';
    
    // Extract total amount - PRIMARY: from controller (with coupon discount), FALLBACK: from API
    double totalAmount = 0.0;
    
    // PRIMARY: Get from controller's finalTotal (includes coupon discount)
    if (bookController != null) {
      totalAmount = bookController.finalTotal;
    }
    
    // FALLBACK: Get from API response if controller doesn't have it
    if (totalAmount == 0.0 && bookingData != null) {
      final apiTotal = bookingData?['total'] ?? 
                       bookingData?['total_amount'] ?? 
                       bookingData?['price'] ?? 
                       bookingData?['amount'];
      if (apiTotal != null) {
        totalAmount = apiTotal is num ? apiTotal.toDouble() : 0.0;
      }
    }
    
    final String formattedTotal = '\$${totalAmount.toStringAsFixed(2)}';
    
    // Extract and format date & time - PRIMARY: from controller, FALLBACK: from API
    String formattedDateTime = 'N/A';
    try {
      DateTime? bookingDate;
      String? timeSlot;
      
      // PRIMARY: Get from controller (user's device input)
      if (bookController?.selectedDate.value != null) {
        bookingDate = bookController!.selectedDate.value;
      }
      if (bookController?.selectedTime.value.isNotEmpty == true) {
        timeSlot = bookController!.selectedTime.value;
      }
      
      // FALLBACK: Get from API response if controller doesn't have it
      if (bookingDate == null) {
        final apiDate = bookingData?['booking_date'] ?? bookingData?['date'] ?? bookingData?['scheduled_date'];
        if (apiDate != null) {
          if (apiDate is String) {
            bookingDate = DateTime.tryParse(apiDate);
            if (bookingDate == null && apiDate.contains('-')) {
              final parts = apiDate.split('-');
              if (parts.length == 3) {
                bookingDate = DateTime.tryParse(apiDate);
              }
            }
          } else if (apiDate is DateTime) {
            bookingDate = apiDate;
          }
        }
      }
      
      if (timeSlot == null || timeSlot.isEmpty) {
        timeSlot = bookingData?['time_slot']?.toString() ?? 
                  bookingData?['time']?.toString() ??
                  bookingData?['scheduled_time']?.toString();
      }
      
      // Format the date and time
      if (bookingDate != null && timeSlot != null && timeSlot.isNotEmpty) {
        final dateFormat = DateFormat('EEEE, MMMM d');
        final formattedDate = dateFormat.format(bookingDate);
        formattedDateTime = '$formattedDate at $timeSlot';
      } else if (bookingDate != null) {
        final dateFormat = DateFormat('EEEE, MMMM d');
        formattedDateTime = dateFormat.format(bookingDate);
      }
    } catch (e) {
      formattedDateTime = 'Date not available';
    }
    
    // Extract location/address - PRIMARY: from controller, FALLBACK: from API
    String location = 'Address not available';
    
    // PRIMARY: Get from controller (user's device input)
    if (bookController != null) {
      // Check if saved address is selected
      if (bookController.selectedSavedAddress.value != null) {
        location = bookController.selectedSavedAddress.value!.fullAddress;
      } 
      // Fallback to manual address input
      else if (bookController.addressController.text.isNotEmpty) {
        location = bookController.addressController.text;
      }
    }
    
    // FALLBACK: Get from API response if controller doesn't have it
    if (location == 'Address not available' && bookingData != null) {
      location = bookingData?['address']?.toString() ?? 
                bookingData?['location']?.toString() ?? 
                bookingData?['full_address']?.toString() ??
                bookingData?['address_text']?.toString() ??
                'Address not available';
    }
    
    // Extract service name - PRIMARY: from controller, FALLBACK: from API
    String serviceName = 'Service not available';
    
    // PRIMARY: Get from controller (from API but selected by user)
    if (bookController?.selectedService.value != null) {
      serviceName = bookController!.selectedService.value!.name;
    }
    
    // FALLBACK: Get from API response if controller doesn't have it
    if (serviceName == 'Service not available' && bookingData != null) {
      // Try nested service object first
      if (bookingData?['service'] is Map) {
        serviceName = bookingData?['service']?['name']?.toString() ?? 
                     bookingData?['service']?['service_name']?.toString() ??
                     'Service not available';
      } else {
        // Try direct fields
        serviceName = bookingData?['service_name']?.toString() ?? 
                     bookingData?['service']?.toString() ??
                     'Service not available';
      }
    }
    
    // Extract vehicle type - PRIMARY: from controller, FALLBACK: from API
    String vehicleType = 'Vehicle type not available';
    
    // PRIMARY: Get from controller (from API but selected by user)
    if (bookController?.selectedVehicleType.value != null) {
      vehicleType = bookController!.selectedVehicleType.value!.displayName;
    }
    
    // FALLBACK: Get from API response if controller doesn't have it
    if (vehicleType == 'Vehicle type not available' && bookingData != null) {
      // Try nested vehicle_type object first
      if (bookingData?['vehicle_type'] is Map) {
        vehicleType = bookingData?['vehicle_type']?['name']?.toString() ?? 
                     bookingData?['vehicle_type']?['display_name']?.toString() ??
                     bookingData?['vehicle_type']?['type']?.toString() ??
                     'Vehicle type not available';
      } else if (bookingData?['vehicle'] is Map) {
        vehicleType = bookingData?['vehicle']?['type']?.toString() ?? 
                     bookingData?['vehicle']?['vehicle_type']?.toString() ??
                     'Vehicle type not available';
      } else {
        // Try direct fields
        vehicleType = bookingData?['vehicle_type_name']?.toString() ?? 
                     bookingData?['vehicle_type']?.toString() ??
                     'Vehicle type not available';
      }
    }
    
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
                      displayBookingId,
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
                      formattedTotal,
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
                  value: formattedDateTime,
                  backgroundColor: Color(0xff4E76E1).withValues(alpha: 0.1),
                  carColor: Colors.blue
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/locate.png',
                  label: 'Location',
                  value: location.toString(),
                  backgroundColor: Color(0xff24E2A9).withValues(alpha: 0.12),
                  carColor: Colors.green
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/car3.png',
                  label: 'Service',
                  value: serviceName.toString(),
                  backgroundColor: Color(0xffCA95FF).withValues(alpha: 0.13),
                  carColor: Color(0xff8844CD),
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/car3.png',
                  label: 'Vehicle Type',
                  value: vehicleType.toString(),
                  backgroundColor: Color(0xffFFB84D).withValues(alpha: 0.13),
                  carColor: Color(0xffFF8C00),
                ),

                const SizedBox(height: 16),

                // Receipt and Share Buttons
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _generateAndSaveReceipt(context),
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
                        onPressed: () => _generateAndShareReceipt(context),
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

  // Generate PDF receipt
  Future<pw.Document> _generateReceiptPDF() async {
    // Get BookController to access selected values
    final BookController? bookController = Get.isRegistered<BookController>() 
        ? Get.find<BookController>() 
        : null;
    
    // Extract booking ID
    final bookingId = bookingData?['booking_id']?.toString() ?? 
                     bookingData?['_id']?.toString() ?? 
                     bookingData?['id']?.toString() ?? 
                     'N/A';
    
    final String displayBookingId = bookingId.length > 8 
        ? '#${bookingId.substring(bookingId.length - 8).toUpperCase()}'
        : '#${bookingId.toUpperCase()}';
    
    // Extract total amount
    double totalAmount = 0.0;
    if (bookController != null) {
      totalAmount = bookController.finalTotal;
    }
    if (totalAmount == 0.0 && bookingData != null) {
      final apiTotal = bookingData?['total'] ?? 
                       bookingData?['total_amount'] ?? 
                       bookingData?['price'] ?? 
                       bookingData?['amount'];
      if (apiTotal != null) {
        totalAmount = apiTotal is num ? apiTotal.toDouble() : 0.0;
      }
    }
    
    // Extract date & time
    String formattedDateTime = 'N/A';
    try {
      DateTime? bookingDate;
      String? timeSlot;
      
      if (bookController?.selectedDate.value != null) {
        bookingDate = bookController!.selectedDate.value;
      }
      if (bookController?.selectedTime.value.isNotEmpty == true) {
        timeSlot = bookController!.selectedTime.value;
      }
      
      if (bookingDate == null) {
        final apiDate = bookingData?['booking_date'] ?? bookingData?['date'] ?? bookingData?['scheduled_date'];
        if (apiDate != null) {
          if (apiDate is String) {
            bookingDate = DateTime.tryParse(apiDate);
          } else if (apiDate is DateTime) {
            bookingDate = apiDate;
          }
        }
      }
      
      if (timeSlot == null || timeSlot.isEmpty) {
        timeSlot = bookingData?['time_slot']?.toString() ?? 
                  bookingData?['time']?.toString() ??
                  bookingData?['scheduled_time']?.toString();
      }
      
      if (bookingDate != null && timeSlot != null && timeSlot.isNotEmpty) {
        final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
        final formattedDate = dateFormat.format(bookingDate);
        formattedDateTime = '$formattedDate at $timeSlot';
      } else if (bookingDate != null) {
        final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
        formattedDateTime = dateFormat.format(bookingDate);
      }
    } catch (e) {
      formattedDateTime = 'Date not available';
    }
    
    // Extract location
    String location = 'Address not available';
    if (bookController != null) {
      if (bookController.selectedSavedAddress.value != null) {
        location = bookController.selectedSavedAddress.value!.fullAddress;
      } else if (bookController.addressController.text.isNotEmpty) {
        location = bookController.addressController.text;
      }
    }
    if (location == 'Address not available' && bookingData != null) {
      location = bookingData?['address']?.toString() ?? 
                bookingData?['location']?.toString() ?? 
                bookingData?['full_address']?.toString() ??
                bookingData?['address_text']?.toString() ??
                'Address not available';
    }
    
    // Extract service name
    String serviceName = 'Service not available';
    if (bookController?.selectedService.value != null) {
      serviceName = bookController!.selectedService.value!.name;
    }
    if (serviceName == 'Service not available' && bookingData != null) {
      if (bookingData?['service'] is Map) {
        serviceName = bookingData?['service']?['name']?.toString() ?? 
                     bookingData?['service']?['service_name']?.toString() ??
                     'Service not available';
      } else {
        serviceName = bookingData?['service_name']?.toString() ?? 
                     bookingData?['service']?.toString() ??
                     'Service not available';
      }
    }
    
    // Extract vehicle type
    String vehicleType = 'Vehicle type not available';
    if (bookController?.selectedVehicleType.value != null) {
      vehicleType = bookController!.selectedVehicleType.value!.displayName;
    }
    if (vehicleType == 'Vehicle type not available' && bookingData != null) {
      if (bookingData?['vehicle_type'] is Map) {
        vehicleType = bookingData?['vehicle_type']?['name']?.toString() ?? 
                     bookingData?['vehicle_type']?['display_name']?.toString() ??
                     bookingData?['vehicle_type']?['type']?.toString() ??
                     'Vehicle type not available';
      } else if (bookingData?['vehicle'] is Map) {
        vehicleType = bookingData?['vehicle']?['type']?.toString() ?? 
                     bookingData?['vehicle']?['vehicle_type']?.toString() ??
                     'Vehicle type not available';
      } else {
        vehicleType = bookingData?['vehicle_type_name']?.toString() ?? 
                     bookingData?['vehicle_type']?.toString() ??
                     'Vehicle type not available';
      }
    }
    
    // Create PDF document
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Wash Away',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Booking Receipt',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Booking ID and Total Amount
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Booking ID',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        displayBookingId,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Amount',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Booking Details
              pw.Text(
                'Booking Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              
              // Date & Time
              _buildReceiptRow('Date & Time', formattedDateTime),
              pw.SizedBox(height: 12),
              
              // Location
              _buildReceiptRow('Location', location),
              pw.SizedBox(height: 12),
              
              // Service
              _buildReceiptRow('Service', serviceName),
              pw.SizedBox(height: 12),
              
              // Vehicle Type
              _buildReceiptRow('Vehicle Type', vehicleType),
              pw.SizedBox(height: 30),
              
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for choosing Wash Away!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${DateFormat('MMMM d, yyyy at hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }
  
  // Helper method to build receipt rows
  pw.Widget _buildReceiptRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  // Generate and save receipt to device
  Future<void> _generateAndSaveReceipt(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate PDF
      final pdf = await _generateReceiptPDF();
      
      // Get directory for saving - use app's documents directory (no permissions needed)
      Directory directory;
      if (Platform.isAndroid) {
        // For Android, use external storage directory (app-specific, no permissions needed on Android 10+)
        // This saves to: /storage/emulated/0/Android/data/com.example.wash_away/files/
        // Android 10+ (API 29+) uses scoped storage - app's own directory doesn't need permissions
        final externalDir = await getExternalStorageDirectory();
        directory = externalDir ?? await getApplicationDocumentsDirectory();
      } else {
        // iOS - use application documents directory (no permissions needed)
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Create a "Receipts" subdirectory for better organization
      final receiptsDir = Directory('${directory.path}/Receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      
      // Generate filename
      final bookingId = bookingData?['booking_id']?.toString() ?? 
                       bookingData?['_id']?.toString() ?? 
                       bookingData?['id']?.toString() ?? 
                       'booking';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'WashAway_Receipt_${bookingId}_$timestamp.pdf';
      final filePath = '${receiptsDir.path}/$fileName';
      
      // Save PDF file
      final file = File(filePath);
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      Get.back(); // Close loading
      
      // Show success message with user-friendly path
      final userFriendlyPath = Platform.isAndroid 
          ? 'Receipts folder in app storage'
          : 'Receipts folder in app documents';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Receipt saved successfully!'),
              const SizedBox(height: 4),
              Text(
                'Location: $userFriendlyPath',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Get.back(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving receipt: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  // Generate and share receipt
  Future<void> _generateAndShareReceipt(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate PDF
      final pdf = await _generateReceiptPDF();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final bookingId = bookingData?['booking_id']?.toString() ?? 
                       bookingData?['_id']?.toString() ?? 
                       bookingData?['id']?.toString() ?? 
                       'booking';
      final fileName = 'WashAway_Receipt_$bookingId.pdf';
      final filePath = '${directory.path}/$fileName';
      
      // Save PDF to temporary file
      final file = File(filePath);
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      Get.back(); // Close loading
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Wash Away Booking Receipt',
        subject: 'Booking Receipt - $bookingId',
      );
    } catch (e) {
      Get.back(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}