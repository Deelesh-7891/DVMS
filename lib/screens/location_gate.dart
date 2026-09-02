import 'package:flutter/material.dart';

import '../services/location_service.dart';
import 'location_restricted_screen.dart';
import 'splash/splash_screen.dart';

class LocationGate extends StatefulWidget {
  const LocationGate({super.key});

  @override
  State<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<LocationGate> {
  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    final bool allowed =
        await LocationService.isWithinAllowedLocation();

    if (!mounted) return;

    if (allowed) {
      // Within 500 meters
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ),
      );
    } else {
      // Outside 500 meters
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LocationRestrictedScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Checking your location...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}