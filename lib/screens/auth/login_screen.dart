import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../driver/driver_home_screen.dart';
import '../security/security_home_screen.dart';
import '../corporate_admin/corporate_admin_home_screen.dart';
import '../branch_admin/branch_admin_home_screen.dart';
import '../accounts/accounts_home_screen.dart';

import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  // ============================================================
  // VARIABLES
  // ============================================================

  bool obscurePassword = true;
  bool isLoading = false;
  bool isLoadingStates = false;
  bool isLoadingLocations = false;
  double? currentLat;
 double? currentLng;
  // ============================================================
  // ROLES
  // ============================================================

  List<dynamic> roles = [];

  String selectedRole = "";
  int? selectedRoleId;

  // ============================================================
  // STATES
  // ============================================================

  List<dynamic> states = [];

  List<int> selectedStateIds = [];
  List<String> selectedStateNames = [];

  // ============================================================
  // LOCATIONS / CITIES
  // ============================================================

  List<dynamic> locations = [];

  List<int> selectedLocationIds = [];
  List<String> selectedLocationNames = [];

  // ============================================================
  // INIT
  // ============================================================
  
   Future<Position> getCurrentLocation() async {
    return await LocationService.getCurrentLocation();
  }


  @override
  void initState() {
    super.initState();

    loadRoles();
    loadStates();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // ROLE LOGIC
  // ============================================================

  bool isStateRequired() {
    return selectedRole == "Accounts" ||
        selectedRole == "Driver" ||
        selectedRole == "BranchAdmin" ||
        selectedRole == "Security" ||
        selectedRole == "StateAdmin";
  }

  bool isLocationRequired() {
    return selectedRole == "Accounts" ||
        selectedRole == "Driver" ||
        selectedRole == "BranchAdmin";
  }

  // ============================================================
  // LOAD ROLES
  // ============================================================

  Future<void> loadRoles() async {
    try {
      final data = await _authService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = data["data"] ?? [];

        selectedRole = "";
        selectedRoleId = null;
      });
    } catch (e) {
      debugPrint("ROLE ERROR: $e");

      if (mounted) {
        showMessage(
          "Unable to load roles\n$e",
        );
      }
    }
  }

  // ============================================================
  // LOAD STATES
  // ============================================================

  Future<void> loadStates() async {
    try {
      setState(() {
        isLoadingStates = true;
      });

      final data = await _authService.getStates();

      if (!mounted) return;

      setState(() {
        states = data["data"] ?? [];
        isLoadingStates = false;
      });

      debugPrint("STATES: $states");
    } catch (e) {
      debugPrint("STATE ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoadingStates = false;
        states = [];
      });

      showMessage(
        "Unable to load states\n$e",
      );
    }
  }

  // ============================================================
  // LOAD LOCATIONS FOR MULTIPLE STATES
  // ============================================================

  Future<void> loadLocationsForSelectedStates() async {
    if (selectedStateIds.isEmpty) {
      setState(() {
        locations = [];
        selectedLocationIds.clear();
        selectedLocationNames.clear();
      });

      return;
    }

    try {
      setState(() {
        isLoadingLocations = true;
      });

      List<dynamic> allLocations = [];

      // Call API for every selected state
      for (final stateId in selectedStateIds) {
        try {
          final data =
              await _authService.getLocations(stateId);

          final cityData = data["data"] ?? [];

          if (cityData is List) {
            allLocations.addAll(cityData);
          }
        } catch (e) {
          debugPrint(
            "Location error for state $stateId: $e",
          );
        }
      }

      // ========================================================
      // REMOVE DUPLICATE CITY IDs
      // ========================================================

      final Map<int, dynamic> uniqueCities = {};

      for (final city in allLocations) {
        final cityId = int.tryParse(
          city["CityId"].toString(),
        );

        if (cityId != null) {
          uniqueCities[cityId] = city;
        }
      }

      if (!mounted) return;

      setState(() {
        locations = uniqueCities.values.toList();

        // Clear previous city selection
        selectedLocationIds.clear();
        selectedLocationNames.clear();

        isLoadingLocations = false;
      });

      debugPrint(
        "ALL LOCATIONS: $locations",
      );
    } catch (e) {
      debugPrint(
        "LOCATION ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        locations = [];
        selectedLocationIds.clear();
        selectedLocationNames.clear();
        isLoadingLocations = false;
      });

      showMessage(
        "Unable to load locations\n$e",
      );
    }
  }

  // ============================================================
  // ROLE SELECT
  // ============================================================

  void onRoleSelected(
    String roleName,
    int? roleId,
  ) {
    setState(() {
      selectedRole = roleName;
      selectedRoleId = roleId;

      selectedStateIds.clear();
      selectedStateNames.clear();

      selectedLocationIds.clear();
      selectedLocationNames.clear();

      locations = [];
    });
  }

  // ============================================================
  // STATE CHECKBOX SELECT
  // ============================================================

  void onStateSelected(
    int stateId,
    String stateName,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        if (!selectedStateIds.contains(stateId)) {
          selectedStateIds.add(stateId);
          selectedStateNames.add(stateName);
        }
      } else {
        selectedStateIds.remove(stateId);
        selectedStateNames.remove(stateName);
      }

      // Whenever state selection changes,
      // location selection will be refreshed.
      selectedLocationIds.clear();
      selectedLocationNames.clear();
    });

    loadLocationsForSelectedStates();
  }

  // ============================================================
  // LOCATION CHECKBOX SELECT
  // ============================================================

  void onLocationSelected(
    int cityId,
    String cityName,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        if (!selectedLocationIds.contains(cityId)) {
          selectedLocationIds.add(cityId);
          selectedLocationNames.add(cityName);
        }
      } else {
        selectedLocationIds.remove(cityId);
        selectedLocationNames.remove(cityName);
      }
    });
  }

  // ============================================================
  // SELECT / UNSELECT ALL STATES
  // ============================================================

  void selectAllStates() {
    setState(() {
      selectedStateIds.clear();
      selectedStateNames.clear();

      for (final state in states) {
        final int? stateId = int.tryParse(
          state["StateId"].toString(),
        );

        final String stateName =
            state["StateName"]?.toString() ??
                state["Name"]?.toString() ??
                "";

        if (stateId != null) {
          selectedStateIds.add(stateId);
          selectedStateNames.add(stateName);
        }
      }

      selectedLocationIds.clear();
      selectedLocationNames.clear();
    });

    loadLocationsForSelectedStates();
  }

  void clearAllStates() {
    setState(() {
      selectedStateIds.clear();
      selectedStateNames.clear();

      selectedLocationIds.clear();
      selectedLocationNames.clear();

      locations.clear();
    });
  }

  // ============================================================
  // SELECT / UNSELECT ALL LOCATIONS
  // ============================================================

  void selectAllLocations() {
    setState(() {
      selectedLocationIds.clear();
      selectedLocationNames.clear();

      for (final location in locations) {
        final int? cityId = int.tryParse(
          location["CityId"].toString(),
        );

        final String cityName =
            location["CityName"]?.toString() ??
                location["Name"]?.toString() ??
                "";

        if (cityId != null) {
          selectedLocationIds.add(cityId);
          selectedLocationNames.add(cityName);
        }
      }
    });
  }

  void clearAllLocations() {
    setState(() {
      selectedLocationIds.clear();
      selectedLocationNames.clear();
    });
  }


