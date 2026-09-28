import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

class FastagScreen extends StatefulWidget {
  const FastagScreen({super.key});

  @override
  State<FastagScreen> createState() => _FastagScreenState();
}

class _FastagScreenState extends State<FastagScreen> {
  // =========================================================
  // SERVICES
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // SEARCH
  // =========================================================

  final TextEditingController searchController =
      TextEditingController();

  // =========================================================
  // ADD FASTAG CONTROLLERS
  // =========================================================

  final TextEditingController providerController =
      TextEditingController();

  final TextEditingController tagNumberController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController balanceController =
      TextEditingController();

  final TextEditingController tollPlazaController =
      TextEditingController();

  // =========================================================
  // FASTAG DATA
  // =========================================================

  List<dynamic> allFastag = [];
  List<dynamic> filteredFastag = [];

  // =========================================================
  // VEHICLES
  // =========================================================

  List<dynamic> vehicles = [];

  String? selectedVehicle;

  // =========================================================
  // FASTAG TYPE
  // =========================================================

  String selectedType = "Recharge";

  // =========================================================
  // ROLE
  // =========================================================

  String userRole = "";

  // =========================================================
  // LOADING
  // =========================================================

  bool isLoading = false;

  bool isSaving = false;

  String? errorMessage;

  // =========================================================
  // DATE FILTER
  // =========================================================

  DateTime? fromDate;

  DateTime? toDate;

  // =========================================================
  // CAN ADD FASTAG
  // =========================================================

