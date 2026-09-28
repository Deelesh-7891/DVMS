import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:upgrader/upgrader.dart';

import 'screens/auth/login_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/security/security_home_screen.dart';
import 'screens/corporate_admin/corporate_admin_home_screen.dart';
// import 'screens/branch_admin/branch_admin_home_screen.dart';
import 'screens/accounts/accounts_home_screen.dart';
// import 'screens/state_admin/state_admin_home_screen.dart';

import 'core/auth/user_role.dart';

// ============================================================
// MAIN
// ============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // TIMEZONE

  // ==========================================================

  tz.initializeTimeZones();

  // ==========================================================
  // RUN APP
  // ==========================================================

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

      // ======================================================
      // APP TITLE
      // ======================================================

      title: 'Demo Vehicle Management',

      // ======================================================
      // APP UPDATE
      //
      // IMPORTANT:
      // UpgradeAlert is placed in builder so that it stays
      // above the complete Navigator.
      //
      // Therefore:
      //
      // Splash
      // Login
      // Driver Home
      // Security Home
      // Admin Home
      //
      // sab screens ke upar update popup show ho sakta hai.
      // ======================================================

      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return UpgradeAlert(
          upgrader: Upgrader(
            // ==================================================
            // CHECK STORE VERSION
            // ==================================================

            checkOnResume: true,

            // ==================================================
            // DEBUG
            //
            // Production me false rakhein.
            // ==================================================

            debugDisplayAlways: false,
            debugDisplayOnce: false,
            debugLogging: false,

            // ==================================================
            // POPUP AGAIN AFTER LATER
            // ==================================================

            durationUntilAlertAgain:
                const Duration(
              days: 1,
            ),

            // ==================================================
            // UPDATE LANGUAGE
            // ==================================================

            languageCode: 'en',

            // ==================================================
            // OPTIONAL:
            // Minimum supported version.
            //

            // Agar aap force update chahte hain to baad me
            // isko configure kar sakte hain.
            // ==================================================

            // minAppVersion: '1.0.3',
          ),

          // ====================================================
          // BUTTONS
          // ====================================================

          showIgnore: true,
          showLater: true,
          showReleaseNotes: true,

          // ====================================================
          // MATERIAL STYLE
          // Android screenshot jaisa
          // ====================================================

          dialogStyle: UpgradeDialogStyle.material,

          // ====================================================
          // DIALOG OUTSIDE TAP
          //
          // false = outside tap se popup close nahi hoga.
          // User ko IGNORE / LATER / UPDATE NOW me se
          // koi action lena hoga.
          // ====================================================

          barrierDismissible: false,

          // ====================================================
          // ACTUAL APP
          // ====================================================

          child: child ?? const SizedBox.shrink(),
        );
      },

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

// ============================================================
// SPLASH STATE
// ============================================================

class _SplashScreenState
    extends State<SplashScreen> {

  // ==========================================================
  // INIT STATE
  // ==========================================================

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
        milliseconds: 800,
      ),
    );

    if (!mounted) return;

    // ========================================================
    // CHECK LOGIN
    //
    // APP UPDATE IS NOW HANDLED GLOBALLY BY UpgradeAlert.
    //
    // Therefore yahan:
    //
    // AppUpdateService.checkForUpdate(context)
    //
    // call nahi karna hai.
    // ========================================================

    await checkLogin();
  }

  // ==========================================================
  // CHECK LOGIN
  // ==========================================================

  Future<void> checkLogin() async {
    try {
      // ======================================================
      // GET PREFERENCES
      // ======================================================

      final prefs =
          await SharedPreferences.getInstance();

      // ======================================================
      // LOGIN
      // ======================================================

      final bool isLogin =
          prefs.getBool(
                "isLogin",
              ) ??
              false;

      // ======================================================
      // TOKEN
      // ======================================================

      final String token =
          prefs.getString(
                "token",
              ) ??
              "";

      // ======================================================
      // ROLE NAME
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

      // ======================================================
      // CLEAN ROLE
      // ======================================================

      role = role.trim();

      final userRole =
          UserRole.fromApiValue(role);

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
      // SMALL WAIT
      // ======================================================

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!mounted) return;

      // ======================================================
      // NOT LOGGED IN
      // ======================================================

      if (!isLogin ||
          token.isEmpty ||
          userRole == null) {

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
        userRole,
      );

    } catch (e) {
      // ======================================================
      // LOGIN CHECK ERROR
      // ======================================================

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
    UserRole role,
  ) {
    Widget page;

    // ========================================================
    // ROLE SWITCH
    // ========================================================

    switch (role) {

      // ======================================================
      // CORPORATE ADMIN
      // ======================================================

      case UserRole.corporateAdmin:

        page =
            const CorporateAdminHomeScreen();

        break;

      // ======================================================
      // BRANCH ADMIN
      // ======================================================

      case UserRole.branchAdmin:

        page = const CorporateAdminHomeScreen();

        break;

      // ======================================================
      // DRIVER
      // ======================================================

      case UserRole.driver:

        page = const DriverHomeScreen();

        break;

      // ======================================================
      // SECURITY
      // ======================================================

      case UserRole.security:

        page = const SecurityHomeScreen();

        break;

      // ======================================================
      // ACCOUNTS
      // ======================================================

      case UserRole.accounts:

        page = const AccountsHomeScreen();

        break;

      // ======================================================
      // STATE ADMIN
      // ======================================================

      case UserRole.stateAdmin:

        page = const CorporateAdminHomeScreen();

        break;
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