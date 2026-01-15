import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../features/bookings/services/washer_location_service.dart';

class WasherTrackingMapScreen extends StatefulWidget {
  final String bookingId;
  final double? customerLatitude;
  final double? customerLongitude;
  final String customerAddress;
  final String? washerName;

  const WasherTrackingMapScreen({
    super.key,
    required this.bookingId,
    this.customerLatitude,
    this.customerLongitude,
    required this.customerAddress,
    this.washerName,
  });

  @override
  State<WasherTrackingMapScreen> createState() => _WasherTrackingMapScreenState();
}

class _WasherTrackingMapScreenState extends State<WasherTrackingMapScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  
  final WasherLocationService _locationService = WasherLocationService();
  
  LatLng? _customerLocation;
  LatLng? _washerLocation;
  double _distance = 0.0; // in kilometers
  bool _isLoading = true;
  bool _isLocationAvailable = false;
  String? _locationError;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Initialize customer location IMMEDIATELY from widget parameters
    // This ensures the green marker is at the booking address, not device location
    // These coordinates come from address_latitude and address_longitude in API response
    if (widget.customerLatitude != null && widget.customerLongitude != null) {
      _customerLocation = LatLng(
        widget.customerLatitude!,
        widget.customerLongitude!,
      );
      print('📍 [WasherTrackingMap] ✅ Customer location set from BOOKING ADDRESS:');
      print('   Latitude: ${widget.customerLatitude}');
      print('   Longitude: ${widget.customerLongitude}');
      print('   Address: ${widget.customerAddress}');
      print('   This is from address_latitude/address_longitude in API response');
      print('   Green marker will be placed at these coordinates');
    } else {
      print('❌ [WasherTrackingMap] No booking coordinates provided!');
      print('   customerLatitude: ${widget.customerLatitude}');
      print('   customerLongitude: ${widget.customerLongitude}');
      _customerLocation = const LatLng(31.4504, 73.1350); // Default fallback
    }
    
    _initializeLocations();
    
    // Start periodic refresh every 3 seconds for real-time location updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _fetchWasherLocation();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeLocations() async {
    // Customer location is already set in initState from widget parameters
    // This is the SERVICE LOCATION (booking address selected during booking)
    // NOT from device's current location
    
    print('📍 [WasherTrackingMap] Initializing locations...');
    print('📍 [WasherTrackingMap] Customer location: $_customerLocation');
    print('📍 [WasherTrackingMap] Customer address: ${widget.customerAddress}');
    
    // Fetch real-time washer location (from washer's GPS device)
    await _fetchWasherLocation();
    
    // Only update state if widget is still mounted
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _updateMap();
    });
  }

  Future<void> _fetchWasherLocation() async {
    try {
      final locationData = await _locationService.getWasherLocation(widget.bookingId);
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      if (locationData != null && 
          locationData['latitude'] != null && 
          locationData['longitude'] != null) {
        setState(() {
          _washerLocation = LatLng(
            (locationData['latitude'] as num).toDouble(),
            (locationData['longitude'] as num).toDouble(),
          );
          _isLocationAvailable = true;
          _locationError = null;
          
          // Calculate distance between customer and washer
          if (_customerLocation != null && _washerLocation != null) {
            final newDistance = Geolocator.distanceBetween(
              _customerLocation!.latitude,
              _customerLocation!.longitude,
              _washerLocation!.latitude,
              _washerLocation!.longitude,
            ) / 1000; // Convert to kilometers
            
            _distance = newDistance;
            
            print('📍 [WasherTrackingMap] Distance updated: ${_distance.toStringAsFixed(2)} km');
            print('   Customer: ${_customerLocation!.latitude}, ${_customerLocation!.longitude}');
            print('   Washer: ${_washerLocation!.latitude}, ${_washerLocation!.longitude}');
          }
          
          _updateMap();
        });
      } else {
        if (!mounted) return;
        setState(() {
          _washerLocation = null;
          _isLocationAvailable = false;
          _locationError = 'Washer location not available yet';
        });
      }
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      setState(() {
        _washerLocation = null;
        _isLocationAvailable = false;
        _locationError = 'Failed to fetch washer location';
      });
    }
  }

  void _updateMap() {
    if (_mapController == null || !mounted) return;
    
    // Clear existing markers and polylines
    _markers.clear();
    _polylines.clear();
    
    // GREEN MARKER: This is the SERVICE LOCATION (booking address selected during booking)
    // Positioned at the coordinates from address_latitude and address_longitude in API response
    // These coordinates come from the dropdown selection in book_screen.dart
    // NOT the device's current location - the device location shows as a blue dot (myLocationEnabled)
    if (_customerLocation != null) {
      // Verify coordinates match expected booking address
      final expectedLat = 31.4140115;
      final expectedLng = 73.0713678;
      final actualLat = _customerLocation!.latitude;
      final actualLng = _customerLocation!.longitude;
      
      print('📍 [WasherTrackingMap] ==========================================');
      print('📍 [WasherTrackingMap] GREEN MARKER POSITION:');
      print('📍 [WasherTrackingMap]   Latitude: $actualLat');
      print('📍 [WasherTrackingMap]   Longitude: $actualLng');
      print('📍 [WasherTrackingMap]   Address: ${widget.customerAddress}');
      print('📍 [WasherTrackingMap]   Expected (from API): $expectedLat, $expectedLng');
      print('📍 [WasherTrackingMap]   Match: ${(actualLat - expectedLat).abs() < 0.0001 && (actualLng - expectedLng).abs() < 0.0001 ? "✅ YES" : "❌ NO"}');
      print('📍 [WasherTrackingMap] ==========================================');
      
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!, // This is from address_latitude/address_longitude
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Service Location',
            snippet: widget.customerAddress,
          ),
        ),
      );
    } else {
      print('❌ [WasherTrackingMap] Customer location is NULL! Green marker NOT added.');
      print('❌ [WasherTrackingMap] Widget customerLatitude: ${widget.customerLatitude}');
      print('❌ [WasherTrackingMap] Widget customerLongitude: ${widget.customerLongitude}');
    }
    
    // Add washer marker
    if (_washerLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('washer'),
          position: _washerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: widget.washerName ?? 'Washer',
            snippet: 'Distance: ${_distance.toStringAsFixed(2)} km',
          ),
        ),
      );
    }
    
    // Add polyline between customer and washer
    if (_customerLocation != null && _washerLocation != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_customerLocation!, _washerLocation!],
          color: Colors.blue,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
      
      // Fit bounds to show both markers
      _fitBounds();
    } else if (_customerLocation != null) {
      // If washer location not available yet, center on booking address location
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_customerLocation!, 14.0),
        );
      } catch (e) {
        // Silently handle errors when map controller is disposed or widget is unmounted
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _fitBounds() {
    if (_customerLocation == null || _washerLocation == null || _mapController == null || !mounted) {
      return;
    }
    
    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _customerLocation!.latitude < _washerLocation!.latitude
              ? _customerLocation!.latitude
              : _washerLocation!.latitude,
          _customerLocation!.longitude < _washerLocation!.longitude
              ? _customerLocation!.longitude
              : _washerLocation!.longitude,
        ),
        northeast: LatLng(
          _customerLocation!.latitude > _washerLocation!.latitude
              ? _customerLocation!.latitude
              : _washerLocation!.latitude,
          _customerLocation!.longitude > _washerLocation!.longitude
              ? _customerLocation!.longitude
              : _washerLocation!.longitude,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      // Silently handle errors when map controller is disposed or widget is unmounted
      print('⚠️ [WasherTrackingMap] Error fitting bounds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkTheme ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? DarkTheme.background : LightTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Tracking',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            // CRITICAL: Use booking address coordinates for initial camera position
            // This ensures the map starts centered on the service location, NOT device location
            initialCameraPosition: CameraPosition(
              target: _customerLocation ?? const LatLng(31.4504, 73.1350), // Default to Faisalabad if no booking address
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              
              // CRITICAL: Force center map on booking address location (green marker position)
              // NOT on device's current location
              // Use Future.delayed to ensure map is fully initialized
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted || _mapController == null) return;
                
                if (_customerLocation != null) {
                  try {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_customerLocation!, 14.0),
                    );
                    print('📍 [WasherTrackingMap] Map FORCED to center on booking address: $_customerLocation');
                    print('📍 [WasherTrackingMap] This is the service location from dropdown selection');
                  } catch (e) {
                    print('❌ [WasherTrackingMap] Error centering map: $e');
                  }
                } else {
                  print('⚠️ [WasherTrackingMap] Customer location is null, cannot center map');
                }
                
                // Update map with markers after centering
                _updateMap();
              });
            },
            markers: _markers,
            polylines: _polylines,
            // myLocationEnabled shows device location (blue dot) for reference
            // The green marker is at booking address coordinates (from address_latitude/address_longitude)
            myLocationEnabled: true,
            myLocationButtonEnabled: true, // User can tap to see their current location
            mapType: MapType.normal,
            zoomControlsEnabled: true,
          ),
          
          // Info Card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (!_isLocationAvailable || _washerLocation == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationError ?? 'Washer location not available yet',
                              style: GoogleFonts.inter(
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Washer Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.washerName ?? 'Washer',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'On the way to your location',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Distance Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkTheme ? DarkTheme.cardSecondary : LightTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            icon: Icons.location_on,
                            label: 'Distance',
                            value: '${_distance.toStringAsFixed(2)} km',
                            isDarkTheme: isDarkTheme,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDarkTheme
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                          _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'Est. Time',
                            value: _calculateEstimatedTime(),
                            isDarkTheme: isDarkTheme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Real-time tracking indicator
                    if (_isLocationAvailable)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Live tracking active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkTheme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  String _calculateEstimatedTime() {
    if (_distance == 0) return '--';
    
    // Assuming average speed of 30 km/h in city
    final estimatedMinutes = (_distance / 30 * 60).round();
    
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes min';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}

