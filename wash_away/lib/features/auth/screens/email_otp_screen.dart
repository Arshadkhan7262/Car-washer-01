import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import 'package:wash_away/themes/dark_theme.dart';
import 'package:wash_away/themes/light_theme.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  bool _isPasswordReset = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _isPasswordReset = args?['isPasswordReset'] ?? false;
    final email = args?['email'] as String?;
    if (email != null) {
      final authController = Get.find<AuthController>();
      authController.setEmail(email);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtp() {
    return _controllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                ),
                onPressed: () => Get.back(),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Enter your OTP",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Enter your 4 digit OTP",
                  style: GoogleFonts.inter(
                    color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 60,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDarkTheme 
                            ? Colors.black.withValues(alpha: 0.25) 
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onChanged(index, value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Resend OTP
              Obx(() => authController.canResend.value
                  ? Center(
                      child: TextButton(
                        onPressed: () => authController.resendEmailOTP(),
                        child: Text(
                          "Resend OTP",
                          style: TextStyle(
                            color: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        "Resend OTP in ${authController.formattedTimer}",
                        style: TextStyle(
                          color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    )),
              const SizedBox(height: 32),
              // Error Message
              Obx(() => authController.errorMessage.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authController.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink()),
              // Done Button
              Obx(() => mainButton(
                    "Done",
                    () async {
                      final otp = _getOtp();
                      if (otp.length == 4) {
                        if (_isPasswordReset) {
                          // Show password reset dialog
                          _showPasswordResetDialog(context, otp);
                        } else {
                          await authController.verifyEmailOTP(otp);
                        }
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please enter 4-digit OTP',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    isLoading: authController.isVerifyingOTP.value,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context, String otp) {
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkTheme ? DarkTheme.card : LightTheme.card,
          title: Text(
            'Reset Password',
            style: TextStyle(
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(
                      color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                      color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  final authController = Get.find<AuthController>();
                  await authController.resetPassword(
                    otp,
                    _newPasswordController.text,
                  );
                }
              },
              child: Text(
                'Reset',
                style: TextStyle(
                  color: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

