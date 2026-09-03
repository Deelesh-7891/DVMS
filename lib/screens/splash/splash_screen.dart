import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import '../driver/driver_home_screen.dart';
import '../security/security_home_screen.dart';
import '../corporate_admin/corporate_admin_home_screen.dart';
import '../branch_admin/branch_admin_home_screen.dart';
import '../accounts/accounts_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {

    // Splash Screen 3 Seconds
    await Future.delayed(const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();

    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    String role = prefs.getString("role") ?? "";

    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    switch (role) {

      case "Driver":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverHomeScreen(),
          ),
        );
        break;

      case "Security":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SecurityHomeScreen(),
          ),
        );
        break;

      case "CorporateAdmin":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CorporateAdminHomeScreen(),
          ),
        );
        break;

      case "Branch Admin":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BranchAdminHomeScreen(),
          ),
        );
        break;

      case "Accounts":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountsHomeScreen(),
          ),
        );
        break;

      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
    }
  }

 
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,

    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Container(
            width: 148,
            height: 148,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2458A6).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/logo.png",
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Welcome",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xff2458A6),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Demo Vehicle Management",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Prem Motors Group",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 40),

          const CircularProgressIndicator(
            color: Color(0xff2458A6),
          ),
        ],
      ),
    ),
  );
}
}