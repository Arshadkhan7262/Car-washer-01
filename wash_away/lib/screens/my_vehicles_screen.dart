import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wash_away/models/add_vehicle_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../widgets/custom_text_field.dart';
import '../features/vehicles/services/vehicle_service.dart';

// --- Vehicle Data Model (For holding vehicle information) ---


class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  // --- STATE MANAGEMENT ---
  List<AddVehicleModel> _vehicles = [];
  bool _isLoading = false;
  final VehicleService _vehicleService = VehicleService();

  // --- Theme Colors and Constants ---
  final Color primaryBlue = const Color(0xFF42A5F5);

  // --- Dialog Controllers ---
  String? _selectedVehicleType;
  final List<String> vehicleTypes = ['Sedan', 'SUV', 'Truck', 'Bike'];
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVehicleType = vehicleTypes.first;
    _loadVehicles();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  // --- VEHICLE ACTIONS ---

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vehicles: $e')),
        );
      }
    }
  }

  Future<void> _addVehicle() async {
    if (_makeController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _colorController.text.isEmpty ||
        _plateNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      final isDefault = _vehicles.isEmpty;
      final newVehicle = await _vehicleService.createVehicle(
        make: _makeController.text,
        model: _modelController.text,
        plateNumber: _plateNumberController.text,
        color: _colorController.text,
        type: _selectedVehicleType!,
        isDefault: isDefault,
      );

      setState(() {
        _vehicles.add(newVehicle);
        _makeController.clear();
        _modelController.clear();
        _colorController.clear();
        _plateNumberController.clear();
        _selectedVehicleType = vehicleTypes.first;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add vehicle: $e')),
        );
      }
    }
  }

  Future<void> _setAsDefault(AddVehicleModel vehicle) async {
    try {
      if (vehicle.id == null) return;
      await _vehicleService.setDefaultVehicle(vehicle.id!);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default vehicle updated')),
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

  Future<void> _removeVehicle(AddVehicleModel vehicle) async {
    try {
      if (vehicle.id == null) return;
      await _vehicleService.deleteVehicle(vehicle.id!);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete vehicle: $e')),
        );
      }
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildVehicleCard(AddVehicleModel vehicle) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Blue Icon Box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xff2E70F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child:  Image.asset(
              'assets/images/car5.png',
              color: Colors.white,
              width: 20,
              height: 20,
              fit: BoxFit.fill,
            ),
          ),
          const SizedBox(width: 12),
          // Center: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.nameAndDetails,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.detailsLine,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // "Set as Default" Text Button
                if (!vehicle.isDefault)
                  GestureDetector(
                    onTap: () => _setAsDefault(vehicle),
                    child: Text(
                      'Set as Default',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryBlue,
                      ),
                    ),
                  )
                else
                // Default indicator
                  Row(
                    children: [
                      Icon(Icons.check, size: 16, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Set as Default', // Text from image is 'Set as Default' with a check
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryBlue,
                        ),
                      ),
                    ],
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
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                onPressed: () => _removeVehicle(vehicle),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
          // Large Car Icon
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDarkTheme ? DarkTheme.card : LightTheme.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_filled,
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No vehicles yet',
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to get started',
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),
          // Add Vehicle Button (Primary action in Empty State)
          ElevatedButton.icon(
            onPressed: () => _showAddVehicleDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label:  Text(
              'Add Vehicle',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E70F0),
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

  // --- DIALOG LOGIC (Modified to call _addVehicle on save) ---
  void _showAddVehicleDialog(BuildContext context) {
    // Reset controllers/state to clear previous inputs when the dialog opens
    _makeController.clear();
    _modelController.clear();
    _colorController.clear();
    _plateNumberController.clear();
    // Ensure dropdown state reflects the current vehicle types
    String? currentSelectedType = vehicleTypes.first; // Use local variable for fresh dialog state

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Vehicle',
      barrierColor: Colors.black.withValues(alpha: 0.6),
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
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Header
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Add Vehicle',
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

                      // Vehicle Type Dropdown
                      _buildInputLabelAndFieldForDropdown(
                        label: 'Vehicle Type',
                        dropdownValue: currentSelectedType,
                        items: vehicleTypes,
                        onChanged: (String? newValue) {
                          setModalState(() {
                            currentSelectedType = newValue;
                            // Update the main state variable used in _addVehicle
                            _selectedVehicleType = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      // Make and Model
                      Row(
                        children: [
                          Expanded(child: _buildInputLabelAndField('Make', _makeController)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInputLabelAndField('Model', _modelController)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Color and Plate Number
                      Row(
                        children: [
                          Expanded(child: _buildInputLabelAndField('Color', _colorController)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInputLabelAndField('Plate Number', _plateNumberController)),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Add Vehicle Button (CALLS _addVehicle)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _addVehicle, // Call the main state method
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E70F0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:  Text('Add Vehicle', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isDarkTheme 
                                    ? Colors.white.withValues(alpha: 0.25) 
                                    : Colors.black.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                          ),
                          child:  Text('Cancel', style: GoogleFonts.inter(fontSize: 16)),
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

  // Helper Widgets (Unchanged)
  Widget _buildInputField(TextEditingController controller, String hintText) {
    return CustomTextField(
      controller: controller,
      hintText: hintText,
    );
  }

  Widget _buildInputLabelAndField(String label, TextEditingController controller) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(controller, label),
      ],
    );
  }

  Widget _buildInputLabelAndFieldForDropdown({
    required String label,
    required String? dropdownValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDarkTheme ? DarkTheme.textSecondary : LightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.card: LightTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(Get.context!).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: dropdownValue,
              hint: Text(
                'Select $label',
                style: GoogleFonts.inter(
                  color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                ),
              ),
              isExpanded: true,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

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
          'My Vehicles',
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
                color: const Color(0xFF2E70F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            onPressed: () => _showAddVehicleDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      return _buildVehicleCard(_vehicles[index]);
                    },
                  ),
                ),
    );
  }
}