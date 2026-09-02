import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:demo_vehicle_management/models/city_model.dart';

class CityService {
  // static const String citiesUrl = 'https://premerp.in/dvms/api/cities';
  static const String citiesUrl = 'http://103.168.210.85:4001/api/cities';

  static Future<List<CityModel>> getCities() async {
    try {
      final response = await http.get(
        Uri.parse(citiesUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'City API Error: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> responseData =
          jsonDecode(response.body);

      final List<dynamic> data =
          responseData['data'] ?? [];

      return data
          .map(
            (item) => CityModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to load cities: $e',
      );
    }
  }
}