import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  // static const String baseUrl = "https://premerp.in/dvms/api";
  // static const String baseUrl = "http://localhost:5000/api";
  static const String baseUrl = "http://103.168.210.85:4001/api";
  // static const String baseUrl = "https://premerp.in/dvms/api";
  // static const String baseUrl = "http://10.0.2.2:5000/api";
  // static const String baseUrl = "http://10.0.2.2:5247/api";
  // Physical device:
  // static const String baseUrl = "http://192.168.1.100:5000/api";


/*================= Login =============*/

Future<Map<String, dynamic>> login(
  String email,
  String password,
  int roleId,
  List<int> stateIds,
  List<int> cityIds,
  double? lat,
  double? lng,
) async {
  final response = await http.post(
    Uri.parse("$baseUrl/auth/app/login"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "email": email,
      "password": password,
      "roleId": roleId,
      "stateIds": stateIds,
      "cityIds": cityIds,
      "lat": lat,
      "lng": lng,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();

    // Token Save
    await prefs.setString("token", data["token"]);

    // User Details Save
    await prefs.setInt("userId", data["user"]["UserId"]);
    await prefs.setString("fullName", data["user"]["FullName"]);
    await prefs.setString("email", data["user"]["Email"]);
    await prefs.setString("rolename", data["user"]["RoleName"]);
    await prefs.setInt("roleId", data["user"]["RoleId"]);
    await prefs.setInt("branchId", data["user"]["BranchId"] ?? 0);
    // await prefs.setInt("CityName", data["user"]["CityName"]);
    // await prefs.setInt("stateId", data["user"]["stateId"]);
    // await prefs.setInt("cityId", data["user"]["cityId"]); 
    // await prefs.setInt("roleId", data["user"]["RoleId"]);



    // Login Status
    await prefs.setBool("isLoggedIn", true);

    return data;
  }

  throw Exception(
    data["error"] ??
        data["message"] ??
        "Login failed",
  );
}
// Future<Map<String, dynamic>> login(
//   String email,
//   String password,
//   int roleId,
//   List<int> stateIds,
//   List<int> cityIds,
//   double? lat,
//   double? lng,
// ) async {
//   final response = await http.post(
//     Uri.parse("$baseUrl/auth/app/login"),

//     headers: {
//       "Content-Type": "application/json",
//     },

//     body: jsonEncode({
//       "email": email,
//       "password": password,
//       "roleId": roleId,
//       "stateIds": stateIds,
//       "cityIds": cityIds,

//       // GPS Location
//       "lat": lat,
//       "lng": lng,
//     }),
//   );

//   final data = jsonDecode(response.body);

//   if (response.statusCode == 200) {
//      return jsonDecode(response.body);
//     // return data;
//   }

//   throw Exception(
//     data["error"] ??
//     data["message"] ??
//     "Login failed",
//   );
  

// }



// Future<Map<String, dynamic>> login(
//   String email,
//   String password,
//   int roleId,
//   List<int> stateIds,
//   List<int> cityIds,
//    double? lat,
//   double? lng,
// ) async {
//   final response = await http.post(
//     Uri.parse("$baseUrl/auth/login"),

//     headers: {
//       "Content-Type": "application/json",
//     },

//     body: jsonEncode({
//       "email": email,
//       "password": password,
//       "roleId": roleId,
//       "stateIds": stateIds,
//       "cityIds": cityIds,
//     }),
//   );
//   final data = jsonDecode(response.body);

//   if (response.statusCode == 200) {
//     return data;
//   }

//   throw Exception(
//     data["error"] ??
//         data["message"] ??
//         "Login failed",
//   );
// }
  // Future<Map<String, dynamic>> login(
  //     String email,
  //     String password,
  //      int roleId,
  //     ) async {

  //   final response = await http.post(
  //     Uri.parse("$baseUrl/auth/login"),
  //     headers: {
  //       "Content-Type": "application/json",
  //     },
  //     body: jsonEncode({
  //       "email": email,
  //       "password": password,
  //        "roleId": roleId, // You can change this to
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     final error = jsonDecode(
  // .body);
  //     throw Exception(error["error"] ?? "Login failed",);
  //   }
  // }

/*================= GetRoles =============*/
Future<Map<String, dynamic>> getRoles() async {
  final url = Uri.parse("$baseUrl/roles");

  print("ROLES URL: $url");

  try {
    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );

    print("ROLES STATUS: ${response.statusCode}");
    print("ROLES RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // print("ROLES DATA: $data");

      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      "Roles API failed: ${response.statusCode}\n${response.body}",
    );
  } catch (e) {
    print("ROLES ERROR: $e");
    throw Exception("Unable to load roles: $e");
  }
}


  Future<Map<String, dynamic>> getStates() async {
  final response = await http.get(
    Uri.parse("$baseUrl/states"),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
  );

  print("STATES STATUS: ${response.statusCode}");
  print("STATES RESPONSE: ${response.body}");

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  throw Exception(
    "Unable to load states: "
    "${response.statusCode}\n${response.body}",
  );
}


// Future<Map<String, dynamic>> getLocations(
//   int stateId,
// ) async {

//   final uri = Uri.parse(
//     "$baseUrl/cities",
//   ).replace(
//     queryParameters: {
//       "stateId": stateId.toString(),
//     },
//   );

 
//   final response = await http.get(
//     uri,
//     headers: {
//       "Accept": "application/json",
//       "Content-Type": "application/json",
//     },
//   );

 

//   if (response.statusCode == 200) {

//     final decoded =
//         jsonDecode(response.body);

//     if (decoded is Map<String, dynamic>) {
//       return decoded;
//     }

//     throw Exception(
//       "Invalid cities response",
//     );
//   }

//   throw Exception(
//     "Unable to load locations: "
//     "${response.statusCode} "
//     "${response.body}",
//   );
// }



//  Future<Map<String, dynamic>> getLocations(
//   int stateId,
// ) async {

//   final uri = Uri.parse(
//     "$baseUrl/cities",
//   ).replace(
//     queryParameters: {
//       "stateId": stateId.toString(),
//     },
//   );

//   final response =
//       await http.get(uri);

 
//   if (response.statusCode == 200) {

//     final decoded =
//         jsonDecode(response.body);

//     if (decoded is Map<String, dynamic>) {
//       return decoded;
//     }

//     throw Exception(
//       "Invalid locations response",
//     );
//   }

//   throw Exception(
//     "Unable to load locations: "
//     "${response.statusCode}",
//   );
// }

Future<Map<String, dynamic>> getLocations(
  int stateId,
) async {
  final uri = Uri.parse(
    "$baseUrl/cities",
  ).replace(
    queryParameters: {
      "stateId": stateId.toString(),
    },
  );

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    "Unable to load locations: ${response.statusCode}",
  );
}



