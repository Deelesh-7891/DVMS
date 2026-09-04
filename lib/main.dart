import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/auth/login_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/security/security_home_screen.dart';
import 'screens/corporate_admin/corporate_admin_home_screen.dart';
import 'screens/branch_admin/branch_admin_home_screen.dart';
import 'screens/accounts/accounts_home_screen.dart';

import 'services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  runApp(
    const MyApp(),
  );
}

// ============================================================
// APP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Demo Vehicle Management',

      // ========================================================
      // SPLASH
      // ========================================================

      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _startApp();
  }

  // ==========================================================
  // START APP
  // ==========================================================

  Future<void> _startApp() async {
    // ========================================================
    // WAIT UNTIL SCREEN IS READY
    // ========================================================

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) return;

    // ========================================================
    // CHECK APP UPDATE
    // ========================================================

    await AppUpdateService.checkForUpdate(
      context,
    );

    if (!mounted) return;

    // ========================================================
    // CHECK LOGIN
    // ========================================================

    await checkLogin();
  }

  // ==========================================================
  // CHECK LOGIN
  // ==========================================================

  Future<void> checkLogin() async {

    try {
    
      final prefs =
          await SharedPreferences.getInstance();

      // ======================================================
      // GET LOGIN DATA
      // ======================================================

      final bool isLogin =
          prefs.getBool(
                "isLogin",
              ) ??
              false;

      final String token =
          prefs.getString(
                "token",
              ) ??
              "";

      // ======================================================
      // ROLE
      // ======================================================

      String role =
          prefs.getString(
                "roleName",
              ) ??
              "";

      // ======================================================
      // FALLBACK ROLE
      // ======================================================

      if (role.trim().isEmpty) {
        role =
            prefs.getString(
                  "role",
                ) ??
                "";
      }

      role = role.trim();

      // ======================================================
      // DEBUG
      // ======================================================

      debugPrint(
        "======================================",
      );

      debugPrint(
        "SPLASH LOGIN CHECK",
      );

      debugPrint(
        "======================================",
      );

      debugPrint(
        "IS LOGIN     : $isLogin",
      );

      debugPrint(
        "TOKEN EXISTS : ${token.isNotEmpty}",
      );

      debugPrint(
        "ROLE NAME    : "
        "${prefs.getString("roleName")}",
      );

      debugPrint(
        "ROLE         : "
        "${prefs.getString("role")}",
      );

      debugPrint(
        "FINAL ROLE   : $role",
      );

      debugPrint(
        "======================================",
      );

      // ======================================================
      // WAIT
      // ======================================================

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!mounted) return;

      // ======================================================
      // NOT LOGIN
      // ======================================================

      if (!isLogin ||
          token.isEmpty ||
          role.isEmpty) {

        debugPrint(
          "SESSION INVALID -> LOGIN",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(),
          ),
        );

        return;
      }

      // ======================================================
      // SESSION FOUND
      // ======================================================

      debugPrint(
        "SESSION FOUND -> HOME",
      );

      openHomePage(
        role,
      );
    } catch (e) {
      debugPrint(
        "CHECK LOGIN ERROR: $e",
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );
    }
  }

  // ==========================================================
  // OPEN HOME PAGE
  // ==========================================================

  void openHomePage(
    String role,
  ) {
    Widget page;

    switch (role.trim()) {

      // ======================================================
      // CORPORATE ADMIN
      // ======================================================

      case "CorporateAdmin":

        page =
            const CorporateAdminHomeScreen();

        break;

      // ======================================================
      // BRANCH ADMIN
      // ======================================================

      case "BranchAdmin":

        page =
            const BranchAdminHomeScreen();

        break;

      // ======================================================
      // DRIVER
      // ======================================================

      case "Driver":

        page =
            const DriverHomeScreen();

        break;

      // ======================================================
      // SECURITY
      // ======================================================

      case "Security":

        page =
            const SecurityHomeScreen();

        break;

      // ======================================================
      // ACCOUNTS
      // ======================================================

      case "Accounts":

        page =
            const AccountsHomeScreen();

        break;

      // ======================================================
      // STATE ADMIN
      // ======================================================

      case "StateAdmin":

        page =
            const LoginScreen();

        break;

      // ======================================================
      // UNKNOWN
      // ======================================================

      default:

        debugPrint(
          "UNKNOWN ROLE: $role",
        );

        page =
            const LoginScreen();
    }

    // ========================================================
    // NAVIGATE
    // ========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}