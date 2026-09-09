import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class PucScreen extends StatefulWidget {
  const PucScreen({super.key});

  @override
  State<PucScreen> createState() => _PucScreenState();
}

class _PucScreenState extends State<PucScreen> {
  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController vehicleController =
      TextEditingController();

  final TextEditingController certificateController =
      TextEditingController();

  // =========================================================
  // DATA
  // =========================================================

  List<dynamic> allPuc = [];
  List<dynamic> filteredPuc = [];

  bool isLoading = false;
  String? errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadPuc();

    vehicleController.addListener(applyFilters);
    certificateController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD PUC API
  // =========================================================

  Future<void> loadPuc() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getpuc();

      debugPrint("PUC API RESPONSE: $result");

      if (!mounted) return;

      setState(() {
        allPuc = List<dynamic>.from(result);
        filteredPuc = List<dynamic>.from(result);
        isLoading = false;
      });

      applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        allPuc = [];
        filteredPuc = [];
      });

      debugPrint("PUC API ERROR: $e");
    }
  }

  // =========================================================
  // SAFE VALUE
  // =========================================================

  String getValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // VEHICLE
  // =========================================================

  String getVehicle(Map<String, dynamic> item) {
    return getValue(item, [
      "RegistrationNo",
      "registrationNo",
      "VehicleNo",
      "vehicleNo",
      "VehicleNumber",
      "vehicleNumber",
      "Vehicle",
      "vehicle",
    ]);
  }

  // =========================================================
  // CERTIFICATE NUMBER
  // =========================================================

  String getCertificateNo(Map<String, dynamic> item) {
    return getValue(item, [
      "CertificateNo",
      "certificateNo",
      "CertificateNumber",
      "certificateNumber",
      "PUCCertificateNo",
      "pucCertificateNo",
      "PUCNo",
      "pucNo",
      "Certificate_No",
      "certificate_no",
    ]);
  }

  // =========================================================
  // EXPIRY
  // =========================================================

  String getExpiry(Map<String, dynamic> item) {
    return getValue(item, [
      "Expiry",
      "expiry",
      "ExpiryDate",
      "expiryDate",
      "PUCExpiry",
      "pucExpiry",
      "PUCExpiryDate",
      "pucExpiryDate",
      "ValidTill",
      "validTill",
      "ValidityDate",
      "validityDate",
    ]);
  }

  // =========================================================
  // DATE PARSE
  // =========================================================

  DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == "-") {
      return null;
    }

    // ISO date
    try {
      return DateTime.parse(text).toLocal();
    } catch (_) {}

    // dd/MM/yyyy
    try {
      final parts = text.split("/");

      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        return DateTime(
          year,
          month,
          day,
        );
      }
    } catch (_) {}

    // dd-MM-yyyy
    try {
      final parts = text.split("-");

      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        return DateTime(
          year,
          month,
          day,
        );
      }
    } catch (_) {}

    return null;
  }

  // =========================================================
  // FORMAT EXPIRY
  // =========================================================

  String formatExpiry(dynamic value) {
    final date = parseDate(value);

    if (date == null) {
      return value?.toString() ?? "-";
    }

    return "${date.day}/${date.month}/${date.year}";
  }

  // =========================================================
  // DAYS LEFT
  // =========================================================

  int? getDaysLeft(dynamic expiry) {
    final date = parseDate(expiry);

    if (date == null) {
      return null;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiryDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return expiryDay
        .difference(today)
        .inDays;
  }

  // =========================================================
  // FILTER
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        vehicleController.text
            .trim()
            .toLowerCase();

    final certificateSearch =
        certificateController.text
            .trim()
            .toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(allPuc);

    // VEHICLE SEARCH
    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(item);

        final vehicle =
            getVehicle(data).toLowerCase();

        return vehicle.contains(
          vehicleSearch,
        );
      }).toList();
    }

    // CERTIFICATE SEARCH
    if (certificateSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(item);

        final certificate =
            getCertificateNo(
          data,
        ).toLowerCase();

        return certificate.contains(
          certificateSearch,
        );
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredPuc = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    vehicleController.clear();
    certificateController.clear();

    setState(() {
      filteredPuc =
          List<dynamic>.from(allPuc);
    });
  }

  // =========================================================
  // SEARCH BOX
  // =========================================================

  Widget searchBox({
    required TextEditingController controller,
    required String hintText,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 44,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xff7c7c7c),
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xffdbe2ea),
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xffdbe2ea),
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xff2161b5),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f4f8),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe0e5eb),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        children: [
          searchBox(
            controller: vehicleController,
            hintText: "Type to search...",
            width: 270,
          ),

          searchBox(
            controller:
                certificateController,
            hintText:
                "Search certificate no...",
            width: 270,
          ),

          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: applyFilters,
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    const Color(0xff2161b5),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Filter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: resetFilters,
              style:
                  OutlinedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(0xff475569),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                side:
                    const BorderSide(
                  color: Color(0xffd5dde7),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Reset",
                style: TextStyle(
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
  // STATE BADGE
  // =========================================================

  Widget stateBadge(int? daysLeft) {
    if (daysLeft == null) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xfff1f5f9),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Text(
          "Unknown",
          style: TextStyle(
            color: Color(0xff64748b),
            fontWeight:
                FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    if (daysLeft < 0) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffffdddd),
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
                color: Color(0xffef233c),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              "Expired",
              style: TextStyle(
                color: Color(0xffef233c),
                fontWeight:
                    FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (daysLeft <= 30) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xfffff4d6),
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
                color: Color(0xfff59e0b),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              "Expiring Soon",
              style: TextStyle(
                color: Color(0xffb45309),
                fontWeight:
                    FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffdcfce7),
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
              color: Color(0xff16a34a),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            "Valid",
            style: TextStyle(
              color: Color(0xff15803d),
              fontWeight:
                  FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget tableHeader(String title) {
    return Text(
      title,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 12,
        fontWeight:
            FontWeight.w700,
        color: Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }

  // =========================================================
  // PUC TABLE
  // =========================================================

  Widget buildPucTable() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child:
              CircularProgressIndicator(),
        ),
      );
    }

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
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: loadPuc,
                child:
                    const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredPuc.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Text(
            "No PUC records found",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff64748b),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe0e5eb),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: DataTable(
            columnSpacing: 80,
            horizontalMargin: 18,
            headingRowHeight: 48,
            dataRowMinHeight: 59,
            dataRowMaxHeight: 72,
            dividerThickness: 1,

            columns: [
              DataColumn(
                label:
                    tableHeader("VEHICLE"),
              ),
              DataColumn(
                label: tableHeader(
                  "CERTIFICATE NO.",
                ),
              ),
              DataColumn(
                label:
                    tableHeader("EXPIRY"),
              ),
              DataColumn(
                label:
                    tableHeader("DAYS LEFT"),
              ),
              DataColumn(
                label:
                    tableHeader("STATE"),
              ),
            ],

            rows: filteredPuc
                .map<DataRow>((item) {
              final data =
                  Map<String, dynamic>.from(
                item,
              );

              final vehicle =
                  getVehicle(data);

              final certificate =
                  getCertificateNo(
                data,
              );

              final expiry =
                  getExpiry(data);

              final daysLeft =
                  getDaysLeft(expiry);

              return DataRow(
                cells: [
                  // VEHICLE
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        vehicle,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // CERTIFICATE
                  DataCell(
                    SizedBox(
                      width: 300,
                      child: Text(
                        certificate,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(0xff1e293b),
                        ),
                      ),
                    ),
                  ),

                  // EXPIRY
                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        formatExpiry(
                          expiry,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // DAYS LEFT
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        daysLeft == null
                            ? "-"
                            : "$daysLeft days",
                        style:
                            TextStyle(
                          fontSize: 14,
                          color: daysLeft !=
                                      null &&
                                  daysLeft < 0
                              ? const Color(
                                  0xff111827,
                                )
                              : const Color(
                                  0xff111827,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // STATE
                  DataCell(
                    stateBadge(
                      daysLeft,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff4f7fb),
      body: SafeArea(
        child: Column(
          children: [
            // =============================================
            // HEADER
            // =============================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                15,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          "PUC",
                          style:
                              TextStyle(
                            fontSize: 25,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Pollution Under Control certificate",
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

                  IconButton(
                    tooltip: "Refresh",
                    onPressed: loadPuc,
                    icon:
                        const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),
            ),

            // =============================================
            // CONTENT
            // =============================================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    buildFilterSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "PUC Records: ${filteredPuc.length}",
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color:
                                  Color(
                                0xff475569,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    buildPucTable(),
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
    vehicleController.dispose();
    certificateController.dispose();

    super.dispose();
  }
}