/*================= DashboardSummary =============*/

  Future<Map<String, dynamic>> DashboardSummary() async 
  {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard/summary"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

    return json["data"];

    } else {
      throw Exception(response.body);
    }
  }

/*================= DashboardCompliance =============*/


 Future<Map<String, dynamic>> dashboardCompliance() async 
 {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard/compliance"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

/*================= Expenses =============*/

 Future<Map<String, dynamic>> expenses() async
 {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/expenses"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

/*================= GetVehicles =============*/

Future<List<dynamic>> getVehicles() async
 {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/vehicles"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
   
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List) return json;
      return json["data"] as List<dynamic>;
    } else {
      throw Exception(response.body);
    }
  }

/*================= SaveFuel =============*/

  Future<void> saveFuel(
  {
    required int vehicleId,
    required String txnDate,
    required String fuelStation,
    required double amount,
    required int odometer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("$baseUrl/fuel"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "VehicleId": vehicleId,
        "TxnDate": txnDate,
        "FuelStation": fuelStation,
        "Amount": amount,
        "Odometer": odometer,
      }),
    );

    print("Request Body:");
    print(jsonEncode({
      "VehicleId": vehicleId,
      "TxnDate": txnDate,
      "FuelStation": fuelStation,
      "Amount": amount,
      "Odometer": odometer,
    }));

    print("Response: ${response.body}");

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

