import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController gateLocationController = TextEditingController();

  final TextEditingController assignedLocationController =
      TextEditingController();

  final TextEditingController latitudeController = TextEditingController();

  final TextEditingController longitudeController = TextEditingController();

  final TextEditingController radiusController = TextEditingController(
    text: "500",
  );

  final TextEditingController stateSearchController = TextEditingController();

  final TextEditingController locationSearchController =
      TextEditingController();

  // ============================================================
  // LOADING
  // ============================================================

  bool isLoadingRoles = false;
  bool isLoadingStates = false;
  bool isLoadingLocations = false;
  bool isSaving = false;

  // ============================================================
  // PASSWORD
  // ============================================================

  bool obscurePassword = true;

  // ============================================================
  // USER STATUS
  // false = Active
  // true  = Locked
  // ============================================================

  bool isUserLocked = false;

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
  // LOCATIONS
  // ============================================================

  List<dynamic> locations = [];

  List<int> selectedLocationIds = [];
  List<String> selectedLocationNames = [];

  // ============================================================
  // CURRENT LOGIN USER ROLE
  // ============================================================

  String currentUserRole = "";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadCurrentUserRole();
    loadRoles();
    loadStates();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    gateLocationController.dispose();
    assignedLocationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
    stateSearchController.dispose();
    locationSearchController.dispose();

    super.dispose();
  }

  // ============================================================
  // CURRENT USER ROLE
  // ============================================================

  Future<void> loadCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString("roleName") ?? prefs.getString("role") ?? "";

    if (!mounted) return;

    setState(() {
      currentUserRole = role.trim();
    });

    debugPrint("CURRENT USER ROLE: $currentUserRole");
  }

  // ============================================================
  // ROLE RULES
  // SAME LOGIC AS LOGIN SCREEN
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
      setState(() {
        isLoadingRoles = true;
      });

      final data = await _authService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = data["data"] ?? [];
        isLoadingRoles = false;
      });

      debugPrint("ADD USER ROLES: $roles");
    } catch (e) {
      debugPrint("ADD USER ROLE ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoadingRoles = false;
        roles = [];
      });

      showMessage("Unable to load roles\n$e", isError: true);
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

      debugPrint("ADD USER STATES: $states");
    } catch (e) {
      debugPrint("ADD USER STATE ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoadingStates = false;
        states = [];
      });

      showMessage("Unable to load states\n$e", isError: true);
    }
  }

  // ============================================================
  // LOAD LOCATIONS FOR SELECTED STATES
  // ============================================================

  Future<void> loadLocationsForSelectedStates() async {
    if (selectedStateIds.isEmpty) {
      if (!mounted) return;

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

      // --------------------------------------------------------
      // API CALL FOR EVERY SELECTED STATE
      // --------------------------------------------------------

      for (final stateId in selectedStateIds) {
        try {
          final data = await _authService.getLocations(stateId);

          final cityData = data["data"] ?? [];

          if (cityData is List) {
            allLocations.addAll(cityData);
          }
        } catch (e) {
          debugPrint("Location error for StateId $stateId: $e");
        }
      }

      // --------------------------------------------------------
      // REMOVE DUPLICATE CITY IDS
      // --------------------------------------------------------

      final Map<int, dynamic> uniqueCities = {};

      for (final city in allLocations) {
        final cityId = int.tryParse(city["CityId"].toString());

        if (cityId != null) {
          uniqueCities[cityId] = city;
        }
      }

      if (!mounted) return;

      setState(() {
        locations = uniqueCities.values.toList();

        // State change ke baad location selection reset
        selectedLocationIds.clear();
        selectedLocationNames.clear();

        isLoadingLocations = false;
      });

      debugPrint("ADD USER LOCATIONS: $locations");
    } catch (e) {
      debugPrint("ADD USER LOCATION ERROR: $e");

      if (!mounted) return;

      setState(() {
        locations = [];
        isLoadingLocations = false;
      });

      showMessage("Unable to load locations\n$e", isError: true);
    }
  }

  // ============================================================
  // ROLE SELECT
  // ============================================================

  void onRoleSelected(String roleName, int roleId) {
    setState(() {
      selectedRole = roleName;
      selectedRoleId = roleId;

      // Role change hone par State/Location reset
      selectedStateIds.clear();
      selectedStateNames.clear();

      selectedLocationIds.clear();
      selectedLocationNames.clear();

      locations.clear();
    });

    debugPrint("SELECTED ROLE: $selectedRole");
    debugPrint("SELECTED ROLE ID: $selectedRoleId");
  }

  // ============================================================
  // STATE SELECT
  // ============================================================

  void onStateSelected(int stateId, String stateName, bool selected) {
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

      // State selection change = Location reset
      selectedLocationIds.clear();
      selectedLocationNames.clear();
    });

    debugPrint("SELECTED STATE IDS: $selectedStateIds");

    loadLocationsForSelectedStates();
  }

  // ============================================================
  // LOCATION SELECT
  // ============================================================

  void onLocationSelected(int cityId, String cityName, bool selected) {
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

    debugPrint("SELECTED LOCATION IDS: $selectedLocationIds");
  }

  // ============================================================
  // SELECT ALL STATES
  // ============================================================

  void selectAllStates() {
    setState(() {
      selectedStateIds.clear();
      selectedStateNames.clear();

      for (final state in states) {
        final int? stateId = int.tryParse(state["StateId"].toString());

        final String stateName =
            state["StateName"]?.toString() ?? state["Name"]?.toString() ?? "";

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

  // ============================================================
  // CLEAR ALL STATES
  // ============================================================

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
  // SELECT ALL LOCATIONS
  // ============================================================

  void selectAllLocations() {
    setState(() {
      selectedLocationIds.clear();
      selectedLocationNames.clear();

      for (final location in locations) {
        final int? cityId = int.tryParse(location["CityId"].toString());

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

  // ============================================================
  // CLEAR ALL LOCATIONS
  // ============================================================

  void clearAllLocations() {
    setState(() {
      selectedLocationIds.clear();
      selectedLocationNames.clear();
    });
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> openGoogleMaps() async {
    final lat = double.tryParse(latitudeController.text.trim());

    final lng = double.tryParse(longitudeController.text.trim());

    Uri url;

    if (lat != null && lng != null) {
      url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
    } else if (gateLocationController.text.trim().isNotEmpty) {
      final query = Uri.encodeComponent(gateLocationController.text.trim());

      url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    } else {
      url = Uri.parse("https://www.google.com/maps");
    }

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // OPEN STREET MAP
  // ============================================================

  Future<void> openOpenStreetMap() async {
    final lat = double.tryParse(latitudeController.text.trim());

    final lng = double.tryParse(longitudeController.text.trim());

    Uri url;

    if (lat != null && lng != null) {
      url = Uri.parse(
        "https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng",
      );
    } else {
      url = Uri.parse("https://www.openstreetmap.org/");
    }

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  bool validateForm() {
    if (nameController.text.trim().isEmpty) {
      showMessage("Please enter Full Name", isError: true);
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage("Please enter Email", isError: true);
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage("Please enter Phone", isError: true);
      return false;
    }

    if (selectedRoleId == null) {
      showMessage("Please select Role", isError: true);
      return false;
    }

    // Same LoginScreen rule
    if (isStateRequired() && selectedStateIds.isEmpty) {
      showMessage("Please select at least one State", isError: true);
      return false;
    }

    // Same LoginScreen rule
    if (isLocationRequired() && selectedLocationIds.isEmpty) {
      showMessage("Please select at least one Location", isError: true);
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      showMessage("Please enter Temporary Password", isError: true);
      return false;
    }

    return true;
  }

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<void> saveUser() async {
    if (!validateForm()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // CREATE USER DATA
      // ========================================================

      final Map<String, dynamic> userData = {
        "FullName": nameController.text.trim(),

        "Email": emailController.text.trim(),

        "Phone": phoneController.text.trim(),

        "RoleId": selectedRoleId,

        "RoleName": selectedRole,

        "StateIds": isStateRequired() ? selectedStateIds : <int>[],

        "StateNames": isStateRequired() ? selectedStateNames : <String>[],

        "CityIds": isLocationRequired() ? selectedLocationIds : <int>[],

        "CityNames": isLocationRequired() ? selectedLocationNames : <String>[],

        "TemporaryPassword": passwordController.text.trim(),

        "GateLocation": gateLocationController.text.trim(),

        "AssignedLocation": assignedLocationController.text.trim(),

        "Latitude": double.tryParse(latitudeController.text.trim()),

        "Longitude": double.tryParse(longitudeController.text.trim()),

        "AllowedRadius": int.tryParse(radiusController.text.trim()) ?? 500,

        // false = Active
        // true = Locked
        "IsLocked": isUserLocked,

        // Convenience field
        "Status": isUserLocked ? "Locked" : "Active",
      };

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint("======================================");

      debugPrint("CREATE USER DATA");

      debugPrint("$userData");

      debugPrint("======================================");

      // ========================================================
      // TODO:
      // ACTUAL CREATE USER API
      //
      // Example:
      //
      // final response =
      //     await _authService.createUser(userData);
      //
      // Exact method depends on your AuthService.
      // ========================================================

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage("User data ready for API", isError: false);

      // Parent UsersScreen ko data return
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context, userData);
    } catch (e) {
      debugPrint("CREATE USER ERROR: $e");

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xff16a34a),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xff94a3b8)),

            prefixIcon: prefixIcon,

            suffixIcon: suffixIcon,

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xff2161b5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROLE DROPDOWN
  // ============================================================

  Widget buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Role",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),

        const SizedBox(height: 7),

        isLoadingRoles
            ? Container(
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xffdbe3ef)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CircularProgressIndicator(),
              )
            : DropdownButtonFormField<int>(
                value: selectedRoleId,
                isExpanded: true,

                decoration: InputDecoration(
                  hintText: "Select Role",
                  prefixIcon: const Icon(Icons.person_outline),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffdbe3ef)),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffdbe3ef)),
                  ),
                ),

                items: roles
                    .map<DropdownMenuItem<int>>((role) {
                      final int? roleId = int.tryParse(
                        role["RoleId"].toString(),
                      );

                      final String roleName =
                          role["RoleName"]?.toString() ?? "";

                      if (roleId == null) {
                        // return null;
                      }

                      return DropdownMenuItem<int>(
                        value: roleId,
                        child: Text(roleName, overflow: TextOverflow.ellipsis),
                      );
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList(),

                onChanged: (int? value) {
                  if (value == null) {
                    return;
                  }

                  final role = roles.firstWhere(
                    (role) => int.tryParse(role["RoleId"].toString()) == value,
                  );

                  final roleName = role["RoleName"]?.toString() ?? "";

                  onRoleSelected(roleName, value);
                },
              ),
      ],
    );
  }

  // ============================================================
  // STATE SELECTION
  // ============================================================

  Widget buildStateSelection() {
    if (!isStateRequired()) {
      return const SizedBox.shrink();
    }

    final search = stateSearchController.text.trim().toLowerCase();

    final filteredStates = states.where((state) {
      final name =
          state["StateName"]?.toString() ?? state["Name"]?.toString() ?? "";

      return name.toLowerCase().contains(search);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          "State",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: stateSearchController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Search state...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: stateSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      stateSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffdbe3ef)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoadingStates
              ? const Center(child: CircularProgressIndicator())
              : states.isEmpty
              ? const Center(child: Text("No states available"))
              : Column(
                  children: [
                    CheckboxListTile(
                      value:
                          selectedStateIds.length == states.length &&
                          states.isNotEmpty,
                      title: const Text(
                        "Select All States",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      activeColor: const Color(0xff2161b5),
                      onChanged: (value) {
                        if (value == true) {
                          selectAllStates();
                        } else {
                          clearAllStates();
                        }
                      },
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredStates.length,
                        itemBuilder: (context, index) {
                          final state = filteredStates[index];

                          final int? stateId = int.tryParse(
                            state["StateId"].toString(),
                          );

                          final String stateName =
                              state["StateName"]?.toString() ??
                              state["Name"]?.toString() ??
                              "";

                          if (stateId == null) {
                            return const SizedBox.shrink();
                          }

                          return CheckboxListTile(
                            dense: true,
                            value: selectedStateIds.contains(stateId),
                            title: Text(stateName),
                            secondary: const Icon(Icons.map_outlined),
                            activeColor: const Color(0xff2161b5),
                            onChanged: (value) {
                              onStateSelected(
                                stateId,
                                stateName,
                                value ?? false,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),

        if (selectedStateNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Selected: ${selectedStateNames.join(", ")}",
              style: const TextStyle(
                color: Color(0xff2161b5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LOCATION SELECTION
  // ============================================================

  Widget buildLocationSelection() {
    if (!isLocationRequired()) {
      return const SizedBox.shrink();
    }

    final search = locationSearchController.text.trim().toLowerCase();

    final filteredLocations = locations.where((location) {
      final name =
          location["CityName"]?.toString() ??
          location["Name"]?.toString() ??
          "";

      return name.toLowerCase().contains(search);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          "Locations",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: locationSearchController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Search location...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: locationSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      locationSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffdbe3ef)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: selectedStateIds.isEmpty
              ? const Center(
                  child: Text(
                    "First select at least one State",
                    style: TextStyle(color: Color(0xff94a3b8)),
                  ),
                )
              : isLoadingLocations
              ? const Center(child: CircularProgressIndicator())
              : locations.isEmpty
              ? const Center(child: Text("No locations available"))
              : Column(
                  children: [
                    CheckboxListTile(
                      value:
                          selectedLocationIds.length == locations.length &&
                          locations.isNotEmpty,
                      title: const Text(
                        "Select All Locations",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      activeColor: const Color(0xff2161b5),
                      onChanged: (value) {
                        if (value == true) {
                          selectAllLocations();
                        } else {
                          clearAllLocations();
                        }
                      },
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          final location = filteredLocations[index];

                          final int? cityId = int.tryParse(
                            location["CityId"].toString(),
                          );

                          final String cityName =
                              location["CityName"]?.toString() ??
                              location["Name"]?.toString() ??
                              "";

                          if (cityId == null) {
                            return const SizedBox.shrink();
                          }

                          return CheckboxListTile(
                            dense: true,
                            value: selectedLocationIds.contains(cityId),
                            title: Text(
                              cityName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            secondary: const Icon(Icons.location_on_outlined),
                            activeColor: const Color(0xff2161b5),
                            onChanged: (value) {
                              onLocationSelected(
                                cityId,
                                cityName,
                                value ?? false,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),

        if (selectedLocationNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Selected: ${selectedLocationNames.join(", ")}",
              style: const TextStyle(
                color: Color(0xff2161b5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LOCK CARD
  // ============================================================

  Widget buildUserStatusCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUserLocked ? const Color(0xfffff7ed) : const Color(0xfff0fdf4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUserLocked
              ? const Color(0xfffed7aa)
              : const Color(0xffbbf7d0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isUserLocked
                  ? const Color(0xffffedd5)
                  : const Color(0xffdcfce7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUserLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isUserLocked
                  ? const Color(0xffea580c)
                  : const Color(0xff16a34a),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUserLocked ? "User Locked" : "User Active",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff334155),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isUserLocked
                      ? "User will not be allowed to login."
                      : "User can login normally.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: isUserLocked,
            activeColor: const Color(0xffea580c),
            onChanged: (value) {
              setState(() {
                isUserLocked = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP SECTION
  // ============================================================

  Widget buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gate Location",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),

        const SizedBox(height: 7),

        buildTextField(
          label: "",
          controller: gateLocationController,
          hint: "Search address / place...",
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: openGoogleMaps,
                icon: const Icon(Icons.map, size: 18),
                label: const Text("Google Maps"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2161b5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: openOpenStreetMap,
                icon: const Icon(Icons.public, size: 18),
                label: const Text("OpenStreetMap"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff475569),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xffdbe3ef)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // MAP PLACEHOLDER
        // --------------------------------------------------------
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xffe2e8f0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffcbd5e1)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_on, color: Color(0xffdc2626), size: 55),

              Positioned(
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Enter Latitude & Longitude",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildTextField(
                label: "Latitude",
                controller: latitudeController,
                hint: "26.9124",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: buildTextField(
                label: "Longitude",
                controller: longitudeController,
                hint: "75.7873",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        buildTextField(
          label: "Allowed Radius (metres)",
          controller: radiusController,
          hint: "500",
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 7),

        const Text(
          "A Security user can only sign in within this radius of the pin.",
          style: TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0f172a),
        elevation: 0,

        title: const Text(
          "Add User",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff94a3b8)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // FULL NAME
                  // ==================================================
                  buildTextField(
                    label: "Full Name",
                    controller: nameController,
                    hint: "Enter full name",
                    prefixIcon: const Icon(Icons.person_outline),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // EMAIL + PHONE
                  // ==================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildTextField(
                          label: "Email",
                          controller: emailController,
                          hint: "Enter email",
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: buildTextField(
                          label: "Phone",
                          controller: phoneController,
                          hint: "Enter phone",
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // ROLE
                  // ==================================================
                  const SizedBox(height: 20),

                  buildRoleDropdown(),

                  // ==================================================
                  // STATE
                  // ==================================================
                  buildStateSelection(),

                  // ==================================================
                  // LOCATION
                  // ==================================================
                  buildLocationSelection(),

                  // ==================================================
                  // PASSWORD
                  // ==================================================
                  const SizedBox(height: 20),

                  buildTextField(
                    label: "Temporary Password",
                    controller: passwordController,
                    hint: "Enter temporary password",
                    obscureText: obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),

                  // ==================================================
                  // ASSIGNED LOCATION
                  // ==================================================
                  const SizedBox(height: 20),

                  buildTextField(
                    label: "Assigned Location (From/To for gate movements)",
                    controller: assignedLocationController,
                    hint: "Type to search...",
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),

                  // ==================================================
                  // MAP
                  // ==================================================
                  const SizedBox(height: 22),

                  buildMapSection(),

                  // ==================================================
                  // STATUS
                  // ==================================================
                  const SizedBox(height: 24),

                  const Text(
                    "User Status",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff475569),
                    ),
                  ),

                  const SizedBox(height: 8),

                  buildUserStatusCard(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // ========================================================
          // BOTTOM BUTTONS
          // ========================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe2e8f0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff475569),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    side: const BorderSide(color: Color(0xffdbe3ef)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: isSaving ? null : saveUser,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    isSaving ? "Saving..." : "Save",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2161b5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