Future<void> login() async {
  // ==========================================================
  // EMAIL VALIDATION
  // ==========================================================

  if (emailController.text.trim().isEmpty) {
    showMessage("Please enter email");
    return;
  }

  // ==========================================================
  // PASSWORD VALIDATION
  // ==========================================================

  if (passwordController.text.trim().isEmpty) {
    showMessage("Please enter password");
    return;
  }

  // ==========================================================
  // ROLE VALIDATION
  // ==========================================================

  if (selectedRoleId == null) {
    showMessage("Please select role");
    return;
  }

  // ==========================================================
  // STATE VALIDATION
  // ==========================================================

  if (isStateRequired() &&
      selectedStateIds.isEmpty) {
    showMessage(
      "Please select at least one state",
    );
    return;
  }

  // ==========================================================
  // LOCATION VALIDATION
  // ==========================================================

  if (isLocationRequired() &&
      selectedLocationIds.isEmpty) {
    showMessage(
      "Please select at least one location",
    );
    return;
  }

  try {
    setState(() {
      isLoading = true;
    });

    // ========================================================
    // GPS LOCATION
    // ========================================================

    double? loginLat;
    double? loginLng;

    if (selectedRole == "Security") {
      try {
        final Position position =
            await LocationService.getCurrentLocation();

        loginLat = position.latitude;
        loginLng = position.longitude;

        debugPrint(
          "LOGIN LATITUDE: $loginLat",
        );

        debugPrint(
          "LOGIN LONGITUDE: $loginLng",
        );

        debugPrint(
          "GPS ACCURACY: ${position.accuracy}",
        );
      } catch (e) {
        debugPrint(
          "LOCATION ERROR: $e",
        );

        if (mounted) {
          showMessage(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          );
        }

        return;
      }
    }

    // ========================================================
    // LOGIN API
    // ========================================================

    debugPrint(
      "======================================",
    );

    debugPrint(
      "LOGIN API START",
    );

    debugPrint(
      "EMAIL: ${emailController.text.trim()}",
    );

    debugPrint(
      "ROLE ID: $selectedRoleId",
    );

    debugPrint(
      "ROLE: $selectedRole",
    );

    debugPrint(
      "STATE IDS: $selectedStateIds",
    );

    debugPrint(
      "CITY IDS: $selectedLocationIds",
    );

    debugPrint(
      "LAT: $loginLat",
    );

    debugPrint(
      "LNG: $loginLng",
    );

    debugPrint(
      "======================================",
    );

    final data = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
      selectedRoleId!,
      isStateRequired()
          ? selectedStateIds
          : [],
      isLocationRequired()
          ? selectedLocationIds
          : [],
      loginLat,
      loginLng,
    );

    // ========================================================
    // LOGIN RESPONSE
    // ========================================================

    debugPrint(
      "======================================",
    );

    debugPrint(
      "LOGIN RESPONSE",
    );

    debugPrint(
      "$data",
    );

    debugPrint(
      "======================================",
    );

    // ========================================================
    // TOKEN
    // ========================================================

    final dynamic token =
        data["token"];

    // ========================================================
    // SUCCESS
    // ========================================================

    final bool success =
        data["success"] == true;

    // ========================================================
    // MESSAGE
    // ========================================================

    final String message =
        data["message"]?.toString() ?? "";

    // ========================================================
    // USER
    // ========================================================

    if (data["user"] == null) {
      throw Exception(
        "User data not found in login response",
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(
      data["user"],
    );

    // ========================================================
    // TOKEN CHECK
    // ========================================================

    if (token == null ||
        token.toString().trim().isEmpty) {
      throw Exception(
        "Token not found in login response",
      );
    }

    // ========================================================
    // USER DATA
    // ========================================================

    final int userId =
        int.tryParse(
              user["UserId"]?.toString() ?? "",
            ) ??
            0;

    final String fullName =
        user["FullName"]?.toString() ?? "";

    final String email =
        user["Email"]?.toString() ?? "";

    final String phone =
        user["Phone"]?.toString() ?? "";

    final int roleId =
        int.tryParse(
              user["RoleId"]?.toString() ?? "",
            ) ??
            0;

    final int branchId =
        int.tryParse(
              user["BranchId"]?.toString() ?? "",
            ) ??
            0;

    // ========================================================
    // IMPORTANT
    // API RESPONSE:
    //
    // "RoleName": "CorporateAdmin"
    // ========================================================

    final String roleName =
        user["RoleName"]?.toString().trim() ?? "";

    // ========================================================
    // OTHER USER DATA
    // ========================================================

    final bool isActive =
        user["IsActive"] == true;

    final String lastLoginAt =
        user["LastLoginAt"]?.toString() ?? "";

    final String createdAt =
        user["CreatedAt"]?.toString() ?? "";

    final String stateName =
        user["StateName"]?.toString() ?? "";

    final String cityName =
        user["CityName"]?.toString() ?? "";

    final String geoLat =
        user["GeoLat"]?.toString() ?? "";

    final String geoLng =
        user["GeoLng"]?.toString() ?? "";

    final int? geoRadius =
        user["GeoRadiusMeters"] == null
            ? null
            : int.tryParse(
                user["GeoRadiusMeters"].toString(),
              );

    // ========================================================
    // ROLE CHECK
    // ========================================================

    if (roleName.isEmpty) {
      throw Exception(
        "RoleName not found in login response",
      );
    }

    // ========================================================
    // SHARED PREFERENCES
    // ========================================================

    final prefs =
        await SharedPreferences.getInstance();

    // ========================================================
    // AUTH DATA
    // ========================================================

    await prefs.setString(
      "token",
      token.toString(),
    );

    await prefs.setBool(
      "isLogin",
      true,
    );

    await prefs.setBool(
      "loginSuccess",
      success,
    );

    await prefs.setString(
      "loginMessage",
      message,
    );

    // ========================================================
    // USER DATA
    // ========================================================

    await prefs.setInt(
      "userId",
      userId,
    );

    await prefs.setString(
      "fullName",
      fullName,
    );

    await prefs.setString(
      "email",
      email,
    );

    await prefs.setString(
      "phone",
      phone,
    );

    // ========================================================
    // ROLE
    // ========================================================

    await prefs.setInt(
      "roleId",
      roleId,
    );

    // IMPORTANT:
    // Save BOTH keys for compatibility

    await prefs.setString(
      "roleName",
      roleName,
    );

    await prefs.setString(
      "role",
      roleName,
    );

    // ========================================================
    // BRANCH
    // ========================================================

    await prefs.setInt(
      "branchId",
      branchId,
    );

    // ========================================================
    // ACTIVE
    // ========================================================

    await prefs.setBool(
      "isActive",
      isActive,
    );

    // ========================================================
    // DATE/TIME
    // ========================================================

    await prefs.setString(
      "lastLoginAt",
      lastLoginAt,
    );

    await prefs.setString(
      "createdAt",
      createdAt,
    );

    // ========================================================
    // STATE / CITY
    // ========================================================

    if (user["StateId"] != null) {
      await prefs.setInt(
        "stateId",
        int.tryParse(
              user["StateId"].toString(),
            ) ??
            0,
      );
    } else {
      await prefs.remove("stateId");
    }

    if (user["CityId"] != null) {
      await prefs.setInt(
        "cityId",
        int.tryParse(
              user["CityId"].toString(),
            ) ??
            0,
      );
    } else {
      await prefs.remove("cityId");
    }

    await prefs.setString(
      "stateName",
      stateName,
    );

    await prefs.setString(
      "cityName",
      cityName,
    );

    // ========================================================
    // GEO LOCATION
    // ========================================================

    await prefs.setString(
      "GeoLat",
      geoLat,
    );

    await prefs.setString(
      "GeoLng",
      geoLng,
    );

    if (geoRadius != null) {
      await prefs.setInt(
        "GeoRadiusMeters",
        geoRadius,
      );
    } else {
      await prefs.remove(
        "GeoRadiusMeters",
      );
    }

    // ========================================================
    // SELECTED STATES
    // ========================================================

    await prefs.setString(
      "stateIds",
      selectedStateIds.join(","),
    );

    await prefs.setString(
      "stateNames",
      selectedStateNames.join(","),
    );

    // ========================================================
    // SELECTED CITIES
    // ========================================================

    await prefs.setString(
      "cityIds",
      selectedLocationIds.join(","),
    );

    await prefs.setString(
      "cityNames",
      selectedLocationNames.join(","),
    );

    // ========================================================
    // FIRST STATE
    // ========================================================

    if (selectedStateIds.isNotEmpty) {
      await prefs.setInt(
        "selectedStateId",
        selectedStateIds.first,
      );
    } else {
      await prefs.remove(
        "selectedStateId",
      );
    }

    // ========================================================
    // FIRST CITY
    // ========================================================

    if (selectedLocationIds.isNotEmpty) {
      await prefs.setInt(
        "selectedCityId",
        selectedLocationIds.first,
      );
    } else {
      await prefs.remove(
        "selectedCityId",
      );
    }

    // ========================================================
    // DEBUG - VERIFY SAVED DATA
    // ========================================================

    debugPrint(
      "======================================",
    );

    debugPrint(
      "SHARED PREFERENCES AFTER LOGIN",
    );

    debugPrint(
      "======================================",
    );

    debugPrint(
      "TOKEN EXISTS: "
      "${(prefs.getString("token") ?? "").isNotEmpty}",
    );

    debugPrint(
      "IS LOGIN: "
      "${prefs.getBool("isLogin")}",
    );

    debugPrint(
      "USER ID: "
      "${prefs.getInt("userId")}",
    );

    debugPrint(
      "ROLE ID: "
      "${prefs.getInt("roleId")}",
    );

    debugPrint(
      "ROLE NAME: "
      "${prefs.getString("roleName")}",
    );

    debugPrint(
      "ROLE: "
      "${prefs.getString("role")}",
    );

    debugPrint(
      "BRANCH ID: "
      "${prefs.getInt("branchId")}",
    );

    debugPrint(
      "======================================",
    );

    // ========================================================
    // NAVIGATION
    // ========================================================

    if (!mounted) return;

    switch (roleName) {

      case "CorporateAdmin":

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CorporateAdminHomeScreen(),
          ),
          (route) => false,
        );

        break;

      case "BranchAdmin":

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const BranchAdminHomeScreen(),
          ),
          (route) => false,
        );

        break;

      case "Driver":

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DriverHomeScreen(),
          ),
          (route) => false,
        );

        break;

      case "Security":

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SecurityHomeScreen(),
          ),
          (route) => false,
        );

        break;

      case "Accounts":

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AccountsHomeScreen(),
          ),
          (route) => false,
        );

        break;

      case "StateAdmin":

        showMessage(
          "StateAdmin login successful",
        );

        break;

      default:

        showMessage(
          "Invalid Role: $roleName",
        );
    }

  } catch (e) {

    debugPrint(
      "LOGIN ERROR: $e",
    );

    if (mounted) {
      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }

  } finally {

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  // ============================================================
  // SNACKBAR
  // ============================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(
          seconds: 4,
        ),
      ),
    );
  }

  // ============================================================
  // STATE UI
  // ============================================================

  Widget buildStateSelection() {
    if (!isStateRequired()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),

        const Text(
          "SELECT STATE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade400,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: isLoadingStates
              ? const Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              : states.isEmpty
                  ? const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Text(
                        "No states available",
                      ),
                    )
                  : Column(
                      children: [
                        // SELECT ALL
                        CheckboxListTile(
                          value:
                              selectedStateIds
                                      .length ==
                                  states.length &&
                              states.isNotEmpty,

                          title: const Text(
                            "Select All States",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          activeColor:
                              const Color(
                            0xff2458A6,
                          ),

                          onChanged:
                              (bool? value) {
                            if (value ==
                                true) {
                              selectAllStates();
                            } else {
                              clearAllStates();
                            }
                          },
                        ),

                        const Divider(
                          height: 1,
                        ),

                        // STATES
                        ...states.map(
                          (state) {
                            final int? stateId =
                                int.tryParse(
                              state["StateId"]
                                  .toString(),
                            );

                            final String
                                stateName =
                                state["StateName"]
                                        ?.toString() ??
                                    state["Name"]
                                        ?.toString() ??
                                    "";

                            if (stateId ==
                                null) {
                              return const SizedBox
                                  .shrink();
                            }

                            return CheckboxListTile(
                              value:
                                  selectedStateIds
                                      .contains(
                                stateId,
                              ),

                              title: Text(
                                stateName,
                              ),

                              secondary:
                                  const Icon(
                                Icons
                                    .map_outlined,
                              ),

                              activeColor:
                                  const Color(
                                0xff2458A6,
                              ),

                              onChanged:
                                  (bool? value) {
                                onStateSelected(
                                  stateId,
                                  stateName,
                                  value ??
                                      false,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
        ),

        if (selectedStateNames
            .isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 8,
            ),
            child: Text(
              "Selected: ${selectedStateNames.join(", ")}",
              style: const TextStyle(
                color:
                    Color(0xff2458A6),
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LOCATION UI
  // ============================================================

  Widget buildLocationSelection() {
    if (!isLocationRequired()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          "SELECT LOCATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade400,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: selectedStateIds.isEmpty
              ? const Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Text(
                    "First select at least one state",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              : isLoadingLocations
                  ? const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  : locations.isEmpty
                      ? const Padding(
                          padding:
                              EdgeInsets.all(20),
                          child: Text(
                            "No locations available",
                          ),
                        )
                      : Column(
                          children: [
                            // SELECT ALL
                            CheckboxListTile(
                              value:
                                  selectedLocationIds
                                          .length ==
                                      locations
                                          .length &&
                                  locations
                                      .isNotEmpty,

                              title:
                                  const Text(
                                "Select All Locations",
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              activeColor:
                                  const Color(
                                0xff2458A6,
                              ),

                              onChanged:
                                  (bool? value) {
                                if (value ==
                                    true) {
                                  selectAllLocations();
                                } else {
                                  clearAllLocations();
                                }
                              },
                            ),

                            const Divider(
                              height: 1,
                            ),

                            // LOCATIONS
                            ...locations.map(
                              (location) {
                                final int? cityId =
                                    int.tryParse(
                                  location[
                                          "CityId"]
                                      .toString(),
                                );

                                final String
                                    cityName =
                                    location[
                                                "CityName"]
                                            ?.toString() ??
                                        location[
                                                "Name"]
                                            ?.toString() ??
                                        "";

                                if (cityId ==
                                    null) {
                                  return const SizedBox
                                      .shrink();
                                }

                                return CheckboxListTile(
                                  value:
                                      selectedLocationIds
                                          .contains(
                                    cityId,
                                  ),

                                  title: Text(
                                    cityName,
                                  ),

                                  secondary:
                                      const Icon(
                                    Icons
                                        .location_on_outlined,
                                  ),

                                  activeColor:
                                      const Color(
                                    0xff2458A6,
                                  ),

                                  onChanged:
                                      (bool?
                                          value) {
                                    onLocationSelected(
                                      cityId,
                                      cityName,
                                      value ??
                                          false,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
        ),

        if (selectedLocationNames
            .isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 8,
            ),
            child: Text(
              "Selected: ${selectedLocationNames.join(", ")}",
              style: const TextStyle(
                color:
                    Color(0xff2458A6),
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            colors: [
              Color(0xff163D7A),
              Color(0xff2E63B8),
            ],
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    "Demo Vehicle Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Center(
                  child: Text(
                    "Prem Motors Group",
                    style: TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // LOGIN CARD
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ============================================
                      // LOGO
                      // ============================================

                      Center(
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff2458A6)
                                    .withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            "assets/images/logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ============================================
                      // ROLE
                      // ============================================

                      const Text(
                        "SELECT ROLE",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      if (roles.isEmpty)
                        const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<
                            int>(
                          value:
                              selectedRoleId,

                          isExpanded: true,

                          decoration:
                              InputDecoration(
                            hintText:
                                "Select Role",

                            prefixIcon:
                                const Icon(
                              Icons
                                  .person_outline,
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),

                          items: roles
                              .map<
                                  DropdownMenuItem<
                                      int>>(
                            (role) {
                              final int?
                                  roleId =
                                  int.tryParse(
                                role["RoleId"]
                                    .toString(),
                              );

                              final String
                                  roleName =
                                  role["RoleName"]
                                          ?.toString() ??
                                      "";

                              if (roleId ==
                                  null) {
                                // return null;
                              }

                              return DropdownMenuItem<
                                  int>(
                                value:
                                    roleId,

                                child: Text(
                                  roleName,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        16,
                                  ),
                                ),
                              );
                            },
                          )
                              .whereType<
                                  DropdownMenuItem<
                                      int>>()
                              .toList(),

                          onChanged:
                              (int? value) {
                            if (value ==
                                null) {
                              return;
                            }

                            final selectedRoleData =
                                roles.firstWhere(
                              (role) =>
                                  int.tryParse(
                                    role["RoleId"]
                                        .toString(),
                                  ) ==
                                  value,
                            );

                            final String
                                roleName =
                                selectedRoleData[
                                            "RoleName"]
                                        ?.toString() ??
                                    "";

                            onRoleSelected(
                              roleName,
                              value,
                            );
                          },
                        ),

                      // ============================================
                      // MULTIPLE STATES
                      // ============================================

                      buildStateSelection(),

                      // ============================================
                      // MULTIPLE LOCATIONS
                      // ============================================

                      buildLocationSelection(),

                      // ============================================
                      // EMAIL
                      // ============================================

                      const SizedBox(
                        height: 25,
                      ),

                      const Text(
                        "EMAIL",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextField(
                        controller:
                            emailController,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Enter Email",

                          prefixIcon:
                              const Icon(
                            Icons
                                .email_outlined,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      // ============================================
                      // PASSWORD
                      // ============================================

                      const SizedBox(
                        height: 20,
                      ),

                      const Text(
                        "PASSWORD",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextField(
                        controller:
                            passwordController,

                        obscureText:
                            obscurePassword,

                        decoration:
                            InputDecoration(
                          hintText:
                              "Enter Password",

                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          suffixIcon:
                              IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                            ),

                            onPressed: () {
                              setState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      // ============================================
                      // LOGIN BUTTON
                      // ============================================

                      const SizedBox(
                        height: 30,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 55,

                        child:
                            ElevatedButton(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xff2458A6,
                            ),

                            disabledBackgroundColor:
                                Colors.grey,

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
                              isLoading
                                  ? null
                                  : login,

                          child:
                              isLoading
                                  ? const SizedBox(
                                      width: 25,
                                      height: 25,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth:
                                            3,
                                      ),
                                    )
                                  : const Text(
                                      "Sign In",
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                        ),
                      ),
                    ],
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