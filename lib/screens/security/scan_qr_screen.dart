import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

// ============================================================
// CITY MODEL
// ============================================================

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

  factory CityModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CityModel(
      cityId:
          int.tryParse(
                json['CityId']?.toString() ?? '',
              ) ??
              0,
      stateId:
          int.tryParse(
                json['StateId']?.toString() ?? '',
              ) ??
              0,
      cityName:
          json['CityName']?.toString() ?? '',
      locationName:
          json['LocationName']?.toString() ?? '',
      locationType:
          json['LocationType']?.toString() ?? '',
      pinCode:
          json['PinCode']?.toString() ?? '',
    );
  }
}

// ============================================================
// SCAN QR SCREEN
// ============================================================

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({
    super.key,
  });

  @override
  State<ScanQRScreen> createState() =>
      _ScanQRScreenState();
}

class _ScanQRScreenState
    extends State<ScanQRScreen> {

  // ==========================================================
  // AUTH SERVICE
  // ==========================================================

  final AuthService _authService =
      AuthService();

  // ==========================================================
  // QR SCANNER
  // ==========================================================

  final MobileScannerController
      controller =
      MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed:
        DetectionSpeed.normal,
  );

  bool isScanned = false;
  bool isLoadingVehicle = false;

  String scannedCode =
      "No QR Code Detected";

  Map<String, dynamic>?
      vehicleDetails;

  // ==========================================================
  // ODOMETER
  // ==========================================================

  final TextEditingController
      odometerController =
      TextEditingController();

  // ==========================================================
  // ODOMETER PHOTO
  // ==========================================================

  final ImagePicker _imagePicker =
      ImagePicker();

  XFile? odometerImage;

  Uint8List? odometerImageBytes;

  bool isTakingOdometerPhoto =
      false;

  // ==========================================================
  // DRIVER
  // ==========================================================

  final TextEditingController
      driverNameController =
      TextEditingController();

  // ==========================================================
  // SALES EXECUTIVE
  // ==========================================================

  final TextEditingController
      salesExecutiveController =
      TextEditingController();

  // ==========================================================
  // CUSTOMER
  // ==========================================================

  final TextEditingController
      customerNameController =
      TextEditingController();

  // ==========================================================
  // PURPOSE
  // ==========================================================

  final TextEditingController
      purposeController =
      TextEditingController();

  // ==========================================================
  // FROM LOCATION
  // ==========================================================

  final TextEditingController
      fromLocationController =
      TextEditingController();

  // ==========================================================
  // TO LOCATION
  // ==========================================================

  final TextEditingController
      toLocationController =
      TextEditingController();

  // ==========================================================
  // CITY IDS
  // ==========================================================

  int? fromCityId;

  int? toCityId;

  // ==========================================================
  // SELECTED LOCATION
  // ==========================================================

  Map<String, dynamic>?
      selectedFromLocation;

  Map<String, dynamic>?
      selectedToLocation;

  // ==========================================================
  // DIRECTION
  // ==========================================================

  String? selectedDirection;

  final List<String> directions = [
    "Entry (returning)",
    "Exit (going out)",
  ];

  // ==========================================================
  // MOVEMENT TYPE
  // ==========================================================

  String? selectedMovementType;

  final List<String> movementTypes = [
    "Demo",
    "TestDrive",
    "Service",
    "Workshop",
    "InterBranch",
  ];

  // ==========================================================
  // LOGIN / GATE
  // ==========================================================

  String gateCityName = "";

  int stateId = 0;

  // ==========================================================
  // CITIES
  // ==========================================================

  List<CityModel> allCities = [];

  bool isLoadingCities = false;

  // ==========================================================
  // INIT STATE
  // ==========================================================

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

    final prefs =
        await SharedPreferences
            .getInstance();

    // ----------------------------------------------------------
    // CITY NAME
    // ----------------------------------------------------------

    String cityName =
        prefs.getString(
              "cityName",
            ) ??
            "";

    if (cityName.trim().isEmpty) {

      cityName =
          prefs.getString(
                "CityName",
              ) ??
              "";
    }

    // ----------------------------------------------------------
    // STATE ID
    // ----------------------------------------------------------

    int savedStateId =
        prefs.getInt(
              "stateId",
            ) ??
            0;

    if (savedStateId == 0) {

      savedStateId =
          prefs.getInt(
                "StateId",
              ) ??
              0;
    }

    if (!mounted) {
      return;
    }

    setState(() {

      gateCityName =
          cityName.trim();

      stateId =
          savedStateId;
    });

    debugPrint(
      "======================================",
    );

    debugPrint(
      "LOGIN / GATE DATA",
    );

    debugPrint(
      "CityName: $gateCityName",
    );

    debugPrint(
      "StateId: $stateId",
    );

    debugPrint(
      "======================================",
    );
  }

  // ============================================================
  // LOAD CITIES
  // ============================================================

  Future<void> loadCities() async {

    if (mounted) {

      setState(() {

        isLoadingCities =
            true;
      });
    }

    try {

      final response =
          await http.get(
        Uri.parse(
          "http://103.168.210.85:4001/api/cities",
        ),
        headers: {
          "Accept":
              "application/json",
        },
      );

      debugPrint(
        "======================================",
      );

      debugPrint(
        "CITIES API STATUS: "
        "${response.statusCode}",
      );

      debugPrint(
        "CITIES API RESPONSE:",
      );

      debugPrint(
        response.body,
      );

      debugPrint(
        "======================================",
      );

      if (response.statusCode != 200) {

        throw Exception(
          "Cities API failed: "
          "${response.statusCode}",
        );
      }

      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! Map) {

        throw Exception(
          "Invalid cities API response",
        );
      }

      final dynamic rawData =
          decoded["data"];

      if (rawData is! List) {

        throw Exception(
          "City data not found",
        );
      }

      final List<CityModel>
          result =
          rawData
              .where(
                (item) =>
                    item is Map,
              )
              .map(
                (item) =>
                    CityModel.fromJson(
                  Map<String, dynamic>
                      .from(
                    item,
                  ),
                ),
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {

        allCities =
            result;

        isLoadingCities =
            false;
      });

      debugPrint(
        "TOTAL CITIES: "
        "${allCities.length}",
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      setState(() {

        isLoadingCities =
            false;
      });

      debugPrint(
        "CITIES API ERROR: $e",
      );

      showMessage(
        "Unable to load cities",
        isError: true,
      );
    }
  }

  // ============================================================
  // SEARCH CITIES
  // ============================================================

  List<Map<String, dynamic>>
      searchCities(
    String query,
  ) {

    final String search =
        query
            .trim()
            .toLowerCase();

    // ----------------------------------------------------------
    // EMPTY SEARCH
    // ----------------------------------------------------------

    if (search.isEmpty) {

      return allCities
          .take(20)
          .map(
            (city) => {

              "CityId":
                  city.cityId,

              "StateId":
                  city.stateId,

              "CityName":
                  city.cityName,

              "LocationName":
                  city.locationName,

              "LocationType":
                  city.locationType,

              "PinCode":
                  city.pinCode,
            },
          )
          .toList();
    }

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    return allCities
        .where(
          (city) {

            final cityName =
                city.cityName
                    .toLowerCase();

            final locationName =
                city.locationName
                    .toLowerCase();

            final locationType =
                city.locationType
                    .toLowerCase();

            final pinCode =
                city.pinCode
                    .toLowerCase();

            final cityId =
                city.cityId
                    .toString()
                    .toLowerCase();

            return
                cityName.contains(
                  search,
                ) ||
                locationName.contains(
                  search,
                ) ||
                locationType.contains(
                  search,
                ) ||
                pinCode.contains(
                  search,
                ) ||
                cityId.contains(
                  search,
                );
          },
        )
        .take(20)
        .map(
          (city) => {

            "CityId":
                city.cityId,

            "StateId":
                city.stateId,

            "CityName":
                city.cityName,

            "LocationName":
                city.locationName,

            "LocationType":
                city.locationType,

            "PinCode":
                city.pinCode,
          },
        )
        .toList();
  }

  // ============================================================
  // FIND CITY ID BY CITY NAME
  // ============================================================

  int? findCityIdByName(
    String cityName,
  ) {

    final search =
        cityName
            .trim()
            .toLowerCase();

    if (search.isEmpty) {
      return null;
    }

    for (final city
        in allCities) {

      if (city.cityName
              .trim()
              .toLowerCase() ==
          search) {

        return city.cityId;
      }
    }

    return null;
  }

  // ============================================================
  // DIRECTION CHANGE
  // ============================================================

  void onDirectionChanged(
    String? value,
  ) {

    if (value == null) {
      return;
    }

    setState(() {

      selectedDirection =
          value;

      // --------------------------------------------------------
      // CLEAR OLD FROM
      // --------------------------------------------------------

      fromLocationController
          .clear();

      fromCityId =
          null;

      selectedFromLocation =
          null;

      // --------------------------------------------------------
      // CLEAR OLD TO
      // --------------------------------------------------------

      toLocationController
          .clear();

      toCityId =
          null;

      selectedToLocation =
          null;
    });
  }

  // ============================================================
  // LOCATION SEARCH FIELD
  // ============================================================

  Widget _locationSearchField({

    required TextEditingController
        controller,

    required String hint,

    required IconData icon,

    required bool enabled,

    required bool readOnly,

    required bool isGateField,

    required ValueChanged<
            Map<String, dynamic>>
        onSelected,

  }) {

    return Autocomplete<
        Map<String, dynamic>>(
      
      // ========================================================
      // DISPLAY VALUE
      // ========================================================

      displayStringForOption:
          (location) {

        return location[
                    "LocationName"]
                ?.toString() ??
            "";
      },

      // ========================================================
      // OPTIONS
      // ========================================================

      optionsBuilder:
          (TextEditingValue value) {

        // ------------------------------------------------------
        // LOGIN / GATE FIELD
        // ------------------------------------------------------

        if (!enabled ||
            readOnly ||
            isGateField) {

          return const Iterable<
              Map<String, dynamic>>.empty();
        }

        // ------------------------------------------------------
        // SEARCH
        // ------------------------------------------------------

        final results =
            searchCities(
          value.text,
        );

        debugPrint(
          "LOCATION SEARCH: "
          "${value.text}",
        );

        debugPrint(
          "RESULT COUNT: "
          "${results.length}",
        );

        return results;
      },

      // ========================================================
      // SELECT LOCATION
      // ========================================================

      onSelected:
          (Map<String, dynamic>
              location) {

        final String locationName =
            location[
                        "LocationName"]
                    ?.toString() ??
                "";

        final int? cityId =
            int.tryParse(
          location[
                      "CityId"]
                  ?.toString() ??
              "",
        );

        controller.text =
            locationName;

        onSelected(
          location,
        );

        debugPrint(
          "======================================",
        );

        debugPrint(
          "SELECTED LOCATION",
        );

        debugPrint(
          "LocationName: "
          "$locationName",
        );

        debugPrint(
          "CityId: "
          "$cityId",
        );

        debugPrint(
          "CityName: "
          "${location["CityName"]}",
        );

        debugPrint(
          "LocationType: "
          "${location["LocationType"]}",
        );

        debugPrint(
          "======================================",
        );
      },

      // ========================================================
      // FIELD VIEW
      // ========================================================

      fieldViewBuilder: (

        BuildContext context,

        TextEditingController
            fieldController,

        FocusNode focusNode,

        VoidCallback
            onFieldSubmitted,

      ) {

        if (fieldController.text !=
            controller.text) {

          fieldController.value =
              TextEditingValue(

            text:
                controller.text,

            selection:
                TextSelection
                    .collapsed(
              offset:
                  controller.text.length,
            ),
          );
        }

        return TextField(

          controller:
              fieldController,

          focusNode:
              focusNode,

          enabled:
              enabled,

          readOnly:
              readOnly,

          textCapitalization:
              TextCapitalization.words,

          decoration:
              _inputDecoration(

            hint:
                hint,

            icon:
                icon,

            suffix:
                isLoadingCities
                    ? "Loading..."
                    : null,
          ),
        );
      },

      // ========================================================
      // OPTIONS VIEW
      // ========================================================

      optionsViewBuilder: (

        BuildContext context,

        AutocompleteOnSelected<
                Map<String, dynamic>>
            onSelected,

        Iterable<
                Map<String, dynamic>>
            options,

      ) {

        final optionList =
            options.toList();

        if (optionList.isEmpty) {

          return const SizedBox
              .shrink();
        }

        return Align(

          alignment:
              Alignment.topLeft,

          child: Material(

            elevation: 8,

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            child: Container(

              width:
                  MediaQuery.of(context)
                          .size
                          .width *
                      0.43,

              constraints:
                  const BoxConstraints(
                maxHeight: 300,
              ),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border:
                    Border.all(
                  color:
                      Colors.grey.shade300,
                ),
              ),

              child:
                  ListView.separated(

                padding:
                    EdgeInsets.zero,

                shrinkWrap:
                    true,

                itemCount:
                    optionList.length,

                separatorBuilder:
                    (_, __) {

                  return const Divider(
                    height: 1,
                  );
                },

                itemBuilder:
                    (context, index) {

                  final location =
                      optionList[index];

                  final locationName =
                      location[
                                  "LocationName"]
                              ?.toString() ??
                          "";

                  final cityName =
                      location[
                                  "CityName"]
                              ?.toString() ??
                          "";

                  final cityId =
                      location[
                                  "CityId"]
                              ?.toString() ??
                          "";

                  final locationType =
                      location[
                                  "LocationType"]
                              ?.toString() ??
                          "";

                  final pinCode =
                      location[
                                  "PinCode"]
                              ?.toString() ??
                          "";

                  return ListTile(

                    dense:
                        true,

                    leading:
                        const Icon(
                      Icons.location_on,
                      color:
                          Color(
                        0xff2458A6,
                      ),
                    ),

                    title:
                        Text(

                      locationName,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    subtitle:
                        Text(

                      cityName,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),

                    onTap: () {

                      onSelected(
                        location,
                      );
                    },
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
  // ODOMETER PHOTO
  // ============================================================

  Future<void>
      takeOdometerPhoto() async {

    if (isTakingOdometerPhoto) {
      return;
    }

    setState(() {

      isTakingOdometerPhoto =
          true;
    });

    try {

      final XFile? image =
          await _imagePicker
              .pickImage(

        source:
            ImageSource.camera,

        imageQuality:
            85,

        maxWidth:
            1600,

        maxHeight:
            1600,
      );

      if (image == null) {

        if (mounted) {

          setState(() {

            isTakingOdometerPhoto =
                false;
          });
        }

        return;
      }

      final Uint8List bytes =
          await image.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {

        odometerImage =
            image;

        odometerImageBytes =
            bytes;

        isTakingOdometerPhoto =
            false;
      });

      showMessage(
        "Odometer photo captured",
        isError: false,
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      setState(() {

        isTakingOdometerPhoto =
            false;
      });

      debugPrint(
        "ODOMETER PHOTO ERROR: $e",
      );

      showMessage(
        "Unable to open camera: $e",
        isError: true,
      );
    }
  }

  // ============================================================
  // ODOMETER PHOTO UI
  // ============================================================

  Widget _buildOdometerPhoto() {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        _sectionLabel(
          "Odometer Photo",
        ),

        const SizedBox(
          height: 7,
        ),

        if (odometerImageBytes !=
            null) ...[

          Container(

            width:
                double.infinity,

            height:
                190,

            decoration:
                BoxDecoration(

              color:
                  Colors.grey.shade100,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              border:
                  Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),

            clipBehavior:
                Clip.antiAlias,

            child:
                Image.memory(

              odometerImageBytes!,

              width:
                  double.infinity,

              height:
                  190,

              fit:
                  BoxFit.cover,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(

            children: [

              Expanded(

                child:
                    OutlinedButton.icon(

                  onPressed:
                      isTakingOdometerPhoto
                          ? null
                          : takeOdometerPhoto,

                  icon:
                      const Icon(
                    Icons.camera_alt,
                  ),

                  label:
                      const Text(
                    "Retake Photo",
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              IconButton(

                tooltip:
                    "Remove Photo",

                onPressed: () {

                  setState(() {

                    odometerImage =
                        null;

                    odometerImageBytes =
                        null;
                  });
                },

                icon:
                    const Icon(
                  Icons.delete_outline,
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),

        ] else ...[

          SizedBox(

            width:
                double.infinity,

            child:
                OutlinedButton.icon(

              onPressed:
                  isTakingOdometerPhoto
                      ? null
                      : takeOdometerPhoto,

              icon:
                  isTakingOdometerPhoto

                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )

                      : const Icon(
                          Icons.camera_alt,
                        ),

              label:
                  Text(

                isTakingOdometerPhoto

                    ? "Opening Camera..."

                    : "Take Odometer Photo",
              ),

              style:
                  OutlinedButton.styleFrom(

                minimumSize:
                    const Size(
                  0,
                  52,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SAVE MOVEMENT
  // ============================================================

  Future<void> saveMovement() async {

    // ==========================================================
    // VEHICLE CHECK
    // ==========================================================

    if (vehicleDetails == null) {

      showMessage(
        "Please scan vehicle QR",
        isError: true,
      );

      return;
    }

    // ==========================================================
    // DIRECTION CHECK
    // ==========================================================

    if (selectedDirection == null ||
        selectedDirection!
            .trim()
            .isEmpty) {

      showMessage(
        "Please select Direction",
        isError: true,
      );

      return;
    }

    // ==========================================================
    // MOVEMENT TYPE CHECK
    // ==========================================================

    if (selectedMovementType ==
            null ||
        selectedMovementType!
            .trim()
            .isEmpty) {

      showMessage(
        "Please select Movement Type",
        isError: true,
      );

      return;
    }

    // ==========================================================
    // ODOMETER
    // ==========================================================

    final int? odometer =
        int.tryParse(
      odometerController.text
          .trim(),
    );

    if (odometer == null) {

      showMessage(
        "Please enter valid Odometer",
        isError: true,
      );

      return;
    }

    // ==========================================================
    // DRIVER
    // ==========================================================

    final String driverName =
        driverNameController.text
            .trim();

    if (driverName.isEmpty) {

      showMessage(
        "Please enter Driver Name",
        isError: true,
      );

      return;
    }

    // ==========================================================
    // LOCATIONS
    // ==========================================================

    final String fromLocation =
        fromLocationController.text
            .trim();

    final String toLocation =
        toLocationController.text
            .trim();

    // ==========================================================
    // LOCATION REQUIRED
    // ==========================================================

    final bool locationRequired =
        selectedMovementType !=
                "Demo" &&
            selectedMovementType !=
                "TestDrive";

    // ==========================================================
    // FROM VALIDATION
    // ==========================================================

    if (locationRequired) {

      if (fromLocation.isEmpty) {

        showMessage(
          "Please select From Location",
          isError: true,
        );

        return;
      }

      // if (fromCityId == null ||
      //     fromCityId == 0) {

      //   showMessage(
      //     "Please select a valid From Location",
      //     isError: true,
      //   );

      //   return;
      // }

      // ========================================================
      // TO VALIDATION
      // ========================================================

      // if (toLocation.isEmpty) {

      //   showMessage(
      //     "Please select To Location",
      //     isError: true,
      //   );

      //   return;
      // }

      // if (toCityId == null ||
      //     toCityId == 0) {

      //   showMessage(
      //     "Please select a valid To Location",
      //     isError: true,
      //   );

      //   return;
      // }
    }

    try {

      // ========================================================
      // VEHICLE DATA
      // ========================================================

      final rawData =
          vehicleDetails!["data"];

      if (rawData is! Map) {

        throw Exception(
          "Vehicle data not found",
        );
      }

      final Map<String, dynamic>
          data =
          Map<String, dynamic>
              .from(
        rawData,
      );

      // ========================================================
      // VEHICLE ID
      // ========================================================

      final int vehicleId =
          int.tryParse(
                data["VehicleId"]
                        ?.toString() ??
                    "",
              ) ??
              0;

      if (vehicleId == 0) {

        throw Exception(
          "VehicleId not found",
        );
      }

      // ========================================================
      // QR TOKEN
      // ========================================================

      final Uri? uri =
          Uri.tryParse(
        scannedCode,
      );

      String? qrToken;

      if (uri != null) {

        qrToken =
            uri.queryParameters[
                "token"];
      }

      qrToken ??=
          scannedCode;

      // ========================================================
      // BRANCH
      // ========================================================

      const int branchId = 1;

      // ========================================================
      // API DIRECTION
      // ========================================================

      final String apiDirection =
          selectedDirection ==
                  "Entry (returning)"
              ? "Entry"
              : "Exit";

      // ========================================================
      // PHOTO UPLOAD
      // ========================================================

      String? uploadedImagePath;

      if (odometerImageBytes !=
          null) {

        final uploadResult =
            await _authService
                .uploadAttachment(

          bytes:
              odometerImageBytes!,

          fileName:
              odometerImage?.name ??
                  "odometer.jpg",

          entityType:
              "Movement",
        );

        uploadedImagePath = uploadResult.url;

        debugPrint(
          "ODOMETER PHOTO UPLOADED: "
          "$uploadedImagePath",
        );
      }

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        "======================================",
      );

      debugPrint(
        "MOVEMENT SAVE",
      );

      debugPrint(
        "======================================",
      );

      debugPrint(
        "BranchId       : $branchId",
      );

      debugPrint(
        "VehicleId      : $vehicleId",
      );

      debugPrint(
        "QR Token       : $qrToken",
      );

      debugPrint(
        "Direction UI   : $selectedDirection",
      );

      debugPrint(
        "Direction API  : $apiDirection",
      );

      debugPrint(
        "Movement Type  : "
        "$selectedMovementType",
      );

      debugPrint(
        "From Location  : "
        "$fromLocation",
      );

      debugPrint(
        "From CityId    : "
        "$fromCityId",
      );

      debugPrint(
        "To Location    : "
        "$toLocation",
      );

      debugPrint(
        "To CityId      : "
        "$toCityId",
      );

      debugPrint(
        "Odometer       : "
        "$odometer",
      );

      debugPrint(
        "Driver Name    : "
        "$driverName",
      );

      debugPrint(
        "Sales Executive: "
        "${salesExecutiveController.text.trim()}",
      );

      debugPrint(
        "Customer Name  : "
        "${customerNameController.text.trim()}",
      );

      debugPrint(
        "Purpose        : "
        "${purposeController.text.trim()}",
      );

      debugPrint(
        "Image Path     : "
        "$uploadedImagePath",
      );

      debugPrint(
        "======================================",
      );

      // ========================================================
      // MOVEMENT API
      // ========================================================

      await _authService.movementSave(

        branchId:
            branchId,

        vehicleId:
            vehicleId,

        qrToken:
            qrToken,

        txnDate:
            DateTime.now()
                .toIso8601String(),

        direction:
            apiDirection,

        // ======================================================
        // FROM LOCATION
        // ======================================================

        fromLocation:
            locationRequired
                ? fromLocation
                : "",

        fromCityId:
            locationRequired
                ? fromCityId
                : null,

        // ======================================================
        // TO LOCATION
        // ======================================================

        toLocation:
            locationRequired
                ? toLocation
                : "",

        toCityId:
            locationRequired
                ? toCityId
                : null,

        // ======================================================
        // ODOMETER
        // ======================================================

        odometer:
            odometer,

        // ======================================================
        // DRIVER
        // ======================================================

        driverName:
            driverName,

        // ======================================================
        // MOVEMENT TYPE
        // ======================================================

        movementType:
            selectedMovementType!,

        // ======================================================
        // SALES EXECUTIVE
        // ======================================================

        salesExecutive:
            salesExecutiveController
                .text
                .trim(),

        // ======================================================
        // CUSTOMER
        // ======================================================

        customerName:
            customerNameController
                .text
                .trim(),

        // ======================================================
        // PURPOSE
        // ======================================================

        purpose:
            purposeController
                .text
                .trim(),

        // ======================================================
        // PHOTO
        // ======================================================

        imagePath:
            uploadedImagePath,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      showMessage(
        "Movement saved successfully",
        isError: false,
      );

      // ========================================================
      // SCAN AGAIN
      // ========================================================

      Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
        () {

          if (!mounted) {
            return;
          }

          _scanAgain();
        },
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      debugPrint(
        "======================================",
      );

      debugPrint(
        "MOVEMENT SAVE ERROR",
      );

      debugPrint(
        "$e",
      );

      debugPrint(
        "======================================",
      );

      showMessage(
        "Save failed: $e",
        isError: true,
      );
    }
  }

  // ============================================================
  // LOCATION FIELDS
  //
  // IMPORTANT FINAL LOGIC:
  //
  // ENTRY:
  // To   = Login/Gate
  // From = Search destination
  //
  // EXIT:
  // To   = Login/Gate
  // From = Search source
  // ============================================================

  // ============================================================
  // LOCATION FIELDS
  //
  // FINAL LOGIC:
  //
  // ENTRY (returning):
  //   To   = Login/Gate (fixed)
  //   From = Search destination (editable)
  //
  // EXIT (going out):
  //   From = Login/Gate (fixed)
  //   To   = Search destination (editable)
  //
  // ============================================================

  Widget _buildLocationFields() {

    // ==========================================================
    // DEMO / TEST DRIVE
    // ==========================================================

    if (selectedMovementType == "Demo" ||
        selectedMovementType == "TestDrive") {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // DIRECTION
    // ==========================================================

    final bool isEntry =
        selectedDirection == "Entry (returning)";

    final bool isExit =
        selectedDirection == "Exit (going out)";

    // ==========================================================
    // GATE CITY ID
    // ==========================================================

    final int? gateCityId =
        findCityIdByName(gateCityName);

    // ==========================================================
    // ENTRY:
    // To = Login/Gate
    // From = Search
    // ==========================================================

    if (isEntry &&
        gateCityName.trim().isNotEmpty) {

      toLocationController.text =
          gateCityName;

      toCityId = gateCityId;

      selectedToLocation = {
        "CityId": gateCityId,
        "CityName": gateCityName,
        "LocationName": gateCityName,
        "LocationType": "Login/Gate",
        "PinCode": "",
      };
    }

    // ==========================================================
    // EXIT:
    // From = Login/Gate
    // To = Search
    // ==========================================================

    if (isExit &&
        gateCityName.trim().isNotEmpty) {

      fromLocationController.text =
          gateCityName;

      fromCityId = gateCityId;

      selectedFromLocation = {
        "CityId": gateCityId,
        "CityName": gateCityName,
        "LocationName": gateCityName,
        "LocationType": "Login/Gate",
        "PinCode": "",
      };
    }

    // ==========================================================
    // ENTRY UI
    // ==========================================================

    if (isEntry) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ------------------------------------------------------
          // TO LOCATION - GATE
          // ------------------------------------------------------

          _sectionLabel(
            "To Location (your gate)",
          ),

          const SizedBox(height: 7),

          _locationSearchField(
            controller:
                toLocationController,
            hint:
                "Login/Gate Location",
            icon:
                Icons.location_on_outlined,
            enabled:
                false,
            readOnly: false,
            isGateField:
                true,
            onSelected:
                (location) {
              setState(() {
                selectedToLocation =
                    location;

                toLocationController.text =
                    location["LocationName"]
                            ?.toString() ??
                        "";

                toCityId =
                    int.tryParse(
                  location["CityId"]
                          ?.toString() ??
                      "",
                );
              });
            },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // FROM LOCATION - SEARCH
          // ------------------------------------------------------

          _sectionLabel(
            "From Location (optional)",
          ),

          const SizedBox(height: 7),

          _locationSearchField(
            controller:
                fromLocationController,
            hint:
                "Type 2–3 letters to search...",
            icon:
                Icons.location_searching,
            enabled:
                true,
            readOnly:
                false,
            isGateField:
                false,
            onSelected:
                (location) {
              setState(() {
                selectedFromLocation =
                    location;

                fromLocationController.text =
                    location["LocationName"]
                            ?.toString() ??
                        "";

                fromCityId =
                    int.tryParse(
                  location["CityId"]
                          ?.toString() ??
                      "",
                );
              });
            },
          ),
        ],
      );
    }

    // ==========================================================
    // EXIT UI
    // ==========================================================

    if (isExit) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ------------------------------------------------------
          // FROM LOCATION - GATE
          // ------------------------------------------------------

          _sectionLabel(
            "From Location (your gate)",
          ),

          const SizedBox(height: 7),

          _locationSearchField(
            controller:
                fromLocationController,
            hint:
                "Login/Gate Location",
            icon:
                Icons.location_searching,
            enabled:
                false,
            readOnly:
                true,
            isGateField:
                true,
            onSelected:
                (location) {
              setState(() {
                selectedFromLocation =
                    location;

                fromLocationController.text =
                    location["LocationName"]
                            ?.toString() ??
                        "";

                fromCityId =
                    int.tryParse(
                  location["CityId"]
                          ?.toString() ??
                      "",
                );
              });
            },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // TO LOCATION - SEARCH
          // ------------------------------------------------------

          _sectionLabel(
            "To Location (optional)",
          ),

          const SizedBox(height: 7),

          _locationSearchField(
            controller:
                toLocationController,
            hint:
                "Type 2–3 letters to search...",
            icon:
                Icons.location_on_outlined,
            enabled:
                true,
            readOnly:
                false,
            isGateField:
                false,
            onSelected:
                (location) {
              setState(() {
                selectedToLocation =
                    location;

                toLocationController.text =
                    location["LocationName"]
                            ?.toString() ??
                        "";

                toCityId =
                    int.tryParse(
                  location["CityId"]
                          ?.toString() ??
                      "",
                );
              });
            },
          ),
        ],
      );
    }

    // ==========================================================
    // NO DIRECTION SELECTED
    // ==========================================================

    return const SizedBox.shrink();
  }

  // ============================================================
  // QR DETECT
  // ============================================================

  Future<void> _onDetect(
    BarcodeCapture capture,
  ) async {

    if (isScanned) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final barcode =
        capture.barcodes.first;

    final String? qrValue =
        barcode.rawValue;

    if (qrValue == null ||
        qrValue.trim().isEmpty) {

      return;
    }

    setState(() {

      isScanned =
          true;

      isLoadingVehicle =
          true;

      scannedCode =
          qrValue.trim();
    });

    try {

      final uri =
          Uri.tryParse(
        qrValue,
      );

      String? token;

      if (uri != null) {

        token =
            uri.queryParameters[
                "token"];
      }

      token ??=
          qrValue;

      debugPrint(
        "QR TOKEN: $token",
      );

      final vehicle =
          await _authService
              .getVehicleByQRToken(
        token,
      );

      if (!mounted) {
        return;
      }

      setState(() {

        vehicleDetails =
            vehicle;

        isLoadingVehicle =
            false;
      });

      final data =
          vehicle["data"];

      if (data is Map) {

        if (data[
                "CurrentOdometer"] !=
            null) {

          odometerController
              .text =
              data[
                      "CurrentOdometer"]
                  .toString();
        }
      }

      showMessage(
        "Vehicle details loaded",
        isError: false,
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      setState(() {

        vehicleDetails =
            null;

        isLoadingVehicle =
            false;

        isScanned =
            false;
      });

      showMessage(
        "Vehicle not found: $e",
        isError: true,
      );
    }
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
          const Color(
        0xff12386B,
      ),

      appBar:
          AppBar(

        backgroundColor:
            const Color(
          0xff12386B,
        ),

        foregroundColor:
            Colors.white,

        elevation:
            0,

        title:
            const Text(
          "Scan Vehicle QR",
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SafeArea(

        child:
            Stack(

          children: [

            // ==================================================
            // CAMERA
            // ==================================================

            Positioned.fill(

              child:
                  Padding(

                padding:
                    const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 190,
                ),

                child:
                    Container(

                  decoration:
                      BoxDecoration(

                    color:
                        Colors.black,

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child:
                      Center(

                    child:
                        SizedBox(

                      width:
                          250,

                      height:
                          250,

                      child:
                          ClipRRect(

                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),

                        child:
                            MobileScanner(

                          controller:
                              controller,

                          onDetect:
                              _onDetect,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // FORM
            // ==================================================

            Align(

              alignment:
                  Alignment.bottomCenter,

              child:
                  Container(

                constraints:
                    BoxConstraints(

                  maxHeight:
                      MediaQuery.of(
                            context,
                          ).size.height *
                          0.80,
                ),

                padding:
                    const EdgeInsets.all(
                  18,
                ),

                decoration:
                    const BoxDecoration(

                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(
                      24,
                    ),
                  ),
                ),

                child:
                    SingleChildScrollView(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Log Gate Movement",

                        style:
                            TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      if (isLoadingVehicle)

                        const Center(
                          child:
                              CircularProgressIndicator(),
                        ),

                      if (vehicleDetails !=
                          null)

                        _buildVehicleCard(),

                      const SizedBox(
                        height: 15,
                      ),

                      Text(
                        "QR Code: "
                        "$scannedCode",

                        maxLines:
                            2,

                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),

                      if (vehicleDetails !=
                          null) ...[

                        const SizedBox(
                          height: 18,
                        ),

                        SizedBox(

                          width:
                              double.infinity,

                          child:
                              ElevatedButton(

                            onPressed:
                                saveMovement,

                            style:
                                ElevatedButton
                                    .styleFrom(

                              backgroundColor:
                                  const Color(
                                0xff2458A6,
                              ),

                              foregroundColor:
                                  Colors.white,

                              minimumSize:
                                  const Size(
                                0,
                                52,
                              ),
                            ),

                            child:
                                const Text(
                              "SAVE MOVEMENT",
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        SizedBox(

                          width:
                              double.infinity,

                          child:
                              OutlinedButton(

                            onPressed:
                                _scanAgain,

                            child:
                                const Text(
                              "Scan Again",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildVehicleCard() {

    final rawData =
        vehicleDetails?["data"];

    if (rawData is! Map) {

      return const Text(
        "Vehicle data not available",
      );
    }

    final data =
        Map<String, dynamic>.from(
      rawData,
    );

    return Card(

      elevation:
          3,

      child:
          Padding(

        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // VEHICLE HEADER
            // ==================================================

            Row(

              children: [

                const Icon(
                  Icons.directions_car,
                  color:
                      Color(
                    0xff2458A6,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                const Text(
                  "Vehicle Details",

                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // VEHICLE NO
            // ==================================================

            _vehicleInfoRow(
              title:
                  "Vehicle No",

              value:
                  data[
                          "RegistrationNo"]
                      ?.toString() ??
                  "-",
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // MODEL
            // ==================================================

            _vehicleInfoRow(
              title:
                  "Model",

              value:
                  data[
                          "Model"]
                      ?.toString() ??
                  "-",
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // VARIANT
            // ==================================================

            _vehicleInfoRow(
              title:
                  "Variant",

              value:
                  data[
                          "Variant"]
                      ?.toString() ??
                  "-",
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DIRECTION
            // ==================================================

            _sectionLabel(
              "Direction",
            ),

            const SizedBox(
              height: 7,
            ),

            DropdownButtonFormField<String>(

              value:
                  selectedDirection,

              isExpanded:
                  true,

              decoration:
                  _inputDecoration(

                hint:
                    "Select direction",

                icon:
                    Icons.compare_arrows,
              ),

              items:
                  directions.map(
                (direction) {

                  return
                      DropdownMenuItem<String>(

                    value:
                        direction,

                    child:
                        Text(
                      direction,
                    ),
                  );
                },
              ).toList(),

              onChanged:
                  onDirectionChanged,
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // MOVEMENT TYPE
            // ==================================================

            _sectionLabel(
              "Movement Type",
            ),

            const SizedBox(
              height: 7,
            ),

            DropdownButtonFormField<String>(

              value:
                  selectedMovementType,

              isExpanded:
                  true,

              decoration:
                  _inputDecoration(

                hint:
                    "Select movement type",

                icon:
                    Icons.swap_horiz,
              ),

              items:
                  movementTypes.map(
                (type) {

                  return
                      DropdownMenuItem<String>(

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
                  (value) {

                setState(() {

                  selectedMovementType =
                      value;

                  // ------------------------------------------------
                  // CLEAR FROM
                  // ------------------------------------------------

                  fromLocationController
                      .clear();

                  fromCityId =
                      null;

                  selectedFromLocation =
                      null;

                  // ------------------------------------------------
                  // CLEAR TO
                  // ------------------------------------------------

                  toLocationController
                      .clear();

                  toCityId =
                      null;

                  selectedToLocation =
                      null;
                });
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // LOCATIONS
            // ==================================================

            _buildLocationFields(),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // ODOMETER
            // ==================================================

            _sectionLabel(
              "Odometer (km)",
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(

              controller:
                  odometerController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  _inputDecoration(

                hint:
                    "Enter odometer",

                icon:
                    Icons.speed,

                suffix:
                    "KM",
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PHOTO
            // ==================================================

            _buildOdometerPhoto(),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // DRIVER
            // ==================================================

            _sectionLabel(
              "Driver Name",
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(

              controller:
                  driverNameController,

              decoration:
                  _inputDecoration(

                hint:
                    "Enter driver name",

                icon:
                    Icons.person_outline,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // SALES EXECUTIVE
            // ==================================================

            _sectionLabel(
              "Sales Executive",
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(

              controller:
                  salesExecutiveController,

              decoration:
                  _inputDecoration(

                hint:
                    "Enter sales executive",

                icon:
                    Icons.person_outline,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // CUSTOMER
            // ==================================================

            _sectionLabel(
              "Customer Name",
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(

              controller:
                  customerNameController,

              decoration:
                  _inputDecoration(

                hint:
                    "Enter customer name",

                icon:
                    Icons.person,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PURPOSE
            // ==================================================

            _sectionLabel(
              "Purpose",
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(

              controller:
                  purposeController,

              maxLines:
                  2,

              decoration:
                  _inputDecoration(

                hint:
                    "Enter purpose",

                icon:
                    Icons.description_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE INFO ROW
  // ============================================================

  Widget _vehicleInfoRow({

    required String title,

    required String value,

  }) {

    return Row(

      children: [

        SizedBox(

          width:
              110,

          child:
              Text(

            title,

            style:
                TextStyle(

              color:
                  Colors.grey.shade600,

              fontSize:
                  13,
            ),
          ),
        ),

        Expanded(

          child:
              Text(

            value,

            style:
                const TextStyle(

              fontWeight:
                  FontWeight.w600,

              fontSize:
                  15,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget _sectionLabel(
    String text,
  ) {

    return Text(

      text,

      style:
          const TextStyle(

        fontSize:
            14,

        fontWeight:
            FontWeight.w600,

        color:
            Color(
          0xff4B5B73,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({

    required String hint,

    IconData? icon,

    String? suffix,

  }) {

    return InputDecoration(

      hintText:
          hint,

      prefixIcon:
          icon != null
              ? Icon(icon)
              : null,

      suffixText:
          suffix,

      filled:
          true,

      fillColor:
          Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            const BorderSide(

          color:
              Color(
            0xff2458A6,
          ),

          width:
              2,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    required bool isError,
  }) {

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(

        content:
            Text(
          message,
        ),

        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // SCAN AGAIN
  // ============================================================

  void _scanAgain() {

    setState(() {

      isScanned =
          false;

      scannedCode =
          "No QR Code Detected";

      vehicleDetails =
          null;

      selectedDirection =
          null;

      selectedMovementType =
          null;

      // --------------------------------------------------------
      // FROM
      // --------------------------------------------------------

      fromLocationController
          .clear();

      fromCityId =
          null;

      selectedFromLocation =
          null;

      // --------------------------------------------------------
      // TO
      // --------------------------------------------------------

      toLocationController
          .clear();

      toCityId =
          null;

      selectedToLocation =
          null;

      // --------------------------------------------------------
      // ODOMETER
      // --------------------------------------------------------

      odometerController
          .clear();

      // --------------------------------------------------------
      // PHOTO
      // --------------------------------------------------------

      odometerImage =
          null;

      odometerImageBytes =
          null;

      // --------------------------------------------------------
      // DRIVER
      // --------------------------------------------------------

      driverNameController
          .clear();

      // --------------------------------------------------------
      // SALES
      // --------------------------------------------------------

      salesExecutiveController
          .clear();

      // --------------------------------------------------------
      // CUSTOMER
      // --------------------------------------------------------

      customerNameController
          .clear();

      // --------------------------------------------------------
      // PURPOSE
      // --------------------------------------------------------

      purposeController
          .clear();
    });

    controller.start();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {

    controller.dispose();

    odometerController
        .dispose();

    driverNameController
        .dispose();

    salesExecutiveController
        .dispose();

    customerNameController
        .dispose();

    purposeController
        .dispose();

    fromLocationController
        .dispose();

    toLocationController
        .dispose();

    super.dispose();
  }
}

