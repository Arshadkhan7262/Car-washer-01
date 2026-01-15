import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../util/constants.dart';

class AddressMapPickerScreen extends StatefulWidget {
  final String selectedLabel;
  final Function(String address, double latitude, double longitude) onAddressSelected;

  const AddressMapPickerScreen({
    super.key,
    required this.selectedLabel,
    required this.onAddressSelected,
  });

  @override
  State<AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends State<AddressMapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  String? _lastProcessedPlaceId; // To prevent duplicate processing

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            if (!mounted) return;
            setState(() {
              _selectedLocation = newPosition;
              _markers = {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: newPosition,
                  draggable: true,
                  onDragEnd: (pos) {
                    if (!mounted) return;
                    setState(() {
                      _selectedLocation = pos;
                      _markers = {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: pos,
                          draggable: true,
                        ),
                      };
                    });
                    _getAddressFromCoordinates(pos);
                  },
                ),
              };
            });
            _getAddressFromCoordinates(newPosition);
          },
        ),
      };
      setState(() {
        _selectedLocation = location;
        _isLoading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );
      await _getAddressFromCoordinates(location);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Default to a common location if GPS fails
      final defaultLocation = LatLng(31.4504, 73.1350); // Faisalabad
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: defaultLocation,
          draggable: true,
          onDragEnd: (newPosition) {
            if (!mounted) return;
            setState(() {
              _selectedLocation = newPosition;
              _markers = {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: newPosition,
                  draggable: true,
                  onDragEnd: (pos) {
                    if (!mounted) return;
                    setState(() {
                      _selectedLocation = pos;
                      _markers = {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: pos,
                          draggable: true,
                        ),
                      };
                    });
                    _getAddressFromCoordinates(pos);
                  },
                ),
              };
            });
            _getAddressFromCoordinates(newPosition);
          },
        ),
      };
      setState(() => _selectedLocation = defaultLocation);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(defaultLocation, 15.0),
      );
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      // Use reverse geocoding to get address
      // This is a simplified version - you may want to use Google Geocoding API
      if (!mounted) return;
      setState(() {
        _selectedAddress = '${location.latitude}, ${location.longitude}';
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapTap(LatLng location) {
    if (!mounted) return;
    _markers = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        draggable: true,
        onDragEnd: (newPosition) {
          if (!mounted) return;
          setState(() {
            _selectedLocation = newPosition;
            _markers = {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: newPosition,
                draggable: true,
                onDragEnd: (pos) {
                  if (!mounted) return;
                  setState(() {
                    _selectedLocation = pos;
                    _markers = {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: pos,
                        draggable: true,
                      ),
                    };
                  });
                  _getAddressFromCoordinates(pos);
                },
              ),
            };
          });
          _getAddressFromCoordinates(newPosition);
        },
      ),
    };
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromCoordinates(location);
  }

  void _onPlaceSelected(Prediction prediction) async {
    if (!mounted) return;
    
    // Prevent duplicate processing if same place is selected again quickly
    if (_lastProcessedPlaceId == prediction.placeId && _isLoading) {
      print('⏭️ Skipping duplicate selection for: ${prediction.placeId}');
      return;
    }
    
    _lastProcessedPlaceId = prediction.placeId;
    setState(() => _isLoading = true);
    
    debugPrint('📍 Place selected: ${prediction.description}');
    debugPrint('📍 Place ID: ${prediction.placeId}');
    debugPrint('📍 Prediction lat: ${prediction.lat}, lng: ${prediction.lng}');
    print('📍 Place selected: ${prediction.description}');
    print('📍 Place ID: ${prediction.placeId}');
    print('📍 Prediction lat: ${prediction.lat}, lng: ${prediction.lng}');
    
    // Debug: Print all prediction properties
    debugPrint('📍 Prediction toString: $prediction');
    print('📍 Prediction toString: $prediction');
    
    // Show visual feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecting: ${prediction.description}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    try {
      LatLng? location;
      
      // Method 1: Try to get coordinates from prediction if available
      if (prediction.lat != null && prediction.lng != null) {
        try {
          location = LatLng(
            double.parse(prediction.lat!),
            double.parse(prediction.lng!),
          );
          print('✅ Got coordinates from prediction.lat/lng: $location');
        } catch (e) {
          print('❌ Error parsing lat/lng from prediction: $e');
        }
      }
      
      // Method 2: Check if lat/lng are in different format (as doubles or in JSON)
      if (location == null) {
        try {
          // Try accessing as dynamic and check for lat/lng
          // Note: toJson() might not exist on all Prediction implementations
          try {
            final predictionMap = prediction.toJson();
            print('📍 Prediction JSON: $predictionMap');
            if (predictionMap['lat'] != null && predictionMap['lng'] != null) {
              location = LatLng(
                (predictionMap['lat'] is num) ? predictionMap['lat'].toDouble() : double.parse(predictionMap['lat'].toString()),
                (predictionMap['lng'] is num) ? predictionMap['lng'].toDouble() : double.parse(predictionMap['lng'].toString()),
              );
              print('✅ Got coordinates from prediction JSON: $location');
            }
          } catch (e) {
            print('📍 toJson() not available or failed: $e');
          }
        } catch (e) {
          print('❌ Error getting coordinates from JSON: $e');
        }
      }
      
      // Method 3: Fetch using placeId if still not available
      if (location == null && prediction.placeId != null) {
        print('🔄 Fetching coordinates using placeId: ${prediction.placeId}');
        try {
          final apiKey = 'AIzaSyDQTjH85etAVOY56-3AZ3oydpI3414ZsMU';
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&fields=geometry&key=$apiKey'
          );
          
          print('🌐 API URL: $url');
          final response = await http.get(url);
          print('📡 Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('📦 Response status from API: ${data['status']}');
            
            if (data['status'] == 'OK' && data['result'] != null && data['result']['geometry'] != null) {
              final geometry = data['result']['geometry'];
              final locationData = geometry['location'];
              if (locationData != null) {
                final lat = locationData['lat'];
                final lng = locationData['lng'];
                print('📍 Extracted from API - lat: $lat, lng: $lng');
                
                if (lat != null && lng != null) {
                  location = LatLng(
                    (lat is num) ? lat.toDouble() : double.parse(lat.toString()),
                    (lng is num) ? lng.toDouble() : double.parse(lng.toString()),
                  );
                  print('✅ Created location from API: $location');
                }
              }
            } else {
              print('❌ API returned error: ${data['status']}');
              if (data['error_message'] != null) {
                print('❌ Error message: ${data['error_message']}');
              }
            }
          } else {
            print('❌ HTTP Error: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        } catch (e, stackTrace) {
          print('❌ Error fetching coordinates from placeId: $e');
          print('Stack trace: $stackTrace');
        }
      }
      
      if (location != null) {
        print('✅ Final location to use: $location');
        if (!mounted) return;
        
        // Store location in a non-null variable for use in setState
        final selectedLocation = location;
        
        // Update everything in a single setState to ensure rebuild
        setState(() {
          _selectedLocation = selectedLocation;
          _selectedAddress = prediction.description ?? '';
          
          // Update markers set INSIDE setState
          _markers = {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: selectedLocation,
              draggable: true,
              onDragEnd: (newPosition) {
                if (!mounted) return;
                setState(() {
                  _selectedLocation = newPosition;
                  _markers = {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: newPosition,
                      draggable: true,
                      onDragEnd: (pos) {
                        if (!mounted) return;
                        setState(() {
                          _selectedLocation = pos;
                          _markers = {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: pos,
                              draggable: true,
                            ),
                          };
                        });
                        _getAddressFromCoordinates(pos);
                      },
                    ),
                  };
                });
                _getAddressFromCoordinates(newPosition);
              },
            ),
          };
          
          _isLoading = false;
        });
        
        print('🎯 Animating camera to: $selectedLocation');
        
        // Wait a bit to ensure map controller is ready, then animate camera
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Move camera and marker to selected place
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLocation, 15.0),
        );
        
        // Force a rebuild to ensure marker is visible
        if (mounted) {
          setState(() {
            // Trigger rebuild to show marker
          });
        }
        
        // Get address from coordinates for better address display
        await _getAddressFromCoordinates(selectedLocation);
        debugPrint('✅ Location updated successfully - marker should be visible now');
        print('✅ Location updated successfully - marker should be visible now');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Location selected! Marker moved.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ Warning: Could not get coordinates for selected place');
        if (!mounted) return;
        setState(() {
          _selectedAddress = prediction.description ?? '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error selecting place: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSave() {
    if (_selectedLocation != null && _selectedAddress != null) {
      widget.onAddressSelected(
        _selectedAddress!,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.inter(
            color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          if (_selectedLocation != null)
            GoogleMap(
              key: ValueKey('${_selectedLocation!.latitude}_${_selectedLocation!.longitude}'),
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
            )
          else
            Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF42A5F5),
              ),
            ),

          // Search Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: 'AIzaSyDQTjH85etAVOY56-3AZ3oydpI3414ZsMU', // Replace with your API key
                inputDecoration: InputDecoration(
                  hintText: 'Search for a place...',
                  hintStyle: GoogleFonts.inter(
                    color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                ),
                debounceTime: 400,
                countries: const ['pk'], // Pakistan
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (prediction) {
                  debugPrint('🔵 getPlaceDetailWithLatLng called');
                  print('🔵 getPlaceDetailWithLatLng called');
                  _onPlaceSelected(prediction);
                },
                itemClick: (prediction) {
                  debugPrint('🟢 itemClick called - processing selection');
                  print('🟢 itemClick called - processing selection');
                  // Also handle selection here in case getPlaceDetailWithLatLng doesn't fire
                  // The getPlaceDetailWithLatLng should fire after this, but we'll handle both
                  _onPlaceSelected(prediction);
                },
                itemBuilder: (context, index, prediction) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFF42A5F5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prediction.description ?? '',
                            style: GoogleFonts.inter(
                              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                seperatedBuilder: const Divider(),
                containerHorizontalPadding: 10,
              ),
            ),
          ),

          // Selected Address Display
          if (_selectedAddress != null)
            Positioned(
              bottom: 100,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Address',
                      style: GoogleFonts.inter(
                        color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedAddress!,
                      style: GoogleFonts.inter(
                        color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Save Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Location',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

