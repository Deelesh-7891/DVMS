import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import 'home_tab.dart';
import 'scan_qr_screen.dart';
import 'manual_entry_screen.dart';

class SecurityHomeScreen extends StatefulWidget {
  const SecurityHomeScreen({
    super.key,
  });

  @override
  State<SecurityHomeScreen> createState() =>
      _SecurityHomeScreenState();
}

class _SecurityHomeScreenState
    extends State<SecurityHomeScreen> {

  // ==========================================================
  // SELECTED TAB
  // ==========================================================

  int selectedIndex = 0;

  // ==========================================================
  // PAGES
  //
  // 0 = Home
  // 1 = Scan QR
  // 2 = Manual Entry
  // ==========================================================

  final List<Widget> pages = [
    const HomeTab(),
    const ScanQRScreen(),
    const ManualEntryScreen(),
  ];

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.clear();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        "LOGOUT ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Logout failed: $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // TAB CHANGE
  // ==========================================================

  void onTabChanged(
    int index,
  ) {
    // Safety check
    if (index < 0 ||
        index >= pages.length) {
      debugPrint(
        "Invalid tab index: $index",
      );
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF1F5F9),

      // ======================================================
      // BODY
      // ======================================================

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex:
            selectedIndex,

        type:
            BottomNavigationBarType.fixed,

        selectedItemColor:
            const Color(0xff12386B),

        unselectedItemColor:
            Colors.grey,

        backgroundColor:
            Colors.white,

        elevation:
            10,

        onTap:
            onTabChanged,

        items: const [

          // ==================================================
          // HOME
          // ==================================================

          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_rounded,
            ),
            activeIcon: Icon(
              Icons.home_rounded,
            ),
            label: "Home",
          ),

          // ==================================================
          // SCAN QR
          // ==================================================

          BottomNavigationBarItem(
            icon: Icon(
              Icons.qr_code_scanner,
            ),
            activeIcon: Icon(
              Icons.qr_code_scanner,
            ),
            label: "Scan QR",
          ),

          // ==================================================
          // MANUAL ENTRY
          // ==================================================

          BottomNavigationBarItem(
            icon: Icon(
              Icons.edit_note,
            ),
            activeIcon: Icon(
              Icons.edit_note,
            ),
            label: "Manual Entry",
          ),
        ],
      ),
    );
  }
}