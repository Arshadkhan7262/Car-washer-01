import 'package:get/get.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/dashboard_binding.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_binding.dart';
import 'features/jobs/screens/jobs_screen.dart';
import 'features/jobs/jobs_binding.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/wallet/wallet_binding.dart';
import 'features/profile/profile_binding.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/email_otp_screen.dart';
import 'features/auth/auth_binding.dart';

/// Application Routes
class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String emailOtpVerify = '/email-otp-verify';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String jobs = '/jobs';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  // Initial route - check if logged in, otherwise show login
  static const String initial = login;

  /// Get all routes
  static List<GetPage> getRoutes() {
    return [
      // Authentication routes - All auth screens need AuthController
      GetPage(
        name: login,
        page: () => const LoginScreen(),
        binding: AuthBinding(),
      ),
      GetPage(
        name: signup,
        page: () => const SignUpScreen(),
        binding: AuthBinding(),
      ),
      GetPage(
        name: resetPassword,
        page: () => const ResetPasswordScreen(),
        binding: AuthBinding(),
      ),
      GetPage(
        name: emailOtpVerify,
        page: () => const EmailOtpScreen(),
        binding: AuthBinding(),
      ),
      // Main app routes
      GetPage(
        name: dashboard,
        page: () => const DashboardScreen(),
        binding: DashboardBinding(),
      ),
      GetPage(
        name: home,
        page: () => const HomeScreen(),
        binding: HomeBinding(),
      ),
      GetPage(
        name: jobs,
        page: () => const JobsScreen(),
        binding: JobsBinding(),
      ),
      GetPage(
        name: wallet,
        page: () => const WalletScreen(),
        binding: WalletBinding(),
      ),
      GetPage(
        name: profile,
        page: () => const ProfileScreen(),
        binding: ProfileBinding(),
      ),
    ];
  }
}