  bool get canAddFastag {
    final role = userRole
        .trim()
        .toLowerCase()
        .replaceAll(" ", "");

    return role == "corporateadmin" ||
        role == "stateadmin";
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadUserRole();

    loadFastag();

    searchController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD USER ROLE
  // =========================================================

  Future<void> loadUserRole() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      String role =
          prefs.getString("rolename") ?? "";

      // Backup keys
      if (role.isEmpty) {
        role =
            prefs.getString("RoleName") ?? "";
      }

      if (role.isEmpty) {
        role =
            prefs.getString("roleName") ?? "";
      }

      if (role.isEmpty) {
        role =
            prefs.getString("Role") ?? "";
      }

      if (role.isEmpty) {
        role =
            prefs.getString("role") ?? "";
      }

      if (!mounted) return;

      setState(() {
        userRole = role;
      });

      debugPrint(
        "FASTAG USER ROLE: $userRole",
      );

      debugPrint(
        "CAN ADD FASTAG: $canAddFastag",
      );
    } catch (e) {
      debugPrint(
        "Role load error: $e",
      );
    }
  }

  // =========================================================
  // LOAD FASTAG
  // =========================================================

  Future<void> loadFastag() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await _authService.getfastag();

      if (!mounted) return;

      setState(() {
        allFastag =
            List<dynamic>.from(result);

        filteredFastag =
            List<dynamic>.from(result);

        isLoading = false;
      });

      applyFilters();

      debugPrint(
        "FASTAG RECORDS: ${result.length}",
      );

      debugPrint(
        "FASTAG RESPONSE: $result",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();

        allFastag = [];
        filteredFastag = [];
      });

      debugPrint(
        "Fastag API Error: $e",
      );
    }
  }

  // =========================================================
  // ADD FASTAG DIALOG
  // =========================================================

  void addFastag() {
    if (!canAddFastag) {
      return;
    }

    // Reset form
    selectedVehicle = null;
    selectedType = "Recharge";

    providerController.clear();
    tagNumberController.clear();
    amountController.clear();
    balanceController.clear();
    tollPlazaController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor:
                  Colors.white,

              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(0),
              ),

              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 600,
                ),

                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [

                      // =================================================
                      // HEADER
                      // =================================================

                      Container(
                        width: double.infinity,

                        padding:
                            const EdgeInsets.fromLTRB(
                          14,
                          12,
                          8,
                          12,
                        ),

                        decoration:
                            const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(
                              color:
                                  Color(
                                0xffe2e8f0,
                              ),
                            ),
                          ),
                        ),

                        child: Row(
                          children: [

                            const Expanded(
                              child: Text(
                                "Add FASTag Transaction",
                                style:
                                    TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(
                                    0xff1e293b,
                                  ),
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip:
                                  "Close",

                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },

                              icon:
                                  const Icon(
                                Icons.close,
                                size: 24,
                                color:
                                    Color(
                                  0xff94a3b8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =================================================
                      // FORM
                      // =================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          8,
                          22,
                          8,
                          22,
                        ),

                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            // =========================================
                            // VEHICLE
                            // =========================================

                            buildFieldLabel(
                              "Vehicle",
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            buildVehicleDropdown(
                              setDialogState,
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =========================================
                            // PROVIDER + TAG
                            // =========================================

                            LayoutBuilder(
                              builder: (
                                context,
                                constraints,
                              ) {
                                if (constraints
                                        .maxWidth <
                                    500) {
                                  return Column(
                                    children: [

                                      buildFastagField(
                                        label:
                                            "Provider",
                                        hint:
                                            "ICICI / Paytm ...",
                                        controller:
                                            providerController,
                                      ),

                                      const SizedBox(
                                        height: 18,
                                      ),

                                      buildFastagField(
                                        label:
                                            "Tag Number",
                                        hint: "",
                                        controller:
                                            tagNumberController,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Expanded(
                                      child:
                                          buildFastagField(
                                        label:
                                            "Provider",
                                        hint:
                                            "ICICI / Paytm ...",
                                        controller:
                                            providerController,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 16,
                                    ),

                                    Expanded(
                                      child:
                                          buildFastagField(
                                        label:
                                            "Tag Number",
                                        hint: "",
                                        controller:
                                            tagNumberController,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =========================================
                            // TYPE + AMOUNT
                            // =========================================

                            LayoutBuilder(
                              builder: (
                                context,
                                constraints,
                              ) {
                                if (constraints
                                        .maxWidth <
                                    500) {
                                  return Column(
                                    children: [

                                      buildTypeDropdown(
                                        setDialogState,
                                      ),

                                      const SizedBox(
                                        height: 18,
                                      ),

                                      buildFastagField(
                                        label:
                                            "Amount (₹)",
                                        hint: "",
                                        controller:
                                            amountController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal:
                                              true,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Expanded(
                                      child:
                                          buildTypeDropdown(
                                        setDialogState,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 16,
                                    ),

                                    Expanded(
                                      child:
                                          buildFastagField(
                                        label:
                                            "Amount (₹)",
                                        hint: "",
                                        controller:
                                            amountController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal:
                                              true,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =========================================
                            // BALANCE + TOLL PLAZA
                            // =========================================

                            LayoutBuilder(
                              builder: (
                                context,
                                constraints,
                              ) {
                                if (constraints
                                        .maxWidth <
                                    500) {
                                  return Column(
                                    children: [

                                      buildFastagField(
                                        label:
                                            "Balance After (₹)",
                                        hint: "",
                                        controller:
                                            balanceController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal:
                                              true,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 18,
                                      ),

                                      buildFastagField(
                                        label:
                                            "Toll Plaza",
                                        hint: "",
                                        controller:
                                            tollPlazaController,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Expanded(
                                      child:
                                          buildFastagField(
                                        label:
                                            "Balance After (₹)",
                                        hint: "",
                                        controller:
                                            balanceController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal:
                                              true,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 16,
                                    ),

                                    Expanded(
                                      child:
                                          buildFastagField(
                                        label:
                                            "Toll Plaza",
                                        hint: "",
                                        controller:
                                            tollPlazaController,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // =================================================
                      // FOOTER
                      // =================================================

                      Container(
                        width: double.infinity,

                        padding:
                            const EdgeInsets.fromLTRB(
                          8,
                          18,
                          8,
                          12,
                        ),

                        decoration:
                            const BoxDecoration(
                          border: Border(
                            top:
                                BorderSide(
                              color:
                                  Color(
                                0xffe2e8f0,
                              ),
                            ),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,

                          children: [

                            // =========================================
                            // CANCEL
                            // =========================================

                            OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        dialogContext,
                                      );
                                    },

                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color(
                                  0xff475569,
                                ),

                                backgroundColor:
                                    Colors.white,

                                side:
                                    const BorderSide(
                                  color:
                                      Color(
                                    0xffdbe2ea,
                                  ),
                                ),

                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),

                              child:
                                  const Text(
                                "Cancel",
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            // =========================================
                            // SAVE
                            // =========================================

                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      saveFastag(
                                        dialogContext,
                                        setDialogState,
                                      );
                                    },

                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xff245db5,
                                ),

                                foregroundColor:
                                    Colors.white,

                                elevation: 0,

                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),

                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Save",
                                      style:
                                          TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w700,
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
            );
          },
        );
      },
    );
  }

  // =========================================================
  // VEHICLE DROPDOWN
  // =========================================================

  Widget buildVehicleDropdown(
    StateSetter setDialogState,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedVehicle,

      isExpanded: true,

      decoration:
          fastagInputDecoration(
        hint:
            "Select Vehicle",
      ),

      items: [

        // Example vehicle.
        // Replace with your API vehicle list
        // when vehicle API response is available.

        const DropdownMenuItem<String>(
          value: "RJ18SS2800",
          child: Text(
            "RJ18SS2800 · HONDA SHINE",
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ],

      onChanged: (value) {
        setDialogState(() {
          selectedVehicle = value;
        });
      },
    );
  }

  // =========================================================
  // TYPE DROPDOWN
  // =========================================================

  Widget buildTypeDropdown(
    StateSetter setDialogState,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        buildFieldLabel(
          "Type",
        ),

        const SizedBox(
          height: 7,
        ),

        DropdownButtonFormField<String>(
          value: selectedType,

          isExpanded: true,

          decoration:
              fastagInputDecoration(),

          items: const [

            DropdownMenuItem(
              value: "Recharge",
              child:
                  Text("Recharge"),
            ),

            DropdownMenuItem(
              value: "Toll",
              child:
                  Text("Toll"),
            ),

            DropdownMenuItem(
              value: "Refund",
              child:
                  Text("Refund"),
            ),
          ],

          onChanged: (value) {
            if (value == null) {
              return;
            }

            setDialogState(() {
              selectedType = value;
            });
          },
        ),
      ],
    );
  }

  // =========================================================
  // FIELD LABEL
  // =========================================================

  Widget buildFieldLabel(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xff475569),
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget buildFastagField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        buildFieldLabel(
          label,
        ),

        const SizedBox(
          height: 7,
        ),

        TextField(
          controller: controller,

          keyboardType:
              keyboardType,

          decoration:
              fastagInputDecoration(
            hint: hint,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration fastagInputDecoration({
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color: Color(0xff64748b),
        fontSize: 16,
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide:
            const BorderSide(
          color: Color(0xffdbe2ea),
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide:
            const BorderSide(
          color: Color(0xffdbe2ea),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide:
            const BorderSide(
          color: Color(0xff245db5),
          width: 1.3,
        ),
      ),
    );
  }

  // =========================================================
  // SAVE FASTAG
  // =========================================================

  Future<void> saveFastag(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    // =============================================
    // VEHICLE
    // =============================================

    if (selectedVehicle == null ||
        selectedVehicle!.trim().isEmpty) {
      showError(
        "Please select vehicle",
      );
      return;
    }

    // =============================================
    // PROVIDER
    // =============================================

    if (providerController.text
        .trim()
        .isEmpty) {
      showError(
        "Please enter provider",
      );
      return;
    }

    // =============================================
    // TAG NUMBER
    // =============================================

    if (tagNumberController.text
        .trim()
        .isEmpty) {
      showError(
        "Please enter tag number",
      );
      return;
    }

    // =============================================
    // AMOUNT
    // =============================================

    if (amountController.text
        .trim()
        .isEmpty) {
      showError(
        "Please enter amount",
      );
      return;
    }

    // =============================================
    // BALANCE
    // =============================================

    if (balanceController.text
        .trim()
        .isEmpty) {
      showError(
        "Please enter balance after",
      );
      return;
    }

    // =============================================
    // PREPARE DATA
    // =============================================

    final fastagData = {
      "vehicle": selectedVehicle,
      "provider":
          providerController.text.trim(),
      "tagNumber":
          tagNumberController.text.trim(),
      "type": selectedType,
      "amount":
          amountController.text.trim(),
      "balanceAfter":
          balanceController.text.trim(),
      "tollPlaza":
          tollPlazaController.text.trim(),
    };

    debugPrint(
      "====================================",
    );

    debugPrint(
      "FASTAG SAVE DATA",
    );

    debugPrint(
      "$fastagData",
    );

    debugPrint(
      "====================================",
    );

    // =============================================
    // IMPORTANT
    //
    // Current AuthService supplied by you has
    // GET /fastag but no create/save Fastag method.
    //
    // So don't call a fake endpoint here.
    // =============================================

    setDialogState(() {
      isSaving = true;
    });

    await Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );

    if (!mounted) return;

    setDialogState(() {
      isSaving = false;
    });

    Navigator.pop(
      dialogContext,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Fastag data ready. Backend Save API connect karna hai.",
        ),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  void showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
            Colors.red,
      ),
    );
  }

  // =========================================================
  // GET VALUE
  // =========================================================

  String getValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty &&
          value
              .toString()
              .toLowerCase() !=
              "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // VEHICLE
  // =========================================================

  String getVehicle(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "RegistrationNo",
        "registrationNo",
        "VehicleNo",
        "vehicleNo",
        "VehicleNumber",
        "vehicleNumber",
        "RegistrationNumber",
        "registrationNumber",
        "Vehicle",
        "vehicle",
      ],
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  String getDateValue(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Date",
        "date",
        "TransactionDate",
        "transactionDate",
        "FastagDate",
        "fastagDate",
        "TransactionTime",
        "transactionTime",
        "CreatedAt",
        "createdAt",
        "CreatedDate",
        "createdDate",
      ],
    );
  }

  // =========================================================
  // PROVIDER
  // =========================================================

  String getProvider(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Provider",
        "provider",
        "FastagProvider",
        "fastagProvider",
        "Issuer",
        "issuer",
        "Bank",
        "bank",
      ],
    );
  }

  // =========================================================
  // TYPE
  // =========================================================

  String getType(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Type",
        "type",
        "TransactionType",
        "transactionType",
        "FastagType",
        "fastagType",
      ],
    );
  }

  // =========================================================
  // AMOUNT
  // =========================================================

  String getAmount(
    Map<String, dynamic> item,
  ) {
    final value = getValue(
      item,
      [
        "Amount",
        "amount",
        "TollAmount",
        "tollAmount",
        "TransactionAmount",
        "transactionAmount",
      ],
    );

    if (value == "-") {
      return "₹0";
    }

    return value.startsWith("₹")
        ? value
        : "₹$value";
  }

  // =========================================================
  // BALANCE
  // =========================================================

  String getBalance(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Balance",
        "balance",
        "FastagBalance",
        "fastagBalance",
        "AvailableBalance",
        "availableBalance",
      ],
    );
  }

  // =========================================================
  // TOLL PLAZA
  // =========================================================

  String getTollPlaza(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "TollPlaza",
        "tollPlaza",
        "TollPlazaName",
        "tollPlazaName",
        "PlazaName",
        "plazaName",
        "TollName",
        "tollName",
      ],
    );
  }

  // =========================================================
  // PARSE DATE
  // =========================================================

  DateTime? parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text == "-") {
      return null;
    }

    // ISO DATE
    try {
      return DateTime
          .parse(text)
          .toLocal();
    } catch (_) {}

    // dd/MM/yyyy
    try {
      final parts =
          text.split("/");

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

    // dd-MM-yyyy
    try {
      final parts =
          text.split("-");

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

    return null;
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(
    dynamic value,
  ) {
    final date =
        parseDate(value);

    if (date == null) {
      if (value == null) {
        return "-";
      }

      return value.toString();
    }

    return "${date.day}/"
        "${date.month}/"
        "${date.year}";
  }

  // =========================================================
  // APPLY FILTERS
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        searchController.text
            .trim()
            .toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(
      allFastag,
    );

    // =============================================
    // VEHICLE SEARCH
    // =============================================

    if (vehicleSearch.isNotEmpty) {
      result = result
          .where(
        (item) {
          if (item is! Map) {
            return false;
          }

          final data =
              Map<String, dynamic>
                  .from(item);

          return getVehicle(data)
              .toLowerCase()
              .contains(
                vehicleSearch,
              );
        },
      ).toList();
    }

    // =============================================
    // FROM DATE
    // =============================================

    if (fromDate != null) {
      result = result
          .where(
        (item) {
          if (item is! Map) {
            return false;
          }

          final data =
              Map<String, dynamic>
                  .from(item);

          final date =
              parseDate(
            getDateValue(data),
          );

          if (date == null) {
            return false;
          }

          final selectedFrom =
              DateTime(
            fromDate!.year,
            fromDate!.month,
            fromDate!.day,
          );

          final recordDate =
              DateTime(
            date.year,
            date.month,
            date.day,
          );

          return !recordDate
              .isBefore(
            selectedFrom,
          );
        },
      ).toList();
    }

    // =============================================
    // TO DATE
    // =============================================

    if (toDate != null) {
      result = result
          .where(
        (item) {
          if (item is! Map) {
            return false;
          }

          final data =
              Map<String, dynamic>
                  .from(item);

          final date =
              parseDate(
            getDateValue(data),
          );

          if (date == null) {
            return false;
          }

          final selectedTo =
              DateTime(
            toDate!.year,
            toDate!.month,
            toDate!.day,
          );

          final recordDate =
              DateTime(
            date.year,
            date.month,
            date.day,
          );

          return !recordDate
              .isAfter(
            selectedTo,
          );
        },
      ).toList();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      filteredFastag =
          result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    searchController.clear();

    setState(() {
      fromDate = null;
      toDate = null;

      filteredFastag =
          List<dynamic>.from(
        allFastag,
      );
    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({
    required bool isFromDate,
  }) async {
    final picked =
        await showDatePicker(
      context: context,

      initialDate: isFromDate
          ? fromDate ??
              DateTime.now()
          : toDate ??
              DateTime.now(),

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isFromDate) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });

    applyFilters();
  }

  // =========================================================
  // DATE BOX
  // =========================================================

  Widget buildDateBox({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(10),

      child: Container(
        width: 195,
        height: 44,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(10),

          border:
              Border.all(
            color:
                const Color(
              0xffdbe2ea,
            ),
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: Text(
                title,

                style:
                    const TextStyle(
                  fontSize: 14,
                  color:
                      Color(
                    0xff334155,
                  ),
                ),
              ),
            ),

            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color:
                  Color(0xff111827),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xfff1f5f9),

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              const Color(0xffe2e8f0),
        ),
      ),

      child: Wrap(
        spacing: 12,
        runSpacing: 12,

        crossAxisAlignment:
            WrapCrossAlignment.center,

        children: [

          // SEARCH
          SizedBox(
            width: 270,
            height: 44,

            child: TextField(
              controller:
                  searchController,

              decoration:
                  InputDecoration(
                hintText:
                    "Type to search...",

                hintStyle:
                    const TextStyle(
                  color:
                      Color(0xff64748b),
                ),

                filled: true,

                fillColor:
                    Colors.white,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xffdbe2ea),
                  ),
                ),

                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xffdbe2ea),
                  ),
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xff2161b5),
                  ),
                ),
              ),
            ),
          ),

          // FROM
          buildDateBox(
            title:
                fromDate == null
                    ? "dd-mm-yyyy"
                    : formatDate(
                        fromDate,
                      ),

            onTap: () {
              selectDate(
                isFromDate: true,
              );
            },
          ),

          // TO
          buildDateBox(
            title:
                toDate == null
                    ? "dd-mm-yyyy"
                    : formatDate(
                        toDate,
                      ),

            onTap: () {
              selectDate(
                isFromDate: false,
              );
            },
          ),

          // RESET
          SizedBox(
            height: 44,

            child:
                OutlinedButton(
              onPressed:
                  resetFilters,

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xff475569,
                ),

                backgroundColor:
                    Colors.white,

                side:
                    const BorderSide(
                  color:
                      Color(
                    0xffd5dde7,
                  ),
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              child:
                  const Text(
                "Reset",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TYPE BADGE
  // =========================================================

  Widget typeBadge(
    String type,
  ) {
    final text =
        type.trim().isEmpty ||
                type == "-"
            ? "Toll"
            : type;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xffe0f2fe),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 8,
            height: 8,

            decoration:
                const BoxDecoration(
              color:
                  Color(0xff0284c7),

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            text,

            style:
                const TextStyle(
              fontSize: 13,

              fontWeight:
                  FontWeight.w600,

              color:
                  Color(0xff0369a1),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FASTAG TABLE
  // =========================================================

  Widget buildFastagTable() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(50),

          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // =============================================
    // ERROR
    // =============================================

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ElevatedButton(
                onPressed:
                    loadFastag,

                child:
                    const Text(
                  "Retry",
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =============================================
    // EMPTY
    // =============================================

    if (filteredFastag.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(50),

          child:
              Text(
            "No Fastag records found",

            style:
                TextStyle(
              fontSize: 16,
              color:
                  Color(0xff64748b),
            ),
          ),
        ),
      );
    }

    // =============================================
    // TABLE
    // =============================================

    return Container(
      width:
          double.infinity,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              const Color(0xffe2e8f0),
        ),
      ),

      child:
          ClipRRect(
        borderRadius:
            BorderRadius.circular(16),

        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child:
              DataTable(
            columnSpacing: 42,

            horizontalMargin:
                18,

            headingRowHeight:
                48,

            dataRowMinHeight:
                58,

            dataRowMaxHeight:
                70,

            dividerThickness:
                0.7,

            columns: const [

              DataColumn(
                label:
                    TableHeader(
                  "DATE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "VEHICLE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "PROVIDER",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "TYPE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "AMOUNT",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "BALANCE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "TOLL PLAZA",
                ),
              ),
            ],

            rows:
                filteredFastag
                    .map<DataRow>(
              (item) {

                final data =
                    Map<String, dynamic>
                        .from(item);

                final date =
                    getDateValue(
                  data,
                );

                final vehicle =
                    getVehicle(
                  data,
                );

                final provider =
                    getProvider(
                  data,
                );

                final type =
                    getType(
                  data,
                );

                final amount =
                    getAmount(
                  data,
                );

                final balance =
                    getBalance(
                  data,
                );

                final tollPlaza =
                    getTollPlaza(
                  data,
                );

                return DataRow(
                  cells: [

                    // DATE
                    DataCell(
                      Text(
                        formatDate(
                          date,
                        ),

                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(
                            0xff1e293b,
                          ),
                        ),
                      ),
                    ),

                    // VEHICLE
                    DataCell(
                      Text(
                        vehicle,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(
                            0xff111827,
                          ),
                        ),
                      ),
                    ),

                    // PROVIDER
                    DataCell(
                      Text(
                        provider,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(
                            0xff111827,
                          ),
                        ),
                      ),
                    ),

                    // TYPE
                    DataCell(
                      typeBadge(
                        type,
                      ),
                    ),

                    // AMOUNT
                    DataCell(
                      Text(
                        amount,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(
                            0xff111827,
                          ),
                        ),
                      ),
                    ),

                    // BALANCE
                    DataCell(
                      Text(
                        balance,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(
                            0xff111827,
                          ),
                        ),
                      ),
                    ),

                    // TOLL PLAZA
                    DataCell(
                      SizedBox(
                        width: 190,

                        child:
                            Text(
                          tollPlaza,

                          maxLines: 2,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                              0xff94a3b8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff4f7fb),

      body:
          SafeArea(
        child:
            Column(
          children: [

            // =================================================
            // HEADER
            // =================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                15,
              ),

              child:
                  Row(
                children: [

                  // TITLE
                  const Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          "Fastag",

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            fontSize: 25,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Colors.black,
                          ),
                        ),

                        SizedBox(
                          height: 4,
                        ),

                        Text(
                          "FASTag transaction records",

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                              0xff64748b,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // ADD FASTAG
                  // ONLY CORPORATEADMIN / STATEADMIN
                  // =================================================

                  if (canAddFastag) ...[

                    const SizedBox(
                      width: 8,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          addFastag,

                      icon:
                          const Icon(
                        Icons.add,
                        size: 19,
                      ),

                      label:
                          const Text(
                        "Add Fastag",
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xff2458A6,
                        ),

                        foregroundColor:
                            Colors.white,

                        elevation: 0,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    width: 5,
                  ),

                  // =================================================
                  // REFRESH
                  // =================================================

                  IconButton(
                    tooltip:
                        "Refresh",

                    onPressed:
                        loadFastag,

                    icon:
                        const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  18,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    // FILTER
                    buildFilterSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    // RECORD COUNT
                    Text(
                      "Fastag Records: "
                      "${filteredFastag.length}",

                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(
                          0xff475569,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // TABLE
                    buildFastagTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    searchController.dispose();

    providerController.dispose();

    tagNumberController.dispose();

    amountController.dispose();

    balanceController.dispose();

    tollPlazaController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class TableHeader
    extends StatelessWidget {

  final String title;

  const TableHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,

      maxLines: 1,

      style:
          const TextStyle(
        fontSize: 12,
        fontWeight:
            FontWeight.w700,
        color:
            Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }
}