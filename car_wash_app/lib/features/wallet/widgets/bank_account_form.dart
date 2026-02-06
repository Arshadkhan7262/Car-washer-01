import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:car_wash_app/theme/app_colors.dart';
import '../controllers/wallet_controller.dart';
import '../services/bank_account_service.dart';

/// Bank Account Form Widget
/// Allows washers to add or edit their bank account details
class BankAccountForm extends StatefulWidget {
  final Map<String, dynamic>? existingAccount;

  const BankAccountForm({super.key, this.existingAccount});

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  String _accountType = 'checking';
  bool _isLoading = false;

  final BankAccountService _bankAccountService = BankAccountService();

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount != null) {
      _accountHolderNameController.text = widget.existingAccount!['account_holder_name'] ?? '';
      _accountNumberController.text = widget.existingAccount!['account_number_last4'] ?? '';
      _routingNumberController.text = widget.existingAccount!['routing_number']?.toString().replaceAll('*', '') ?? '';
      _accountType = widget.existingAccount!['account_type'] ?? 'checking';
      _bankNameController.text = widget.existingAccount!['bank_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _saveBankAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _bankAccountService.saveBankAccount(
        accountHolderName: _accountHolderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        routingNumber: _routingNumberController.text.trim(),
        accountType: _accountType,
        bankName: _bankNameController.text.trim().isEmpty 
            ? null 
            : _bankNameController.text.trim(),
      );

      // Refresh wallet controller to update status
      final walletController = Get.find<WalletController>();
      await walletController.loadStripeAccountStatus();
      await walletController.refreshData(showLoader: false);

      Get.back();
      Get.snackbar(
        'Success',
        'Bank account saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.existingAccount != null ? 'Edit Bank Account' : 'Add Bank Account',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bank Account Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your bank account details to receive payouts',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              
              // Account Holder Name
              TextFormField(
                controller: _accountHolderNameController,
                style: TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  labelText: 'Account Holder Name *',
                  labelStyle: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  hintText: 'John Doe',
                  hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                  ),
                  prefixIcon: Icon(Icons.person, color: const Color(0xFF0A2540)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Number
              TextFormField(
                controller: _accountNumberController,
                style: TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  labelText: 'Account Number *',
                  labelStyle: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  hintText: '1234567890',
                  hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                  ),
                  prefixIcon: Icon(Icons.account_balance, color: const Color(0xFF0A2540)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account number';
                  }
                  if (value.trim().length < 4) {
                    return 'Account number must be at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Routing Number
              TextFormField(
                controller: _routingNumberController,
                style: TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  labelText: 'Routing Number *',
                  labelStyle: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  hintText: '123456789',
                  hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                  ),
                  prefixIcon: Icon(Icons.numbers, color: const Color(0xFF0A2540)),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 9,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter routing number';
                  }
                  if (value.trim().length != 9) {
                    return 'Routing number must be 9 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Type
              DropdownButtonFormField<String>(
                value: _accountType,
                style: TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  labelText: 'Account Type *',
                  labelStyle: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                  ),
                  prefixIcon: Icon(Icons.account_balance_wallet, color: const Color(0xFF0A2540)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'checking',
                    child: Text('Checking'),
                  ),
                  DropdownMenuItem(
                    value: 'savings',
                    child: Text('Savings'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _accountType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Bank Name (Optional)
              TextFormField(
                controller: _bankNameController,
                style: TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  labelText: 'Bank Name (Optional)',
                  labelStyle: TextStyle(color: AppColors.black.withOpacity(0.6)),
                  hintText: 'Chase Bank',
                  hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.black.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                  ),
                  prefixIcon: Icon(Icons.business, color: const Color(0xFF0A2540)),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBankAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2540),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Bank Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
