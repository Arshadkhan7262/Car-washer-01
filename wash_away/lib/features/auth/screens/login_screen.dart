import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'package:wash_away/themes/dark_theme.dart';
import 'package:wash_away/themes/light_theme.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "Welcome to Wash Away",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to continue",
                    style: GoogleFonts.inter(
                      color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Google Button
                  googleButton(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDarkTheme 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "or",
                          style: TextStyle(
                            color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDarkTheme 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                  // Password Field
                  AuthTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "********",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => const ResetPasswordScreen()),
                      child: Text(
                        "Forget Password?",
                        style: TextStyle(
                          color: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  // Sign In Button
                  Obx(() => mainButton(
                        "Sign In",
                        () async {
                          if (_formKey.currentState!.validate()) {
                            await authController.loginWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );
                          }
                        },
                        isLoading: authController.isLoggingIn.value,
                      )),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Get.to(() => const SignUpScreen()),
                    child: Text(
                      "Need an account? Sign Up",
                      style: TextStyle(
                        color: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

