import 'package:geolocator/geolocator.dart';

class LocationService {
  // =====================================================
  // REGISTERED PREMI MOTORS LOCATION
  // =====================================================

  static const double registeredLatitude = 26.8565059;
  static const double registeredLongitude = 75.8313690;

  // ONLY 100 METERS ALLOWED
  static const double allowedRadius = 100.0;

  // =====================================================
  // GET CURRENT LOCATION
  // =====================================================

  static Future<Position> getCurrentLocation() async {
    // Check GPS service
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        "Please turn ON your GPS/location service.",
      );
    }

    // Check permission
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        "Location permission denied.",
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. "
        "Please enable location permission from Settings.",
      );
    }

    // Get current GPS location
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // =====================================================
  // CHECK WITHIN 100 METERS
  // =====================================================

  static Future<bool> isWithinAllowedLocation() async {
    try {
      final Position currentPosition =
          await getCurrentLocation();

      // Current mobile location
      final double currentLatitude =
          currentPosition.latitude;

      final double currentLongitude =
          currentPosition.longitude;

      // Calculate distance in meters
      final double distance =
          Geolocator.distanceBetween(
        currentLatitude,
        currentLongitude,
        registeredLatitude,
        registeredLongitude,
      );

      print("====================================");
      print("CURRENT LATITUDE: $currentLatitude");
      print("CURRENT LONGITUDE: $currentLongitude");
      print("REGISTERED LATITUDE: $registeredLatitude");
      print("REGISTERED LONGITUDE: $registeredLongitude");
      print("DISTANCE: $distance meters");
      print("ALLOWED RADIUS: $allowedRadius meters");
      print("====================================");

      // 100 meter check
      if (distance <= allowedRadius) {
        print("LOCATION ALLOWED");
        return true;
      }

      print("LOCATION BLOCKED");
      return false;
    } catch (e) {
      print("LOCATION CHECK ERROR: $e");
      return false;
    }
  }

  // =====================================================
  // GET DISTANCE
  // =====================================================

  static Future<double?> getCurrentDistance() async {
    try {
      final Position position =
          await getCurrentLocation();

      final double distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        registeredLatitude,
        registeredLongitude,
      );

      print(
        "Current distance: $distance meters",
      );

      return distance;
    } catch (e) {
      print("DISTANCE ERROR: $e");
      return null;
    }
  }
}