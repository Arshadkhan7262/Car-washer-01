import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../features/bookings/services/booking_service.dart';
import '../controllers/book_controller.dart';
import '../features/notifications/services/notification_handler_service.dart';
import '../features/notifications/controllers/notification_controller.dart';
import 'washer_tracking_map_screen.dart';

class AppColors {
  // Primary color used for the header background and active status.
  static const Color primaryBlueLight = Color(0xFFC0D6F9); // Light blue background
  static const Color primaryBlueDark = Color(0xFF4285F4); // Primary blue for icons/text
  static const Color primaryBlueIcon = Color(0xFF4285F4); // Darker primary for the icon
  static const Color lightGreyBg = Color(0xFFF5F5F5); // Light grey for inactive circles
  static const Color iconColor = Colors.grey; // Color for the small detail icons
}

class AppStyles {
  static TextStyle headlineBold = GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold);
  static TextStyle subHeader = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle bodyText = GoogleFonts.inter(fontSize: 16,fontWeight: FontWeight.w400);
  static TextStyle detailLabel = GoogleFonts.inter(fontSize: 14, color: Colors.grey);
  static TextStyle detailValue = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500);
  static TextStyle totalValue = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold);
}

// --- Tracking Status Enum ---
// Used to define and manage the active step in the timeline.
enum OrderStatus {
  confirmed,
  washerAssigned,
  onTheWay,
  arrived,
  washing,
  completed,
}


// --- Main Screen Widget ---

class TrackerOrderScreen extends StatefulWidget {
  final String bookingId;
  
  const TrackerOrderScreen({super.key, required this.bookingId});

  @override
  State<TrackerOrderScreen> createState() => _TrackerOrderScreenState();
}

class _TrackerOrderScreenState extends State<TrackerOrderScreen> {
  final BookingService _bookingService = BookingService();
  
  OrderStatus currentStatus = OrderStatus.confirmed;
  String bookingIdDisplay = '';
  Map<String, dynamic>? trackingData;
  bool isLoading = true;
  String? error;
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;
  bool _isRefreshing = false;
  DateTime? _lastUpdateTime;
  BookingStatusCallback? _bookingStatusCallback;
  
  List<String> imagePath = [
    'assets/images/car5.png',
    'assets/images/car5.png',
    'assets/images/locationn.png',
    'assets/images/wash.png',
    'assets/images/complete.png'
  ];

