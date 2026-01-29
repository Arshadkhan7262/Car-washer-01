import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../widgets/custom_text_field.dart';
import '../api/api_client.dart';
import '../features/auth/services/auth_service.dart';
import '../controllers/profile_controller.dart';

class AddFundsScreen extends StatefulWidget {
  final double? initialAmount;
  final ProfileController? profileController; // Optional controller to reuse existing instance
  
  const AddFundsScreen({super.key, this.initialAmount, this.profileController});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _apiClient = ApiClient();
  final _authService = AuthService();
  ProfileController? _profileController;
  bool _isProcessing = false;
  final List<double> _quickAmounts = [10.0, 25.0, 50.0, 100.0, 200.0];
  
  ProfileController get profileController {
    if (_profileController == null) {
      _initializeController();
      // If still null after initialization, create a temporary one
      if (_profileController == null) {
        _profileController = ProfileController();
      }
    }
    return _profileController!;
  }
  
  @override
  void initState() {
    super.initState();
    debugPrint('🔄 AddFundsScreen initState called');
    
    // Initialize controller immediately if provided, otherwise after first frame
    if (widget.profileController != null) {
      _profileController = widget.profileController;
      debugPrint('✅ Using provided ProfileController');
    } else {
      // Initialize controller after first frame to avoid crash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeController();
        }
      });
    }
    
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    
    debugPrint('✅ AddFundsScreen initState completed');
  }
  
  void _initializeController() {
    // Use provided controller if available
    if (widget.profileController != null) {
      _profileController = widget.profileController;
      debugPrint('✅ ProfileController provided from parent');
      return;
    }
    
    try {
      if (Get.isRegistered<ProfileController>()) {
        _profileController = Get.find<ProfileController>();
        debugPrint('✅ ProfileController found in GetX');
      } else {
        // Use Get.put with permanent: false to avoid conflicts
        debugPrint('🔄 Creating new ProfileController');
        _profileController = Get.put(ProfileController(), permanent: false);
        debugPrint('✅ ProfileController created');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing ProfileController: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback: create new instance if Get.find fails
      try {
        _profileController = Get.put(ProfileController(), permanent: false);
        debugPrint('✅ ProfileController created in fallback');
      } catch (e2, stackTrace2) {
        debugPrint('❌ Failed to create ProfileController with GetX: $e2');
        debugPrint('Stack trace 2: $stackTrace2');
        // Last resort: create without GetX (won't have reactive updates)
        // Don't call fetchProfile() as it might cause crash
        _profileController = ProfileController();
        // Set a default balance to avoid null issues
        _profileController?.walletBalance.value = 0.0;
        debugPrint('✅ ProfileController created without GetX (dummy mode)');
      }
    }
  }


  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addFunds() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (amount < 5.0) {
      Get.snackbar(
        'Minimum Amount',
        'Minimum amount to add is \$5.00',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final token = await _authService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please sign in again to add funds.');
      }
      _apiClient.setAuthToken(token);

      // Call backend add-funds with dummy flag (no Stripe; credits wallet for testing)
      final response = await _apiClient.post(
        '/customer/wallet/add-funds',
        body: {
          'amount': amount,
          'is_dummy': true,
        },
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to add funds');
      }

      final data = response.data;
      final payload = data is Map ? (data['data'] as Map<String, dynamic>?) : null;
      final newBalance = payload != null && payload['wallet_balance'] != null
          ? (payload['wallet_balance'] as num).toDouble()
          : null;

      final controller = profileController;
      if (newBalance != null) {
        controller.walletBalance.value = newBalance;
      } else {
        await controller.fetchProfile();
      }

      if (mounted) {
        Get.snackbar(
          'Success',
          '\$${amount.toStringAsFixed(2)} added to wallet successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Navigator.pop(context, {
          'success': true,
          'amount': amount,
          'new_balance': newBalance ?? controller.walletBalance.value,
        });
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        Get.snackbar(
          'Error',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: Text(
          'Add Funds to Wallet',
          style: GoogleFonts.inter(
            color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E3A5F),
                          const Color(0xFF2D4A6F),
                        ]
                      : [
                          const Color(0xFF2E70F0),
                          const Color(0xFF1E5FCF),
                        ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.blue : Colors.blue).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Wallet Balance',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    try {
                      final controller = _profileController;
                      if (controller == null) {
                        return Text(
                          '\$0.00',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      final balance = controller.walletBalance.value;
                      return Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error displaying balance: $e');
                      return Text(
                        '\$0.00',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),

            Text(
              'Enter Amount',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _amountController,
              hintText: '0.00',
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              borderRadius: 12,
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Amounts',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((amount) {
                return GestureDetector(
                  onTap: () {
                    _amountController.text = amount.toStringAsFixed(2);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? DarkTheme.card : LightTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Minimum amount: \$5.00',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? DarkTheme.textTertiary : LightTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _addFunds,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? DarkTheme.primary : LightTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Add Funds',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

