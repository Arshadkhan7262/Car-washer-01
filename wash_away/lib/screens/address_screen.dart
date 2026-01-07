

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/address_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../features/addresses/services/address_service.dart';
import 'address_map_picker_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // --- STATE MANAGEMENT ---
  List<Address> _addresses = [];
  bool _isLoading = false;
  final AddressService _addressService = AddressService();

  // --- Theme Colors and Constants ---
  final Color primaryBlue = const Color(0xFF42A5F5);         // Primary Button/Icon Color
  late final Color segmentedButtonActive = primaryBlue;       // Active Label Button Color

  // --- Dialog State ---
  String _selectedLabel = 'Home';

  @override
  void initState() {
    super.initState();
    _selectedLabel = 'Home';
    _loadAddresses();
  }

  // --- ADDRESS ACTIONS ---

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final addresses = await _addressService.getAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load addresses: $e')),
        );
      }
    }
  }

  Future<void> _addAddress(String address, double latitude, double longitude) async {
    try {
      final isDefault = _addresses.isEmpty;
      final newAddress = await _addressService.createAddress(
        label: _selectedLabel,
        fullAddress: address,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      
      setState(() {
        _addresses.add(newAddress);
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add address: $e')),
        );
      }
    }
  }

  Future<void> _setAsDefault(Address address) async {
    try {
      if (address.id == null) return;
      await _addressService.setDefaultAddress(address.id!);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default: $e')),
        );
      }
    }
  }

  Future<void> _removeAddress(Address address) async {
    try {
      if (address.id == null) return;
      await _addressService.deleteAddress(address.id!);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: $e')),
        );
      }
    }
  }

  void _showMapPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressMapPickerScreen(
          selectedLabel: _selectedLabel,
          onAddressSelected: _addAddress,
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAddressCard(Address address) {
    // Determine the icon based on the label
    String imagePath;
    if (address.label == 'Home') {
      imagePath = 'assets/images/home5.png';
    } else if (address.label == 'Office') {
      imagePath = 'assets/images/home5.png';
    } else {
      imagePath = 'assets/images/home5.png';
    }

    // Colors for the default indicator
    final Color defaultTextColor = primaryBlue;

    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? DarkTheme.card : LightTheme.card,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Icon Box (Light Blue/Purple Box in the image)
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xff4E76E1).withValues(alpha: .3), // Using primary blue with opacity for light background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  imagePath,
                  // color: Color(0xff4E76E1).withValues(alpha: 0.3),
                  height: 30,
                  width: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Center: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label, // Home
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.fullAddress, // 123 house
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Edit and Delete Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Icon
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                      size: 20,
                    ),
                    onPressed: () {
                      // Handle edit
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Delete Icon
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), // Red trash can
                    onPressed: () => _removeAddress(address),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Row: Set as Default
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (address.isDefault)
              // Default indicator (Checkmark and text)
                Row(
                  children: [
                    Icon(Icons.check, size: 18, color: defaultTextColor),
                    const SizedBox(width: 4),
                    Text(
                      'Set as Default',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: defaultTextColor,
                      ),
                    ),
                  ],
                )
              else
              // Set as Default text button (without checkmark)
                GestureDetector(
                  onTap: () => _setAsDefault(address),
                  child: Text(
                    'Set as Default',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: defaultTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large Location Icon
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDarkTheme ? DarkTheme.card : LightTheme.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          // "No addresses saved" text
          Text(
            'No addresses saved',
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Add your home or office address',
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),
          // Add Address Button
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label:  Text(
              'Add Address',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // --- DIALOG LOGIC ---
  void _showAddAddressDialog(BuildContext context) {
    String currentSelectedLabel = _selectedLabel;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDarkTheme ? DarkTheme.card : LightTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                Widget _buildLabelButton(String label) {
                  final isSelected = currentSelectedLabel == label;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: label != 'Other' ? 8.0 : 0),
                      child: ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            currentSelectedLabel = label;
                            _selectedLabel = label;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected 
                              ? segmentedButtonActive 
                              : (isDarkTheme ? DarkTheme.cardSecondary : LightTheme.cardSecondary),
                          foregroundColor: isSelected 
                              ? Colors.white 
                              : (isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Add Address',
                              style: GoogleFonts.inter(
                                color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: isDarkTheme ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                        height: 20,
                      ),

                      Text(
                        'Label',
                        style: GoogleFonts.inter(
                          color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLabelButton('Home'),
                          _buildLabelButton('Office'),
                          _buildLabelButton('Other'),
                        ],
                      ),
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showMapPicker();
                          },
                          icon: const Icon(Icons.map, color: Colors.white),
                          label: Text(
                            'Select Location on Map',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- MAIN BUILD METHOD (CONDITIONAL DISPLAY) ---
  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Addresses',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark 
                ? DarkTheme.textPrimary 
                : LightTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            onPressed: () => _showAddAddressDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(_addresses[index]);
                    },
                  ),
                ),
    );
  }
}