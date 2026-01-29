import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class CompletedBookingScreen extends StatefulWidget {
  final Booking booking;

  const CompletedBookingScreen({super.key, required this.booking});

  @override
  State<CompletedBookingScreen> createState() => _CompletedBookingScreenState();
}

class _CompletedBookingScreenState extends State<CompletedBookingScreen> {
  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary;
    final Color cardBackgroundColor = isDarkTheme ? DarkTheme.card : LightTheme.card;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? DarkTheme.background
          : LightTheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? DarkTheme.background
            : LightTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).iconTheme.color,
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Order Completed',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF24E2A9).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Color(0xFF24E2A9),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Your Order Has Been Completed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Thank you for using our service',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Booking Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkTheme
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.receipt_long,
                      label: 'Booking ID',
                      value: '#${booking.bookingId}',
                      isDarkTheme: isDarkTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.local_car_wash,
                      label: 'Service',
                      value: booking.service,
                      isDarkTheme: isDarkTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date & Time',
                      value: booking.date,
                      isDarkTheme: isDarkTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: booking.location,
                      isDarkTheme: isDarkTheme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.directions_car,
                      label: 'Vehicle',
                      value: booking.vehicle,
                      isDarkTheme: isDarkTheme,
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          booking.price,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF24E2A9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate back to home or history
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E76E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Bookings',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => _generateAndShareReceipt(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDarkTheme
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt,
                      color: textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Download Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Generate PDF receipt
  Future<pw.Document> _generateReceiptPDF() async {
    final booking = widget.booking;
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
              pw.Text(
                'Receipt',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Wash Away - Car Wash Service',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
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
              pw.SizedBox(height: 16),
              
              _buildPDFRow('Booking ID', '#${booking.bookingId}'),
              pw.SizedBox(height: 8),
              _buildPDFRow('Service', booking.service),
              pw.SizedBox(height: 8),
              _buildPDFRow('Date & Time', booking.date),
              pw.SizedBox(height: 8),
              _buildPDFRow('Location', booking.location),
              pw.SizedBox(height: 8),
              _buildPDFRow('Vehicle', booking.vehicle),
              
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    booking.price,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Thank you for using Wash Away!',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on ${DateFormat('MMMM d, yyyy at h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Generate and share receipt
  Future<void> _generateAndShareReceipt(BuildContext context) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      
      // Generate PDF
      final pdf = await _generateReceiptPDF();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final bookingId = widget.booking.bookingId;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'WashAway_Receipt_${bookingId}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      // Save PDF file
      final file = File(filePath);
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      Get.back(); // Close loading
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Receipt for booking #${widget.booking.bookingId}',
        subject: 'Booking Receipt',
      );
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'Error',
        'Failed to generate receipt: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}