/*================= UploadAttachment =============*/
// Uploads a photo (e.g. the odometer photo captured before saving a
// movement) via POST /attachments and returns the "url" the server
// hands back — pass that straight into movementSave's imagePath.
Future<String> uploadAttachment({
  required Uint8List bytes,
  required String fileName,
  String entityType = 'Movement',
}) async {
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('token');

  if (authToken == null || authToken.isEmpty) {
    throw Exception('Authorization token not found. Please login again.');
  }

  // Dart's http package defaults a multipart file part's Content-Type to
  // application/octet-stream unless told otherwise — and the server's
  // Multer fileFilter (dvms.js) only allows image/jpeg, image/png,
  // image/webp, or application/pdf, so an unset content type was always
  // rejected with a 500 regardless of what the file actually was.
  // image_picker's camera capture always produces a JPEG here.
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/attachments'),
  )
    ..headers['Authorization'] = 'Bearer $authToken'
    ..fields['entityType'] = entityType
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  print('ATTACHMENT UPLOAD STATUS: ${response.statusCode}');
  print('ATTACHMENT UPLOAD RESPONSE: ${response.body}');

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(
      'Attachment upload failed: ${response.statusCode} ${response.body}',
    );
  }

  final data = jsonDecode(response.body);
  final url = data['url']?.toString();

  if (url == null || url.isEmpty) {
    throw Exception('Attachment upload succeeded but no url was returned.');
  }

  return url;
}

