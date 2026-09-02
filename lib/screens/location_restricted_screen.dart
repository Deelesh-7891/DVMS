import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationRestrictedScreen extends StatefulWidget {
  const LocationRestrictedScreen({super.key});

  @override
  State<LocationRestrictedScreen> createState() =>
      _LocationRestrictedScreenState();
}

class _LocationRestrictedScreenState
    extends State<LocationRestrictedScreen> {

  bool checking = false;

  Future<void> checkAgain() async {
    setState(() {
      checking = true;
    });

    final bool allowed =
        await LocationService.isWithinAllowedLocation();

    if (!mounted) return;

    setState(() {
      checking = false;
    });

    if (allowed) {
      Navigator.pushReplacementNamed(
        context,
        '/splash',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 80,
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Location Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'You are outside the allowed location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'This application can only be used '
                  'within 500 meters of the registered location.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: checking ? null : checkAgain,
                  child: checking
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Check Location Again',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}