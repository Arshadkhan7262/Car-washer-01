import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0E16)),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Reset your Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0E16),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your email and we'll send you a link to reset your password",
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                // Email Field
                AuthTextField(
                  controller: _emailController,
                  label: "Email",
                  hint: "abc@gmail.com",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
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
                // Send Reset Link Button
                Obx(() => mainButton(
                      "Send reset link",
                      () async {
                        if (_formKey.currentState!.validate()) {
                          authController.setEmail(_emailController.text.trim());
                          await authController.requestPasswordReset(
                            _emailController.text.trim(),
                          );
                        }
                      },
                      isLoading: authController.isResettingPassword.value,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