Future<void> movementSave({
  required int branchId,
  required int vehicleId,
  required String qrToken,
  required String direction,
  required String txnDate,
  // Location optional
  String? fromLocation,
  int? fromCityId,
  String? toLocation,
  int? toCityId,

  required int odometer,
  required String driverName,
  required String movementType,
  required String salesExecutive,
  required String customerName,
  required String purpose,
  // Path returned by uploadAttachment() — persisted as VehicleMovement.ImagePath.
  String? imagePath,
}) async {
  // ==========================================================
  // GET SHARED PREFERENCES
  // ==========================================================

  final prefs = await SharedPreferences.getInstance();

  // ==========================================================
  // GET AUTH TOKEN
  // ==========================================================

  final authToken = prefs.getString('token');

  if (authToken == null || authToken.isEmpty) {
    throw Exception(
      'Authorization token not found. Please login again.',
    );
  }

  // ==========================================================
  // GET LOGIN LOCATION
  // ==========================================================

  final lat = prefs.getString('GeoLat');
  final lng = prefs.getString('GeoLng');

  // ==========================================================
  // "OTHER" LOCATION (for Security logins)
  // ==========================================================
  // The backend pins ONE side of a Security user's movement to their own
  // gate location (from their profile) and only reads the other side —
  // as a numeric CityId, in a field called exactly "otherCityId" — from
  // the request. On Exit the vehicle is heading TO the picked location;
  // on Entry it's coming FROM the picked location.
  final int? otherCityId = direction == 'Entry' ? fromCityId : toCityId;

  // ==========================================================
  // REQUEST BODY
  // ==========================================================

  final Map<String, dynamic> body = {
    'branchId': branchId,
    'vehicleId': vehicleId,
    'qrToken': qrToken,
    'direction': direction,
    'txnDate': txnDate,

    // Optional location — fromCityId/toCityId are read directly for
    // non-Security (admin) logins; otherCityId is what a Security login
    // actually needs (see comment above). Sending both is harmless.
    'fromLocation': fromLocation,
    'fromCityId': fromCityId,
    'toLocation': toLocation,
    'toCityId': toCityId,
    'otherCityId': otherCityId,
    'odometer': odometer,
    'driverName': driverName,
    'movementType': movementType,
    
    'salesExecutive': salesExecutive,
    'customerName': customerName,
    'purpose': purpose,
    'imagePath': imagePath,

    // Login GPS location
    'latitude': lat,
    'longitude': lng,
  };

  // ==========================================================
  // PRINT REQUEST
  // ==========================================================

  print('');
  print('======================================');
  print('MOVEMENT REQUEST BODY');
  print('======================================');
  print(jsonEncode(body));
  print('======================================');

  // ==========================================================
  // API CALL
  // ==========================================================

  final response = await http.post(
    Uri.parse('$baseUrl/movement/scan'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode(body),
  );

  // ==========================================================
  // PRINT RESPONSE
  // ==========================================================

  print('');
  print('======================================');
  print('MOVEMENT API RESPONSE');
  print('======================================');
  print('STATUS CODE: ${response.statusCode}');
  print('RESPONSE: ${response.body}');
  print('======================================');

  // ==========================================================
  // SUCCESS
  // ==========================================================

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    print('MOVEMENT SAVE SUCCESS');
    return;
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  print('======================================');
  print('MOVEMENT SAVE ERROR');
  print('======================================');

  throw Exception(
    'Movement API failed: '
    '${response.statusCode} '
    '${response.body}',
  );
}









// Future<void> movementSave({
//   required int branchId,
//   required int vehicleId,
//   required String qrToken,
//   required String direction,
//   required String txnDate,
//   required String fromLocation,
//   required int? fromCityId,
//   required String toLocation, 
//   required int? toCityId,
//   required int odometer,
//   required String driverName,
//   required String movementType,
//   required String salesExecutive,
//   required String customerName,
//   required String purpose,
// }) async {

//   // ==========================================================
//   // TOKEN
//   // ==========================================================

//   final prefs = await SharedPreferences.getInstance();

//   final authToken = prefs.getString('token');


//   // ==========================================================
//   // LOGIN LOCATION
//   // ==========================================================

//   final lat = prefs.getString('GeoLat');
//   final lng =  prefs.getString('GeoLng');


//   // ==========================================================
//   // TOKEN CHECK
//   // ==========================================================

//   if (authToken == null ||
//       authToken.isEmpty) {

//     throw Exception(
//       'Authorization token not found. Please login again.',
//     );
//   }


//   // ==========================================================
//   // LOGIN LOCATION CHECK
//   // ==========================================================

//   if (lat == null ||
//       lat.isEmpty ||
//       lng == null ||
//       lng.isEmpty) {

//     throw Exception(
//       'Login location not found. Please login again.',
//     );
//   }


//   // ==========================================================
//   // REQUEST BODY
//   // ==========================================================

//   final Map<String, dynamic> body = {
//     'branchId': branchId,
//     'vehicleId':  vehicleId,
//     'qrToken': qrToken,
//     'direction': direction,
//     'txnDate': txnDate,
//     'fromLocation': fromLocation,
//     'fromCityId': fromCityId,
//     'toLocation': toLocation,
//     'toCityId': 42,
//     'odometer': odometer,
//     'driverName': driverName,
//     'movementType': movementType,
//     'salesExecutive': salesExecutive,
//     'customerName': customerName,
//     'purpose': purpose,
//     'lat': lat,
//     'lng': lng,
//   };

//   print(
//     '======================================',
//   );

//   print(
//     'MOVEMENT REQUEST BODY',
//   );

//   print(
//     jsonEncode(body),
//   );

//   print(
//     '======================================',
//   );


//   // ==========================================================
//   // API CALL
//   // ==========================================================

//   final response = await http.post(

//     Uri.parse(
//       '$baseUrl/movement/scan',
//     ),

//     headers: {

//       'Content-Type':
//           'application/json',

//       'Authorization':
//           'Bearer $authToken',
//     },

//     body:
//         jsonEncode(body),
//   );

//   print(
//     '======================================',
//   );

//   print(
//     'MOVEMENT API RESPONSE',
//   );

//   print(
//     'STATUS CODE: '
//     '${response.statusCode}',
//   );

//   print(
//     'RESPONSE: '
//     '${response.body}',
//   );

//   print(
//     '======================================',
//   );


//   if (
//     response.statusCode >= 200 &&
//     response.statusCode < 300
//   ) {

//     return;
//   }


//   throw Exception(
//     'Movement API failed: '
//     '${response.statusCode} '
//     '${response.body}',
//   );
// }





 Future<List<dynamic>> getmovement() async
 {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/movement"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print("Response: ${response.body}");
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List) return json;
      return json["data"] as List<dynamic>;
    } else {
      throw Exception(response.body);
    }
  }

  /*================= Report Damage =============*/
 Future<void> reportDamageSave({
  required int vehicleId,
  required String txnDate,
  required String damageType,
  required String location,
  required String description,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final body = {
    "vehicleId": vehicleId,
    "txnDate": txnDate,
    "damageType": damageType,
    "location": location,
    "description": description,
  };

  print("Request Body: ${jsonEncode(body)}");

  final response = await http.post(
    Uri.parse("$baseUrl/accidents"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  print("Status Code: ${response.statusCode}");
  print("Response: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    return;
  } else {
    throw Exception(response.body);
  }
}
  
  
  Future<Map<String, dynamic>> getVehicleByQRToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  // Get login JWT token
  final authToken = prefs.getString('token');
  final CityName = prefs.getString('CityName');

  if (authToken == null || authToken.isEmpty) {
    throw Exception('Login token not found. Please login again.');
  }

  final response = await http.get(
    Uri.parse(
      '$baseUrl/vehicle/get-by-qr-token?token=${Uri.encodeComponent(token)}',
    ),
    headers: {
      'Authorization': 'Bearer $authToken',
      'Accept': 'application/json',
    },
  );
  print('Vehicle API Status: ${response.statusCode}');
  print('Vehicle API Response: ${response.body}');
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception(
    'Vehicle API failed: ${response.statusCode} ${response.body}',
  );
}




Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString("token");
  final loggedIn = prefs.getBool("isLoggedIn") ?? false;

  return loggedIn &&
      token != null &&
      token.isNotEmpty;
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}


Future<Position> getCurrentLocation() async {
  bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw Exception(
      "Please turn on GPS/location service",
    );
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission =
        await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw Exception(
      "Location permission denied",
    );
  }

  if (permission ==
      LocationPermission.deniedForever) {
    throw Exception(
      "Location permission permanently denied. "
      "Please enable it from App Settings.",
    );
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}


 Future<List<dynamic>> getAccidents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      throw Exception(
        "Authorization token not found. Please login again.",
      );
    }

    final response = await http.get(
      Uri.parse("$baseUrl/accidents"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print(
      "ACCIDENT LIST STATUS: ${response.statusCode}",
    );
    print(
      "ACCIDENT LIST RESPONSE: ${response.body}",
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json is List) {
        return json;
      }

      if (json["data"] is List) {
        return List<dynamic>.from(json["data"]);
      }

      return [];
    }

    throw Exception(
      "Accident list failed: "
      "${response.statusCode} ${response.body}",
    );
  }

   
  Future<Map<String, dynamic>> uploadAccidentAttachment({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      throw Exception(
        "Authorization token not found. Please login again.",
      );
    }

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/attachments"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["entityType"] = "Accident";

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: fileName,
      ),
    );

    print("======================================");
    print("ACCIDENT ATTACHMENT UPLOAD");
    print("URL: $baseUrl/attachments");
    print("FILE: $fileName");
    print("SIZE: ${bytes.length}");
    print("======================================");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    print(
      "ATTACHMENT STATUS: ${response.statusCode}",
    );
    print(
      "ATTACHMENT RESPONSE: ${response.body}",
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      "Attachment upload failed: "
      "${response.statusCode} ${response.body}",
    );
  }

  Future<Map<String, dynamic>> saveAccident({
    required int vehicleId,
    required String capturedAt,
    required String description,
    int? attachmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      throw Exception(
        "Authorization token not found. Please login again.",
      );
    }

    final body = {
      "VehicleId": vehicleId,
      "CapturedAt": capturedAt,
      "Description": description,
      "AttachmentId": 1,
    };

    print("======================================");
    print("ACCIDENT SAVE API");
    print("URL: $baseUrl/accidents");
    print("REQUEST BODY: ${jsonEncode(body)}");
    print("======================================");

    final response = await http.post(
      Uri.parse("$baseUrl/accidents"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("ACCIDENT STATUS: ${response.statusCode}");
    print("ACCIDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      "Accident API failed: "
      "${response.statusCode} ${response.body}",
    );
  }


}