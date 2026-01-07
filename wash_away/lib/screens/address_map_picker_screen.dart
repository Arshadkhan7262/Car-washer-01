import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geolocator/geolocator.dart';
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
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = location;
        _isLoading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );
      await _getAddressFromCoordinates(location);
    } catch (e) {
      setState(() => _isLoading = false);
      // Default to a common location if GPS fails
      final defaultLocation = LatLng(31.4504, 73.1350); // Faisalabad
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
      setState(() {
        _selectedAddress = '${location.latitude}, ${location.longitude}';
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromCoordinates(location);
  }

  void _onPlaceSelected(Prediction prediction) async {
    setState(() => _isLoading = true);
    try {
      // Get place details using Places API
      // For now, we'll use the prediction description
      setState(() {
        _selectedAddress = prediction.description ?? '';
        _isLoading = false;
      });
      
      // Move camera to selected place (you'll need to get lat/lng from place details)
      // This requires additional Places API call
    } catch (e) {
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
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                        draggable: true,
                        onDragEnd: (newPosition) {
                          setState(() {
                            _selectedLocation = newPosition;
                          });
                          _getAddressFromCoordinates(newPosition);
                        },
                      ),
                    }
                  : {},
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
                  _onPlaceSelected(prediction);
                },
                itemClick: (prediction) {
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

