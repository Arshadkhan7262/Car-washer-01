
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/auth_binding.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/email_otp_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'screens/resume_booking_screen.dart';
import 'controllers/theme_controller.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';
import 'features/auth/services/auth_service.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import 'features/bookings/services/draft_booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase before running the app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Continue app execution even if Firebase fails (fallback will handle it)
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? initialRoute;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      // If logged in, verify token is still valid by checking user status
      if (isLoggedIn) {
        final statusData = await authService.checkUserStatus();
        if (statusData != null) {
          // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
          // Check if there's a draft booking
          // final draftBookingService = DraftBookingService();
          // final hasDraft = await draftBookingService.checkDraftExists();
          
          setState(() {
            // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
            // if (hasDraft) {
            //   initialRoute = '/resume-booking';
            // } else {
            //   initialRoute = '/dashboard';
            // }
            initialRoute = '/dashboard';
            isLoading = false;
          });
          return;
        }
      }
      
      // Not logged in or token invalid
      setState(() {
        initialRoute = '/login';
        isLoading = false;
      });
    } catch (e) {
      // On error, default to login
      setState(() {
        initialRoute = '/login';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    
    if (isLoading) {
      return MaterialApp(
        title: 'Wash Away',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return Obx(() => GetMaterialApp(
      title: 'Wash Away',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.themeData,
      darkTheme: DarkTheme.themeData,
      themeMode: themeController.isDarkMode.value 
          ? ThemeMode.dark 
          : ThemeMode.light,
      initialBinding: AuthBinding(),
      initialRoute: initialRoute ?? '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/signup',
          page: () => const SignUpScreen(),
        ),
        GetPage(
          name: '/email-otp-verify',
          page: () => const EmailOtpScreen(),
        ),
        GetPage(
          name: '/reset-password',
          page: () => const ResetPasswordScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardScreen(),
        ),
        // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
        // GetPage(
        //   name: '/resume-booking',
        //   page: () => const ResumeBookingScreen(),
        // ),
      ],
    ));
  }
}