  @override
  void initState() {
    super.initState();
    bookingIdDisplay = widget.bookingId;
    _fetchTrackingData();
    
    // Ensure notification handler is initialized before registering callback
    _ensureNotificationHandlerInitialized();
    
    // Register callback for booking status notifications
    _bookingStatusCallback = (String bookingId, Map<String, dynamic> data) {
      if (bookingId == widget.bookingId && mounted) {
        developer.log('📱 [TrackOrderScreen] Booking status update received via notification');
        developer.log('📱 Status: ${data['status']}');
        // Refresh tracking data - fromPushNotification: true to skip snackbar (system notification already showed)
        _fetchTrackingData(silent: true, fromPushNotification: true);
      }
    };
    
    NotificationHandlerService().registerBookingCallback(
      widget.bookingId,
      _bookingStatusCallback!,
    );
    
    // Start periodic refresh every 5 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isRefreshing) {
        _fetchTrackingData(silent: true);
      }
    });
    
    // Also update the last update time display every second
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lastUpdateTime != null) {
        setState(() {
          // Trigger rebuild to update "X seconds ago" text
        });
      }
    });
  }

  /// Ensure notification handler is initialized
  Future<void> _ensureNotificationHandlerInitialized() async {
    try {
      developer.log('🔄 [TrackOrderScreen] Ensuring notification handler is initialized...');
      await NotificationHandlerService().initialize(forceReinitialize: false);
      developer.log('✅ [TrackOrderScreen] Notification handler initialized');
    } catch (e) {
      developer.log('⚠️ [TrackOrderScreen] Error initializing notification handler: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _uiUpdateTimer?.cancel();
    
    // Unregister callback
    if (_bookingStatusCallback != null) {
      NotificationHandlerService().unregisterBookingCallback(
        widget.bookingId,
        _bookingStatusCallback!,
      );
    }
    
    super.dispose();
  }

  Future<void> _fetchTrackingData({bool silent = false, bool fromPushNotification = false}) async {
    // Prevent multiple simultaneous requests
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      
      // Only show loading indicator on initial load, not on silent refreshes
      if (!silent && mounted) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      developer.log('📍 [TrackOrderScreen] Fetching tracking data for booking: ${widget.bookingId} (silent: $silent)');
      
      final data = await _bookingService.trackBooking(widget.bookingId);
      
      // Check if status has changed
      final newStatus = _mapStatusToOrderStatus(data['status']?.toString() ?? 'confirmed');
      final statusChanged = newStatus != currentStatus;
      final washerAssigned = data['washer_name'] != null && trackingData?['washer_name'] == null;
      
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          trackingData = data;
          bookingIdDisplay = data['booking_id']?.toString() ?? widget.bookingId;
          currentStatus = newStatus;
          isLoading = false;
          error = null;
          _lastUpdateTime = DateTime.now();
        });
      }
      
      // Show notification if status changed or washer was assigned
      if (mounted && (statusChanged || washerAssigned)) {
        String message = '';
        if (washerAssigned) {
          message = 'Washer ${data['washer_name']} has been assigned to your booking!';
        } else if (statusChanged) {
          switch (newStatus) {
            case OrderStatus.washerAssigned:
              message = 'Washer has been assigned!';
              break;
            case OrderStatus.onTheWay:
              message = 'Washer is on the way!';
              break;
            case OrderStatus.arrived:
              message = 'Washer has arrived!';
              break;
            case OrderStatus.washing:
              message = 'Washing in progress!';
              break;
            case OrderStatus.completed:
              message = 'Service completed!';
              // Stop polling when completed
              _refreshTimer?.cancel();
              break;
            default:
              break;
          }
        }
        
        // Don't show snackbar when update came from push - show push/banner instead (foreground)
        final skipSnackbar = fromPushNotification ||
            (Get.isRegistered<NotificationController>() &&
                Get.find<NotificationController>().wasRecentlyNotifiedByPush(widget.bookingId));
        if (message.isNotEmpty && !skipSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Stop polling if booking is completed or cancelled
      if (newStatus == OrderStatus.completed || 
          data['booking_status']?.toString() == 'cancelled') {
        _refreshTimer?.cancel();
      }
      
    } catch (e) {
      developer.log('❌ [TrackOrderScreen] Error fetching tracking data: $e');
      
      // Only show error on initial load, not on silent refreshes
      if (!silent && mounted) {
        setState(() {
          // Clean up error message for user display
          String errorMsg = e.toString();
          if (errorMsg.contains('Exception: ')) {
            errorMsg = errorMsg.replaceAll('Exception: ', '');
          }
          error = errorMsg;
          isLoading = false;
        });
        
        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to load tracking data'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  OrderStatus _mapStatusToOrderStatus(String status) {
    // Normalize status to lowercase for comparison
    final normalizedStatus = status.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    
    switch (normalizedStatus) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'washerassigned':
        return OrderStatus.washerAssigned;
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'arrived':
        return OrderStatus.arrived;
      case 'washing':
      case 'inprogress':
        return OrderStatus.washing;
      case 'completed':
        return OrderStatus.completed;
      default:
        developer.log('⚠️ [TrackOrderScreen] Unknown status: $status, defaulting to confirmed');
        return OrderStatus.confirmed;
    }
  }

  String _formatSchedule(dynamic date, dynamic timeSlot) {
    if (date == null || timeSlot == null) {
      return 'Not scheduled';
    }
    
    try {
      final dateTime = DateTime.parse(date.toString());
      final formattedDate = _formatDate(dateTime);
      return '$formattedDate at $timeSlot';
    } catch (e) {
      return '$date at $timeSlot';
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    
    return '$weekday, $month $day';
  }

  /// Get total price - matches booking confirmation screen logic (includes coupon discount)
  String _getTotalPrice(Map<String, dynamic> data) {
    // PRIMARY: Get from BookController's finalTotal (includes coupon discount)
    // This works because user navigates from booking confirmation, so controller still has the service and coupon
    final BookController? bookController = Get.isRegistered<BookController>() 
        ? Get.find<BookController>() 
        : null;
    
    if (bookController != null) {
      final finalTotal = bookController.finalTotal;
      if (finalTotal > 0.0) {
        return '\$${finalTotal.toStringAsFixed(2)}';
      }
    }
    
    // SECONDARY: Try to get price from service object in tracking data
    if (data['service'] is Map) {
      final servicePrice = data['service']?['base_price'] ?? 
                          data['service']?['price'] ?? 
                          data['service']?['basePrice'];
      if (servicePrice != null) {
        final price = servicePrice is num ? servicePrice.toDouble() : double.tryParse(servicePrice.toString()) ?? 0.0;
        if (price > 0.0) {
          return '\$${price.toStringAsFixed(2)}';
        }
      }
    }
    
    // FALLBACK: Get from API response total (this should already include discount if coupon was applied)
    final total = data['total'] ?? 
                data['total_amount'] ?? 
                data['price'] ?? 
                data['amount'] ??
                0.0;
    
    final totalAmount = total is num ? total.toDouble() : double.tryParse(total.toString()) ?? 0.0;
    
    return '\$${totalAmount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme colors for better compatibility
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
          onPressed: () {
            // Check if we can pop (there's a previous route)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // No previous route (came from notification), navigate to dashboard
              Get.offAllNamed('/dashboard');
            }
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Track Order',
            style: AppStyles.headlineBold.copyWith(color: textColor),
          ),
          subtitle: Text(
            bookingIdDisplay,
            style: AppStyles.detailLabel.copyWith(
              color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading tracking data',
                        style: TextStyle(color: textColor),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTrackingData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTrackingData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: <Widget>[
                        // 2. Main Content
                        _buildColoredSection(textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const SizedBox(height: 16),
                                 
                              // 3. Order Status Timeline Card
                              const SizedBox(height: 16),
                              _buildOrderStatusCard(cardBackgroundColor, textColor),

                            const SizedBox(height: 24),

                            // 4. Booking Detail Card
                            _buildBookingDetailCard(cardBackgroundColor, textColor),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
    );
  }

  Widget _buildColoredSection(Color textColor) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // Check if tracking data is available
        if (trackingData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading tracking data...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Check if washer is assigned - prevent map opening if no washer assigned
        final washerName = trackingData!['washer_name']?.toString();
        final washerId = trackingData!['washer_id'];
        
        if (washerName == null || washerName.isEmpty || washerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Waiting for washer assignment. Map will be available once a washer is assigned to your booking.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        // Navigate to map screen when image is clicked
        // IMPORTANT: Using booking address coordinates (from selected address during booking)
        // NOT device's current location. This is the service location the customer selected
        // from their saved addresses dropdown in stage 3 of booking.
        
        // Get address coordinates from booking (the address selected during booking)
        final customerLat = trackingData!['address_latitude'];
        final customerLng = trackingData!['address_longitude'];
        final address = trackingData!['address']?.toString() ?? 'Location';
        
        // DEBUG: Log coordinates being passed to map
        developer.log('📍 [TrackOrderScreen] Opening map with booking address coordinates:');
        developer.log('   Address: $address');
        developer.log('   Latitude: $customerLat');
        developer.log('   Longitude: $customerLng');
        developer.log('   Washer: $washerName');
        developer.log('   Tracking Data Keys: ${trackingData!.keys.toList()}');
        
        // Verify we have address coordinates (should always be present if address was selected from dropdown)
        if (customerLat == null || customerLng == null) {
          developer.log('❌ [TrackOrderScreen] Missing coordinates!');
          developer.log('   Full tracking data: $trackingData');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address location not available. Please ensure you selected an address during booking.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        // Convert coordinates to double
        final customerLatDouble = customerLat is num ? customerLat.toDouble() : double.tryParse(customerLat.toString());
        final customerLngDouble = customerLng is num ? customerLng.toDouble() : double.tryParse(customerLng.toString());
        
        if (customerLatDouble == null || customerLngDouble == null) {
          developer.log('❌ [TrackOrderScreen] Failed to parse coordinates!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid address coordinates. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        developer.log('✅ [TrackOrderScreen] Navigating to map with coordinates: $customerLatDouble, $customerLngDouble');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WasherTrackingMapScreen(
              bookingId: widget.bookingId,
              // These are the coordinates of the address selected during booking (from dropdown)
              customerLatitude: customerLatDouble,
              customerLongitude: customerLngDouble,
              customerAddress: address,
              washerName: washerName,
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness==Brightness.dark? Color(0xff4E76E1).withValues(alpha: 0.3): Color(0xff4E76E1).withValues(alpha: .3), // Keep the light blue background
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Container(
                width: 90,
                height: 70,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/send1.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.send,
                      size: 30,
                      color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10,),
            Text(
              'Live Tracking',
              style: AppStyles.bodyText.copyWith(
                color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Builder(
              builder: (context) {
                final lastUpdate = _lastUpdateTime;
                if (lastUpdate != null) {
                  final now = DateTime.now();
                  final diff = now.difference(lastUpdate);
                  String timeText;
                  if (diff.inSeconds < 10) {
                    timeText = 'Just now';
                  } else if (diff.inSeconds < 60) {
                    timeText = 'Updated ${diff.inSeconds}s ago';
                  } else {
                    timeText = 'Updated ${diff.inMinutes}m ago';
                  }
                  return Text(
                    timeText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkTheme 
                          ? DarkTheme.textTertiary 
                          : LightTheme.textTertiary,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: 4),
            Text(
              'Tap to view on map',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDarkTheme 
                    ? DarkTheme.textTertiary 
                    : LightTheme.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(Color cardBackgroundColor, Color textColor) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkTheme ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Order Status',
            style: GoogleFonts.inter(fontSize: 16,fontWeight: FontWeight.w600,color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.textPrimary : LightTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          // Timeline Steps
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  String? _getStatusSubtitle(OrderStatus status) {
    if (status == currentStatus) {
      switch (status) {
        case OrderStatus.confirmed:
          return trackingData?['washer_name'] == null 
              ? 'Waiting for washer assignment...' 
              : null;
        case OrderStatus.washerAssigned:
          final washerName = trackingData?['washer_name'];
          return washerName != null ? 'Washer: $washerName' : null;
        case OrderStatus.onTheWay:
          return 'Washer is on the way';
        case OrderStatus.arrived:
          return 'Washer has arrived';
        case OrderStatus.washing:
          return 'Washing in progress';
        case OrderStatus.completed:
          return 'Service completed';
      }
    }
    return null;
  }

  Widget _buildStatusTimeline() {
    // List of all tracking steps
    final List<Map<String, dynamic>> steps = [
      {'title': 'Confirmed', 'subtitle': 'In Progress...'},
      {'title': 'Washer Assigned', 'subtitle': null},
      {'title': 'On the Way', 'subtitle': null},
      {'title': 'Arrived', 'subtitle': null},
      {'title': 'Washing', 'subtitle': null},
      {'title': 'Completed', 'subtitle': null},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final int index = entry.key;
        final step = entry.value;
        final stepStatus = OrderStatus.values[index];
        final bool isActive = index <= currentStatus.index;
        final bool isCurrentStep = stepStatus == currentStatus;
        final bool isLast = index == steps.length - 1;
        final subtitle = isCurrentStep ? _getStatusSubtitle(stepStatus) : null;

        return _buildTimelineStep(
          title: step['title'] as String,
          subtitle: subtitle,
          isActive: isActive,
          isCurrentStep: isCurrentStep,
          isLast: isLast,
          imagePath: imagePath,
          index: index,
          onTap: () {
            // Status is controlled by backend, don't allow manual changes
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    required bool isActive,
    bool isCurrentStep = false,
    required bool isLast,
    required List<String> imagePath,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    // Determine the icon and color based on active status
    final Color stepColor = isActive
        ? AppColors.primaryBlueDark
        : (isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary);
    final Color circleColor = isActive
        ? AppColors.primaryBlueDark
        : (isDarkTheme ? DarkTheme.cardSecondary : LightTheme.cardSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Timeline Dot and Line
            SizedBox(height: 10,),
            Column(
          children: <Widget>[
            // The Circle (Dot)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isActive
                    ? const Icon(Icons.check,  size: 18)
                    : Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          index < imagePath.length ? imagePath[index] : imagePath[0],
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              size: 18,
                              color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                            );
                          },
                        ),
                      ),
              ),
            ),
            // The Connector Line
            if (!isLast)
              Container(
                width: 2.0,
                height: 40.0, // Height of the line segment
                color: isActive
                    ? AppColors.primaryBlueDark.withValues(alpha: 0.5)
                    : (isDarkTheme ? DarkTheme.cardSecondary : LightTheme.cardSecondary).withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(width: 16.0),
          // Title and Subtitle
          Padding(
          padding: EdgeInsets.only(top: isActive ? 4.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppStyles.bodyText.copyWith(
                  color: isActive ? stepColor : (isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isCurrentStep 
                          ? AppColors.primaryBlueDark 
                          : (isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary),
                      fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailCard(Color cardBackgroundColor, Color textColor) {
    if (trackingData == null) {
      return SizedBox.shrink();
    }
    
    final data = trackingData!;
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkTheme ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
            child: Text(
              'Booking Detail',
              style: AppStyles.subHeader.copyWith(color: textColor),
            ),
          ),
          const SizedBox(height: 16),
          // Booking Detail Rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: <Widget>[
                _buildDetailRow(
                  iconPath: 'assets/images/star.png',
                  label: 'Service',
                  value: data['service_name']?.toString() ?? 'Service',
                  backgroundColor: const Color(0xFFE8F0FF),
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/calendar.png',
                  label: 'Scheduled',
                  value: _formatSchedule(data['booking_date'], data['time_slot']),
                  backgroundColor: const Color(0xFFFFF2E6),
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/location.png',
                  label: 'Location',
                  value: data['address']?.toString() ?? 'Address not provided',
                  backgroundColor: const Color(0xFFE6FFFB),
                ),
                _buildDetailRow(
                  iconPath: 'assets/images/car.png',
                  label: 'Vehicle',
                  value: data['vehicle_type']?.toString().toUpperCase() ?? 'Vehicle',
                  backgroundColor: const Color(0xFFEFE8FF),
                ),
                Divider(
                  height: 32,
                  thickness: 1,
                  color: Theme.of(Get.context!).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
          // Total Amount Row
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total',
                  style: AppStyles.bodyText.copyWith(color: textColor),
                ),
                Text(
                  _getTotalPrice(data),
                  style: AppStyles.totalValue.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reused and adapted detail row builder from the previous screen
  Widget _buildDetailRow({
    required String iconPath,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Square Colored Background for Icon
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    iconPath,
                    // Use a dark color for the icon against the light background
                    color: AppColors.primaryBlueDark,
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