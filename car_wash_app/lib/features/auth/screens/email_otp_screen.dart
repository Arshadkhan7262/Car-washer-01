import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../services/auth_service.dart';

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
    _initializeEmail();
  }

  Future<void> _initializeEmail() async {
    final args = Get.arguments as Map<String, dynamic>?;
    _isPasswordReset = args?['isPasswordReset'] ?? false;
    final emailFromArgs = args?['email'] as String?;
    final authController = Get.find<AuthController>();
    
    // Try to get email from arguments first (normal navigation)
    String? email = emailFromArgs;
    
    // If not in arguments, try to get from SharedPreferences (app restart scenario)
    if (email == null) {
      final authService = AuthService();
      email = await authService.getUserEmail();
    }
    
    // Set email if found
    if (email != null) {
      authController.setEmail(email);
    }
    
    // If app restarted and timer is 0, enable resend button
    // Timer should only start when OTP is actually sent, not when screen is shown
    // Timer is started in: registerWithEmail, requestPasswordReset, requestEmailOTP, resendEmailOTP
    if (authController.resendTimer.value == 0) {
      authController.canResend.value = true;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0E16)),
                onPressed: () => Get.back(),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Enter your OTP",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0E16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Obx(() {
                  final emailValue = authController.email.value;
                  return Column(
                    children: [
                      const Text(
                        "Enter your 4 digit OTP",
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
                      ),
                      if (emailValue != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Sent to: $emailValue",
                          style: const TextStyle(
                            color: Color(0xFF031E3D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
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
                    child: Builder(
                      builder: (context) {
                        final hasValue = _controllers[index].text.isNotEmpty;
                        return TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A0E16),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: hasValue ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                width: hasValue ? 2 : 1.5,
                              ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF031E3D),
                            width: 2,
                          ),
                        ),
                      ),
                          onChanged: (value) {
                            setState(() {}); // Trigger rebuild to update border color
                            _onChanged(index, value);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Resend OTP
              Obx(() {
                final isLoading = authController.isSendingOTP.value;
                final timerValue = authController.resendTimer.value;
                final canResend = authController.canResend.value;
                
                // Show resend button if: timer is 0 (app restarted or timer expired) OR canResend is true
                // Show timer button only if: timer is running (timer > 0)
                final showResendButton = timerValue == 0 || canResend;
                
                return showResendButton
                  ? Center(
                        child: InkWell(
                          onTap: isLoading ? null : () => authController.resendEmailOTP(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLoading 
                                    ? const Color(0xFFCBD5E1) 
                                    : const Color(0xFF031E3D),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF031E3D)),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.refresh,
                                    color: Color(0xFF031E3D),
                                    size: 18,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  isLoading ? "Sending..." : "Resend OTP",
                          style: TextStyle(
                                    color: isLoading 
                                        ? const Color(0xFF757575) 
                                        : const Color(0xFF031E3D),
                            fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFF757575),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                        "Resend OTP in ${authController.formattedTimer}",
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
              }),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
              child: const Text('Cancel'),
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
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

