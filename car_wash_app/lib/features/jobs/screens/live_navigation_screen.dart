import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';

class LiveNavigationScreen extends StatefulWidget {
  final String customerAddress;
  final String customerName;
  final double? customerLatitude;
  final double? customerLongitude;

  const LiveNavigationScreen({
    super.key,
    required this.customerAddress,
    required this.customerName,
    this.customerLatitude,
    this.customerLongitude,
  });

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _customerLocation;
  StreamSubscription<Position>? _positionStream;
  double _distanceInKm = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _parseCustomerLocation();
    await _initializeLocationTracking();
  }

  Future<void> _parseCustomerLocation() async {
    try {
      // First try to use provided latitude/longitude
      if (widget.customerLatitude != null && widget.customerLongitude != null) {
        setState(() {
          _customerLocation = LatLng(widget.customerLatitude!, widget.customerLongitude!);
        });
        return;
      }
      
      // Fallback: Try to parse from address string format: "31.4140064, 73.071362, ..."
      final parts = widget.customerAddress.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        
        if (lat != null && lng != null) {
          setState(() {
            _customerLocation = LatLng(lat, lng);
          });
          return;
        }
      }
      
      // If coordinates not available, geocode the address
      await _geocodeAddress(widget.customerAddress);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing location: $e';
        _isLoading = false;
      });
    }
  }

  /// Geocode address text to get coordinates
  Future<void> _geocodeAddress(String address) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Use OpenStreetMap Nominatim API (free, no API key required)
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '0');
          final lng = double.tryParse(result['lon']?.toString() ?? '0');
          
          if (lat != null && lng != null && lat != 0 && lng != 0) {
            setState(() {
              _customerLocation = LatLng(lat, lng);
              _isLoading = false;
            });
            return;
          }
        }
        
        // If geocoding fails, try to geocode just the city name
        await _geocodeCityName(address);
      } else {
        // If API fails, try to extract city name and geocode that
        await _geocodeCityName(address);
      }
    } catch (e) {
      // If geocoding fails, try to extract city name and geocode that
      await _geocodeCityName(address);
    }
  }

  /// Try to geocode just the city name from the address
  Future<void> _geocodeCityName(String address) async {
    try {
      // Extract city name (usually first part before comma)
      final cityName = address.split(',').first.trim();
      
      if (cityName.isEmpty) {
        throw Exception('Could not extract city name from address');
      }

      final encodedCity = Uri.encodeComponent(cityName);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedCity&format=json&limit=1'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CarWashApp/1.0', // Required by Nominatim
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '0');
          final lng = double.tryParse(result['lon']?.toString() ?? '0');
          
          if (lat != null && lng != null && lat != 0 && lng != 0) {
            setState(() {
              _customerLocation = LatLng(lat, lng);
              _isLoading = false;
            });
            return;
          }
        }
        
        setState(() {
          _errorMessage = 'Could not find location for address: $address. Please check the address and try again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not geocode address. Please ensure the address is correct.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not find location. Please check the address: $address';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeLocationTracking() async {
    // Request location permissions
    final status = await Permission.location.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Location permission denied. Please enable location access in settings.';
        _isLoading = false;
      });
      return;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable location services.';
        _isLoading = false;
      });
      return;
    }

    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _isLoading = false;
      });

      // Calculate initial distance
      if (_customerLocation != null && _currentPosition != null) {
        _updateDistance();
      }

      // Listen to position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          setState(() {
            _currentPosition = position;
          });
          _updateDistance();
          _updateMapCamera();
        },
        onError: (error) {
          if (mounted) {
            Get.snackbar(
              'Location Error',
              'Error getting location: $error',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _updateDistance() {
    if (_customerLocation != null && _currentPosition != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _customerLocation!.latitude,
        _customerLocation!.longitude,
      );
      setState(() {
        _distanceInKm = distance / 1000; // Convert to kilometers
      });
    }
  }

  void _updateMapCamera() {
    if (_mapController != null && 
        _currentPosition != null && 
        _customerLocation != null) {
      // Fit bounds to show both locations
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _customerLocation!.latitude
              ? _currentPosition!.latitude
              : _customerLocation!.latitude,
          _currentPosition!.longitude < _customerLocation!.longitude
              ? _currentPosition!.longitude
              : _customerLocation!.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _customerLocation!.latitude
              ? _currentPosition!.latitude
              : _customerLocation!.latitude,
          _currentPosition!.longitude > _customerLocation!.longitude
              ? _currentPosition!.longitude
              : _customerLocation!.longitude,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  Future<void> _openInMaps() async {
    if (_customerLocation == null) {
      Get.snackbar(
        'Error',
        'Customer location not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Use coordinates for more accurate navigation
    final lat = _customerLocation!.latitude;
    final lng = _customerLocation!.longitude;
    
    // Try to open in Google Maps first
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Apple Maps on iOS
      final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open maps app',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        surfaceTintColor: AppColors.white,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Live Navigation",
          style: TextStyle(
            fontFamily: "Inter",
            color: AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF138EC3),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoading = true;
                            });
                            _initializeLocationTracking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF138EC3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null || _customerLocation == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF138EC3),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 14,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Update camera to show both locations after map is created
            Future.delayed(const Duration(milliseconds: 500), () {
              _updateMapCamera();
            });
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          markers: {
            // Customer location marker
            Marker(
              markerId: const MarkerId('customer'),
              position: _customerLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: widget.customerName,
                snippet: widget.customerAddress,
              ),
            ),
            // Washer current location marker
            Marker(
              markerId: const MarkerId('washer'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(
                title: 'Your Location',
              ),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                _customerLocation!,
              ],
              color: const Color(0xFF138EC3),
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          },
        ),
        // Info card at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF138EC3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.customerAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      color: Color(0xFF138EC3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Distance: ${_distanceInKm.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text(
                    "Open in Maps App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF138EC3),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
