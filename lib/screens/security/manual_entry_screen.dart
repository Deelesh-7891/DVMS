import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class CityModel {
  final int cityId;
  final int stateId;
  final String cityName;
  final String locationName;
  final String locationType;
  final String pinCode;

  CityModel({
    required this.cityId,
    required this.stateId,
    required this.cityName,
    required this.locationName,
    required this.locationType,
    required this.pinCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: int.tryParse(json['CityId']?.toString() ?? '') ?? 0,
      stateId: int.tryParse(json['StateId']?.toString() ?? '') ?? 0,
      cityName: json['CityName']?.toString() ?? '',
      locationName: json['LocationName']?.toString() ?? '',
      locationType: json['LocationType']?.toString() ?? '',
      pinCode: json['PinCode']?.toString() ?? '',
    );
  }
}

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({
    super.key,
  });

  @override
  State<ManualEntryScreen> createState() =>
      _ManualEntryScreenState();
}

class _ManualEntryScreenState
    extends State<ManualEntryScreen> {

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController tokenController =
      TextEditingController();

  final TextEditingController odometerController =
      TextEditingController();

  final TextEditingController driverController =
      TextEditingController();

  final TextEditingController salesExecutiveController =
      TextEditingController();

  final TextEditingController customerNameController =
      TextEditingController();

  final TextEditingController purposeController =
      TextEditingController();

  final TextEditingController fromLocationController =
      TextEditingController();

  final TextEditingController toLocationController =
      TextEditingController();

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker _imagePicker =
      ImagePicker();

  // Original selected/captured image
  XFile? odometerImage;

  // Image bytes - works on Android + Web
  Uint8List? odometerImageBytes;

  // ============================================================
  // SERVICE
  // ============================================================

  final AuthService _authService = AuthService();

  // ============================================================
  // MOVEMENT
  // ============================================================

  String direction = "Entry";

  String? selectedMovementType;

  final List<String> movementTypes = [
    "Demo",
    "TestDrive",
    "Service",
    "Workshop",
    "InterBranch",
  ];

  // ============================================================
  // LOADING
  // ============================================================

  bool isSaving = false;

  // ============================================================
  // LOGIN / CITY / LOCATION DATA
  // ============================================================

  String gateCityName = '';
  int stateId = 0;

  List<CityModel> allCities = [];
  bool isLoadingCities = false;

  int? fromCityId;
  int? toCityId;

  String? fromCityName;
  String? toCityName;

  Map<String, dynamic>? selectedFromLocation;
  Map<String, dynamic>? selectedToLocation;

  @override
  void initState() {
    super.initState();
    loadLoginData();
    loadCities();
  }

  // ============================================================
  // LOAD LOGIN DATA
  // ============================================================

  Future<void> loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();

    String cityName = prefs.getString('cityName') ?? '';
    if (cityName.trim().isEmpty) {
      cityName = prefs.getString('CityName') ?? '';
    }

    int savedStateId = prefs.getInt('stateId') ?? 0;
    if (savedStateId == 0) {
      savedStateId = prefs.getInt('StateId') ?? 0;
    }

    if (!mounted) return;

    setState(() {
      gateCityName = cityName.trim();
      stateId = savedStateId;

    });

    debugPrint('LOGIN CITY: $gateCityName');
    debugPrint('STATE ID: $stateId');

    // If cities have already loaded, immediately apply the gate location
    // to the correct side for the current direction.
    if (allCities.isNotEmpty) {
      applyDirectionLocation();
    }
  }

  // ============================================================
  // APPLY LOGIN / GATE LOCATION BASED ON DIRECTION
  // ============================================================

  void applyDirectionLocation() {
    if (gateCityName.trim().isEmpty || allCities.isEmpty) {
      return;
    }

    final String gate = gateCityName.trim().toLowerCase();

    CityModel? gateLocation;

    for (final city in allCities) {
      if (city.cityName.trim().toLowerCase() == gate ||
          city.locationName.trim().toLowerCase() == gate) {
        gateLocation = city;
        break;
      }
    }

    if (gateLocation == null) {
      debugPrint('GATE LOCATION NOT FOUND IN CITIES API: $gateCityName');
      return;
    }

    final Map<String, dynamic> location = {
      'CityId': gateLocation.cityId,
      'StateId': gateLocation.stateId,
      'CityName': gateLocation.cityName,
      'LocationName': gateLocation.locationName,
      'LocationType': gateLocation.locationType,
      'PinCode': gateLocation.pinCode,
    };

    final String displayName = gateLocation.locationName.isNotEmpty
        ? gateLocation.locationName
        : gateLocation.cityName;

    setState(() {
      if (direction == 'Entry') {
        // ENTRY: To = Login/Gate, From = User destination
        toCityId = gateLocation!.cityId;
        toCityName = gateLocation.cityName;
        selectedToLocation = location;
        toLocationController.text = displayName;

        fromCityId = null;
        fromCityName = null;
        selectedFromLocation = null;
        fromLocationController.clear();
      } else {
        // EXIT: From = Login/Gate, To = User destination
        fromCityId = gateLocation!.cityId;
        fromCityName = gateLocation.cityName;
        selectedFromLocation = location;
        fromLocationController.text = displayName;

        toCityId = null;
        toCityName = null;
        selectedToLocation = null;
        toLocationController.clear();
      }
    });

    debugPrint('DIRECTION: $direction');
    debugPrint('GATE LOCATION: $displayName');
    debugPrint('GATE CITY ID: ${gateLocation.cityId}');
  }

  // ============================================================
  // LOAD LOCATIONS / CITIES
  // ============================================================

  Future<void> loadCities() async {
    if (mounted) {
      setState(() {
        isLoadingCities = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://103.168.210.85:4001/api/cities'),
        headers: const {
          'Accept': 'application/json',
        },
      );

      debugPrint('CITIES API STATUS: \${response.statusCode}');
      debugPrint('CITIES API RESPONSE: \${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Cities API failed: \${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid cities API response');
      }

      final rawData = decoded['data'];

      if (rawData is! List) {
        throw Exception('City data not found');
      }

      final result = rawData
          .where((item) => item is Map)
          .map((item) => CityModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((city) => city.cityId > 0)
          .toList();

      if (!mounted) return;

      setState(() {
        allCities = result;
        isLoadingCities = false;
      });

      // Resolve login/gate location to CityId.
      if (gateCityName.isNotEmpty) {
        final defaultCity = allCities.cast<CityModel?>().firstWhere(
          (city) =>
              city!.cityName.trim().toLowerCase() ==
                  gateCityName.trim().toLowerCase() ||
              city.locationName.trim().toLowerCase() ==
                  gateCityName.trim().toLowerCase(),
          orElse: () => null,
        );

        if (defaultCity != null && mounted) {
          // Keep the gate location on the correct side only when
          // the selected movement type requires locations.
          if (isLocationRequired()) {
            applyDirectionLocation();
          }
        }
      }

      debugPrint('TOTAL LOCATIONS: \${allCities.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCities = false;
      });

      debugPrint('CITIES API ERROR: $e');
      showError('Unable to load locations');
    }
  }

  // ============================================================
  // SEARCH LOCATIONS
  // ============================================================

  List<Map<String, dynamic>> searchLocations(String query) {
    final search = query.trim().toLowerCase();

    Iterable<CityModel> source = allCities;

    if (search.isNotEmpty) {
      source = source.where((city) {
        return city.cityName.toLowerCase().contains(search) ||
            city.locationName.toLowerCase().contains(search) ||
            city.locationType.toLowerCase().contains(search) ||
            city.pinCode.toLowerCase().contains(search) ||
            city.cityId.toString().contains(search);
      });
    }

    return source.take(20).map((city) {
      return <String, dynamic>{
        'CityId': city.cityId,
        'StateId': city.stateId,
        'CityName': city.cityName,
        'LocationName': city.locationName,
        'LocationType': city.locationType,
        'PinCode': city.pinCode,
      };
    }).toList();
  }

  // ============================================================
  // LOCATION SEARCH FIELD
  // ============================================================

  Widget locationSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<Map<String, dynamic>> onSelected,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (location) =>
          location['CityName']?.toString() ??
          location['LocationName']?.toString() ??
          '',

      optionsBuilder: (value) {
        return searchLocations(value.text);
      },

      onSelected: onSelected,

      fieldViewBuilder: (
        context,
        fieldController,
        focusNode,
        onFieldSubmitted,
      ) {
        if (fieldController.text != controller.text) {
          fieldController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(
              offset: controller.text.length,
            ),
          );
        }

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,

          onChanged: (value) {
            // If the user changes the selected text manually,
            // invalidate the previous CityId/selection.
            if (controller == fromLocationController) {
              if (selectedFromLocation?['LocationName']?.toString() != value &&
                  selectedFromLocation?['CityName']?.toString() != value) {
                fromCityId = null;
                fromCityName = null;
                selectedFromLocation = null;
              }
            }

            if (controller == toLocationController) {
              if (selectedToLocation?['LocationName']?.toString() != value &&
                  selectedToLocation?['CityName']?.toString() != value) {
                toCityId = null;
                toCityName = null;
                selectedToLocation = null;
              }
            }

            controller.value = fieldController.value;
          },

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isLoadingCities
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xff2757B0),
                width: 2,
              ),
            ),
          ),
        );
      },

      optionsViewBuilder: (
        context,
        onSelected,
        options,
      ) {
        final optionList = options.toList();

        if (optionList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 36,
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final location = optionList[index];

                  final locationName =
                      location['LocationName']?.toString() ?? '';
                  final cityName =
                      location['CityName']?.toString() ?? '';
                  final cityId =
                      location['CityId']?.toString() ?? '';
                  final locationType =
                      location['LocationType']?.toString() ?? '';
                  final pinCode =
                      location['PinCode']?.toString() ?? '';

                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xff2458A6),
                    ),
                    title: Text(
                      locationName.isNotEmpty
                          ? locationName
                          : cityName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (cityName.isNotEmpty) cityName,
                        // if (cityId.isNotEmpty) 'CityId: $cityId',
                        if (locationType.isNotEmpty) locationType,
                        // if (pinCode.isNotEmpty) 'PIN: $pinCode',
                      ].join(' • '),
                    ),
                    onTap: () => onSelected(location),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OPEN ODOMETER CAMERA
  // ============================================================

  Future<void> openOdometerCamera() async {
    try {
      debugPrint(
        "======================================",
      );

      debugPrint(
        "OPEN ODOMETER CAMERA",
      );

      debugPrint(
        "======================================",
      );

      final XFile? image =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      // --------------------------------------------------------
      // USER CANCELLED CAMERA
      // --------------------------------------------------------

      if (image == null) {
        debugPrint(
          "CAMERA CANCELLED",
        );

        return;
      }

      // --------------------------------------------------------
      // READ IMAGE BYTES
      // --------------------------------------------------------

      final Uint8List bytes =
          await image.readAsBytes();

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SAVE IMAGE
      // --------------------------------------------------------

      setState(() {
        odometerImage = image;
        odometerImageBytes = bytes;
      });

      debugPrint(
        "======================================",
      );

      debugPrint(
        "ODOMETER IMAGE CAPTURED",
      );

      debugPrint(
        "IMAGE PATH: ${image.path}",
      );

      debugPrint(
        "IMAGE BYTES: ${bytes.length}",
      );

      debugPrint(
        "ODOMETER: "
        "${odometerController.text.trim()}",
      );

      debugPrint(
        "======================================",
      );

    } catch (e) {

      debugPrint(
        "ODOMETER CAMERA ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      showError(
        "Unable to open camera: $e",
      );
    }
  }

  // ============================================================
  // RETAKE IMAGE
  // ============================================================

  Future<void> retakeOdometerImage() async {
    await openOdometerCamera();
  }

  // ============================================================
  // LOCATION REQUIRED
  // Service / Workshop / InterBranch
  // ============================================================

  bool isLocationRequired() {
    // Demo / TestDrive = NO movement locations.
    // Service / Workshop / InterBranch = movement locations required.
    return selectedMovementType == "Service" ||
        selectedMovementType == "Workshop" ||
        selectedMovementType == "InterBranch";
  }

  // ============================================================
  // VALIDATE FORM
  // ============================================================

  bool validateForm() {

    // ==========================================================
    // QR TOKEN
    // ==========================================================

    if (tokenController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter QR Token",
      );

      return false;
    }

    // ==========================================================
    // ODOMETER
    // ==========================================================

    final String odometerText =
        odometerController.text
            .trim()
            .replaceAll(",", "");

    if (odometerText.isEmpty) {

      showError(
        "Enter Odometer",
      );

      return false;
    }

    final int? odometer =
        int.tryParse(
      odometerText,
    );

    if (odometer == null) {

      showError(
        "Enter valid Odometer",
      );

      return false;
    }

    if (odometer < 0) {

      showError(
        "Odometer cannot be negative",
      );

      return false;
    }

    // ==========================================================
    // ODOMETER IMAGE
    // ==========================================================

    // if (odometerImageBytes == null) {

    //   showError(
    //     "Please take Odometer Image",
    //   );

    //   return false;
    // }

    // ==========================================================
    // DRIVER
    // ==========================================================

    if (driverController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Driver Name",
      );

      return false;
    }

    // ==========================================================
    // MOVEMENT TYPE
    // ==========================================================

    if (selectedMovementType == null ||
        selectedMovementType!
            .trim()
            .isEmpty) {

      showError(
        "Select Movement Type",
      );

      return false;
    }

    // ==========================================================
    // SALES EXECUTIVE
    // ==========================================================

    if (salesExecutiveController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Sales Executive",
      );

      return false;
    }

    // ==========================================================
    // CUSTOMER
    // ==========================================================

    if (customerNameController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Customer Name",
      );

      return false;
    }

    // ==========================================================
    // PURPOSE
    // ==========================================================

    if (purposeController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Purpose",
      );

      return false;
    }

    // ==========================================================
    // FROM / TO LOCATION
    // Demo / TestDrive = hidden, not required
    // Service / Workshop / InterBranch = required
    // ==========================================================

    if (isLocationRequired()) {

      if (direction == 'Entry') {
        // ENTRY:
        // To   = Login/Gate location -> REQUIRED
        // From = User selected destination -> OPTIONAL

        if (toLocationController.text.trim().isEmpty) {
          showError('Login / Gate Location not found');
          return false;
        }

        if (toCityId == null || toCityId == 0) {
          showError('Login / Gate City not found');
          return false;
        }

        // From is OPTIONAL.
        // If user entered/selected it, CityId must be valid.
        if (fromLocationController.text.trim().isNotEmpty &&
            (fromCityId == null || fromCityId == 0)) {
          showError('Select From Location from the list');
          return false;
        }
      } else {
        // EXIT:
        // From = Login/Gate location -> REQUIRED
        // To   = User selected destination -> OPTIONAL

        if (fromLocationController.text.trim().isEmpty) {
          showError('Login / Gate Location not found');
          return false;
        }

        if (fromCityId == null || fromCityId == 0) {
          showError('Login / Gate City not found');
          return false;
        }

        // To is OPTIONAL.
        // If user entered/selected it, CityId must be valid.
        if (toLocationController.text.trim().isNotEmpty &&
            (toCityId == null || toCityId == 0)) {
          showError('Select To Location from the list');
          return false;
        }
      }

      debugPrint('VALID FROM CITY ID: $fromCityId');
      debugPrint('VALID TO CITY ID: $toCityId');
    }

    return true;
  }

  // ============================================================
  // SAVE MOVEMENT
  // ============================================================

  Future<void> saveMovement() async {

    if (isSaving) {
      return;
    }

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (!validateForm()) {
      return;
    }

    try {

      setState(() {
        isSaving = true;
      });

      // ========================================================
      // SHARED PREFERENCES
      // ========================================================

      final SharedPreferences prefs = await SharedPreferences .getInstance();

      // ========================================================
      // BRANCH ID
      // ========================================================

      // final int branchId = prefs.getInt( "BranchId", ) ?? 0;


    final int branchId =  prefs.getInt('BranchId') ?? 1;
      if (branchId == 0) {

        throw Exception(
          "BranchId not found. Please login again.",
        );
      }

      // ========================================================
      // USER ID
      // ========================================================

      final int? userId =
          prefs.getInt(
        "UserId",
      );

      // ========================================================
      // QR TOKEN
      // ========================================================

      final String qrToken =
          tokenController.text.trim();

      // ========================================================
      // DRIVER
      // ========================================================

      final String driverName =
          driverController.text.trim();

      // ========================================================
      // SALES EXECUTIVE
      // ========================================================

      final String salesExecutive =
          salesExecutiveController
              .text
              .trim();

      // ========================================================
      // CUSTOMER
      // ========================================================

      final String customerName =
          customerNameController
              .text
              .trim();

      // ========================================================
      // LOCATION
      //
      // Keeping your existing structure.
      // ========================================================

      final String fromLocation =
          fromLocationController
              .text
              .trim();

      final String toLocation =
          toLocationController
              .text
              .trim();

      // ========================================================
      // PURPOSE
      // ========================================================

      final String purpose =
          purposeController
              .text
              .trim();

      // ========================================================
      // MOVEMENT TYPE
      // ========================================================

      final String movementType =
          selectedMovementType ?? "";

      // ========================================================
      // ODOMETER
      // ========================================================

      final int? odometer =
          int.tryParse(
        odometerController.text
            .trim()
            .replaceAll(
              ",",
              "",
            ),
      );

      if (odometer == null) {

        throw Exception(
          "Invalid Odometer",
        );
      }

      // ========================================================
      // DEBUG
      // ========================================================

      print(
        "======================================",
      );

      print(
        "MANUAL MOVEMENT SAVE",
      );

      print(
        "======================================",
      );

      print(
        "UserId          : $userId",
      );

      print(
        "BranchId        : $branchId",
      );

      print(
        "VehicleId       : 1",
      );

      print(
        "QR Token        : $qrToken",
      );

      print(
        "Direction       : $direction",
      );

      print(
        "Odometer        : $odometer",
      );

      print(
        "Odometer Image  : "
        "${odometerImage?.path}",
      );

      print(
        "Image Bytes     : "
        "${odometerImageBytes?.length}",
      );

      print(
        "Driver Name     : $driverName",
      );

      print(
        "Movement Type   : $movementType",
      );

      print(
        "Sales Executive : $salesExecutive",
      );

      print(
        "Customer Name   : $customerName",
      );

      print(
        "From Location   : $fromLocation",
      );

      print(
        "To Location     : $toLocation",
      );

      print(
        "Purpose         : $purpose",
      );

      print(
        "======================================",
      );

      // ========================================================
      // API CALL
      // ========================================================

      await _authService.movementSave(

        branchId:
            branchId,

        vehicleId:
            1,

        qrToken:
            qrToken,

        txnDate:
            DateTime.now()
                .toIso8601String(),

        direction:
            direction,

        odometer:
            odometer,

        driverName:
            driverName,

        movementType:
            movementType,

        salesExecutive:
            salesExecutive,

        customerName:
            customerName,

        fromLocation:
            selectedFromLocation?['LocationName']?.toString() ??
                fromLocation,

        fromCityId:
            fromCityId,

        toLocation:
            selectedToLocation?['LocationName']?.toString() ??
                toLocation,

        toCityId:
            toCityId,

        purpose:
            purpose,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            "Movement Saved Successfully",
          ),

          backgroundColor:
              Colors.green,

          duration:
              Duration(
            seconds: 2,
          ),
        ),
      );

      // ========================================================
      // CLEAR FORM
      // ========================================================

      tokenController.clear();

      odometerController.clear();

      driverController.clear();

      salesExecutiveController.clear();

      customerNameController.clear();

      purposeController.clear();

      fromLocationController.clear();

      toLocationController.clear();

      setState(() {

        fromCityId = null;
        toCityId = null;
        fromCityName = null;
        toCityName = null;
        selectedFromLocation = null;
        selectedToLocation = null;

        odometerImage =
            null;

        odometerImageBytes =
            null;

        direction =
            "Entry";

        selectedMovementType =
            null;
      });

      // Default is Entry, but Demo is selected only after user chooses
      // a movement type. Do not force a hidden location here.
      if (isLocationRequired()) {
        applyDirectionLocation();
      }

    } catch (e) {

      if (!mounted) {
        return;
      }

      print(
        "======================================",
      );

      print(
        "MOVEMENT SAVE ERROR",
      );

      print(
        "$e",
      );

      print(
        "======================================",
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            "Movement Save Error: $e",
          ),

          backgroundColor:
              Colors.red,
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void showError(
    String message,
  ) {

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            Colors.red,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {

    tokenController.dispose();

    odometerController.dispose();

    driverController.dispose();

    salesExecutiveController.dispose();

    customerNameController.dispose();

    purposeController.dispose();

    fromLocationController.dispose();

    toLocationController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xffEEF2F7),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar:
          AppBar(

        backgroundColor:
            const Color(0xff12386B),

        elevation:
            0,

        foregroundColor:
            Colors.white,

        title:
            const Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              "📝 Manual Entry",

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,

                fontSize:
                    22,
              ),
            ),

            SizedBox(
              height: 4,
            ),

            Text(
              "When the camera can't read the sticker",

              style:
                  TextStyle(
                fontSize:
                    14,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Card(

          elevation:
              3,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              18,
            ),

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // QR TOKEN
                // ==================================================

                buildTitle(
                  "Vehicle QR Token",
                ),

                const SizedBox(
                  height: 8,
                ),

                buildField(
                  controller: tokenController,

                  hint: "Please enter QR token",

                  icon: Icons.qr_code,
                  capitalize: false,
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // DIRECTION
                // ==================================================

                buildTitle(
                  "Direction",
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [

                    Expanded(
                      child:
                          ChoiceChip(

                        label:
                            const Text(
                          "Entry",
                        ),

                        selected:
                            direction ==
                                "Entry",

                        selectedColor:
                            Colors.green,

                        labelStyle:
                            TextStyle(

                          color:
                              direction ==
                                      "Entry"
                                  ? Colors.white
                                  : Colors.black,

                          fontWeight:
                              FontWeight.w600,
                        ),

                        onSelected: (_) {
                          setState(() {
                            direction = "Entry";
                          });

                          // Apply gate location only for movement types
                          // that require Movement Locations.
                          if (isLocationRequired()) {
                            applyDirectionLocation();
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          ChoiceChip(

                        label:
                            const Text(
                          "Exit",
                        ),

                        selected:
                            direction ==
                                "Exit",

                        selectedColor:
                            Colors.orange,

                        labelStyle:
                            TextStyle(

                          color:
                              direction ==
                                      "Exit"
                                  ? Colors.white
                                  : Colors.black,

                          fontWeight:
                              FontWeight.w600,
                        ),

                        onSelected: (_) {
                          setState(() {
                            direction = "Exit";
                          });

                          // Apply gate location only for movement types
                          // that require Movement Locations.
                          if (isLocationRequired()) {
                            applyDirectionLocation();
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // ODOMETER + DRIVER
                // ==================================================

                // ==================================================
                // ODOMETER
                // ==================================================

                buildTitle("Odometer (km)"),

                const SizedBox(height: 8),

                TextField(
                  controller: odometerController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: "Enter odometer",
                    prefixIcon: const Icon(
                      Icons.speed,
                      color: Color(0xff64748B),
                    ),
                    suffixText: "KM",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xff2757B0),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // TAKE ODOMETER IMAGE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: openOdometerCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      odometerImageBytes == null
                          ? "Take Odometer Image"
                          : "Retake Odometer Image",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff12386B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DRIVER NAME
                // ==================================================

                buildTitle("Driver Name"),

                const SizedBox(height: 8),

                buildField(
                  controller: driverController,
                  hint: "Enter driver name",
                  icon: Icons.person,
                  capitalize: true,
                ),
                // ==================================================
                // ODOMETER IMAGE PREVIEW
                // ==================================================

                if (odometerImageBytes != null) ...[

                  const SizedBox(
                    height: 18,
                  ),

                  buildTitle(
                    "Odometer Image",
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  ClipRRect(

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child:
                        Image.memory(

                      odometerImageBytes!,

                      width:
                          double.infinity,

                      height:
                          220,

                      fit:
                          BoxFit.cover,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        OutlinedButton.icon(

                      onPressed:
                          retakeOdometerImage,

                      icon:
                          const Icon(
                        Icons.camera_alt,
                      ),

                      label:
                          const Text(
                        "Retake Odometer Photo",
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // MOVEMENT TYPE
                // ==================================================

                buildTitle(
                  "Movement Type",
                ),

                const SizedBox(
                  height: 8,
                ),

                DropdownButtonFormField<
                    String>(

                  value:
                      selectedMovementType,

                  isExpanded:
                      true,

                  decoration:
                      InputDecoration(

                    hintText:
                        "Select movement type",

                    prefixIcon:
                        const Icon(
                      Icons.swap_horiz,
                    ),

                    filled:
                        true,

                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey
                                .shade300,
                      ),
                    ),
                  ),

                  items:
                      movementTypes
                          .map(
                    (
                      type,
                    ) {

                      return
                          DropdownMenuItem<
                              String>(

                        value:
                            type,

                        child:
                            Text(
                          type,
                        ),
                      );
                    },
                  ).toList(),

                  onChanged:
                      (
                    value,
                  ) {

                    setState(() {
                      selectedMovementType = value;

                      // Demo / TestDrive:
                      // hide movement location and clear old values.
                      if (value == "Demo" || value == "TestDrive") {
                        fromLocationController.clear();
                        toLocationController.clear();

                        fromCityId = null;
                        toCityId = null;

                        fromCityName = null;
                        toCityName = null;

                        selectedFromLocation = null;
                        selectedToLocation = null;
                      }
                    });

                    // Service / Workshop / InterBranch:
                    // show movement locations and apply Login/Gate
                    // location according to Entry / Exit.
                    if (value == "Service" ||
                        value == "Workshop" ||
                        value == "InterBranch") {
                      applyDirectionLocation();
                    }
                  },
                ),

                // ==================================================
                // FROM / TO LOCATION SEARCH
                // ==================================================
                // Only Service / Workshop / InterBranch are shown.
                // Demo / TestDrive are hidden.
                // ==================================================

                if (isLocationRequired()) ...[
                  const SizedBox(height: 20),

                  // ==================================================
                  // MOVEMENT LOCATIONS
                  // Gate side is disabled; opposite side is optional and searchable.
                  // ==================================================

                  buildTitle('Movement Locations'),

                  const SizedBox(height: 10),

                  // ==================================================
                  // FROM LOCATION - COL 12
                  // Entry -> Optional/searchable
                  // Exit  -> Gate (disabled/read-only)
                  // ==================================================

                  buildTitle(direction == 'Entry' ? 'From Location (optional)' : 'From Location (your gate)'),

                  const SizedBox(height: 8),

                  if (direction == 'Entry')
                    locationSearchField(
                      controller: fromLocationController,
                      hint: 'Type 2–3 letters to search...',
                      icon: Icons.location_searching,
                      onSelected: (location) {
                        final cityName =
                            location['CityName']?.toString() ?? '';
                        final locationName =
                            location['LocationName']?.toString() ?? '';

                        setState(() {
                          selectedFromLocation = location;

                          fromCityId = int.tryParse(
                            location['CityId']?.toString() ?? '',
                          );

                          fromCityName = cityName;

                          fromLocationController.text =
                              locationName.isNotEmpty
                                  ? locationName
                                  : cityName;
                        });

                        debugPrint(
                          'ENTRY FROM CITY NAME: $cityName',
                        );
                        debugPrint(
                          'ENTRY FROM LOCATION: $locationName',
                        );
                        debugPrint(
                          'ENTRY FROM CITY ID: $fromCityId',
                        );
                      },
                    )
                  else
                    TextField(
                      controller: fromLocationController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Login / Gate Location',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Color(0xff64748B),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // TO LOCATION - COL 12
                  // Entry -> Gate (disabled/read-only)
                  // Exit  -> Optional/searchable
                  // ==================================================

                  buildTitle(direction == 'Entry' ? 'To Location (your gate)' : 'To Location (optional)'),

                  const SizedBox(height: 8),

                  if (direction == 'Exit')
                    locationSearchField(
                      controller: toLocationController,
                      hint: 'Type 2–3 letters to search...',
                      icon: Icons.location_on_outlined,
                      onSelected: (location) {
                        final cityName =
                            location['CityName']?.toString() ?? '';
                        final locationName =
                            location['LocationName']?.toString() ?? '';

                        setState(() {
                          selectedToLocation = location;

                          toCityId = int.tryParse(
                            location['CityId']?.toString() ?? '',
                          );

                          toCityName = cityName;

                          toLocationController.text =
                              locationName.isNotEmpty
                                  ? locationName
                                  : cityName;
                        });

                        debugPrint(
                          'EXIT TO CITY NAME: $cityName',
                        );
                        debugPrint(
                          'EXIT TO LOCATION: $locationName',
                        );
                        debugPrint(
                          'EXIT TO CITY ID: $toCityId',
                        );
                      },
                    )
                  else
                    TextField(
                      controller: toLocationController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Login / Gate Location',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Color(0xff64748B),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SALES EXECUTIVE + CUSTOMER
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Expanded(
                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          buildTitle(
                            "Sales Executive",
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          buildField(
                            controller:
                                salesExecutiveController,

                            hint:
                                "Enter sales executive",

                            icon: Icons .person_outline,
                            capitalize: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          buildTitle(
                            "Customer Name",
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          buildField(
                            controller:
                                customerNameController,

                            hint:
                                "Enter customer name",

                            icon:
                                Icons.person,
                                capitalize: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // PURPOSE
                // ==================================================

                buildTitle(
                  "Purpose",
                ),

                const SizedBox(
                  height: 8,
                ),

                buildField(
                  controller: purposeController,

                  hint: "e.g. Customer demo drive – Model X",

                  icon: Icons
                          .description_outlined,

                  maxLines:
                      2,
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // RECORD MOVEMENT
                // ==================================================

                SizedBox(

                  width:
                      double.infinity,

                  height:
                      55,

                  child:
                      ElevatedButton.icon(

                    style:
                        ElevatedButton
                            .styleFrom(

                      backgroundColor:
                          const Color(
                        0xff2757B0,
                      ),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),

                    onPressed:
                        isSaving
                            ? null
                            : saveMovement,

                    icon:
                        isSaving

                            ? const SizedBox(
                                width:
                                    20,

                                height:
                                    20,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,

                                  color:
                                      Colors.white,
                                ),
                              )

                            : const Icon(
                                Icons
                                    .save_outlined,
                              ),

                    label:
                        Text(

                      isSaving
                          ? "Saving..."
                          : "Record Movement",

                      style:
                          const TextStyle(
                        fontSize:
                            17,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget buildTitle(
    String title,
  ) {

    return Text(

      title,

      style:
          const TextStyle(

        fontWeight:
            FontWeight.bold,

        fontSize:
            13,

        color:
            Color(
          0xff4B5B73,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================


Widget buildField({
  required TextEditingController controller,
  required IconData icon,
  String? hint,
  TextInputType keyboard = TextInputType.text,
  int maxLines = 1,
  bool capitalize = true,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: maxLines,

    // Keyboard capital mode
    textCapitalization: capitalize
        ? TextCapitalization.words
        : TextCapitalization.none,

    // Automatically convert:
    // rahul kumar -> Rahul Kumar
    onChanged: capitalize
        ? (value) {
            final words = value.split(' ');

            final formatted = words.map((word) {
              if (word.isEmpty) return '';

              return word[0].toUpperCase() +
                  word.substring(1).toLowerCase();
            }).join(' ');

            if (formatted != value) {
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(
                  offset: formatted.length,
                ),
              );
            }
          }
        : null,

    decoration: InputDecoration(
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: const Color(0xff64748B),
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xff2757B0),
          width: 2,
        ),
      ),
    ),
  );
}

}