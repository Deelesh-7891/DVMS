import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ChallansScreen extends StatefulWidget {
  const ChallansScreen({super.key});

  @override
  State<ChallansScreen> createState() => _ChallansScreenState();
}

class _ChallansScreenState extends State<ChallansScreen> {
  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController vehicleController =
      TextEditingController();

  final TextEditingController offenceController =
      TextEditingController();

  final TextEditingController challanController =
      TextEditingController();

  // =========================================================
  // DATA
  // =========================================================

  List<dynamic> allChallans = [];
  List<dynamic> filteredChallans = [];

  bool isLoading = false;
  String? errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadChallans();

    vehicleController.addListener(applyFilters);
    offenceController.addListener(applyFilters);
    challanController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD CHALLANS API
  // =========================================================

  Future<void> loadChallans() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getchallan();

      if (!mounted) return;

      setState(() {
        allChallans = List<dynamic>.from(result);
        filteredChallans = List<dynamic>.from(result);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        allChallans = [];
        filteredChallans = [];
      });

      debugPrint("Challan API Error: $e");
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
  // FILTER
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        vehicleController.text.trim().toLowerCase();

    final offenceSearch =
        offenceController.text.trim().toLowerCase();

    final challanSearch =
        challanController.text.trim().toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(allChallans);

    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final vehicle = getValue(data, [
          "RegistrationNo",
          "registrationNo",
          "VehicleNo",
          "vehicleNo",
          "VehicleNumber",
          "vehicleNumber",
          "Vehicle",
          "vehicle",
        ]).toLowerCase();

        return vehicle.contains(vehicleSearch);
      }).toList();
    }

    if (offenceSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final offence = getValue(data, [
          "Offence",
          "offence",
          "OffenceDetails",
          "offenceDetails",
          "Description",
          "description",
        ]).toLowerCase();

        return offence.contains(offenceSearch);
      }).toList();
    }

    if (challanSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final challanNo = getValue(data, [
          "ChallanNo",
          "challanNo",
          "ChallanNumber",
          "challanNumber",
          "Challan_No",
          "challan_no",
        ]).toLowerCase();

        return challanNo.contains(challanSearch);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredChallans = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    vehicleController.clear();
    offenceController.clear();
    challanController.clear();

    setState(() {
      filteredChallans =
          List<dynamic>.from(allChallans);
    });
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return "-";
    }

    final text = value.toString();

    if (text.trim().isEmpty) {
      return "-";
    }

    try {
      final date = DateTime.parse(text).toLocal();

      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return text;
    }
  }

  // =========================================================
  // FILTER INPUT
  // =========================================================

  Widget searchBox({
    required TextEditingController controller,
    required String hintText,
    double width = 270,
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
  // STATUS
  // =========================================================

  String getStatus(Map<String, dynamic> data) {
    return getValue(data, [
      "Status",
      "status",
      "PaymentStatus",
      "paymentStatus",
    ]);
  }

  bool isPaid(String status) {
    return status.toLowerCase() == "paid";
  }

  Widget statusBadge(String status) {
    final paid = isPaid(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: paid
            ? const Color(0xffdcfce7)
            : const Color(0xffffdddd),
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
            decoration: BoxDecoration(
              color: paid
                  ? const Color(0xff16a34a)
                  : const Color(0xffef233c),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            paid ? "Paid" : "Pending",
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color: paid
                  ? const Color(0xff16a34a)
                  : const Color(0xffef233c),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MARK PAID
  // =========================================================

  void markPaid(int index) {
    final data =
        Map<String, dynamic>.from(
      filteredChallans[index],
    );

    setState(() {
      data["Status"] = "Paid";
      filteredChallans[index] = data;

      final originalIndex =
          allChallans.indexOf(
        filteredChallans[index],
      );

      if (originalIndex >= 0) {
        allChallans[originalIndex] =
            data;
      }
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Challan marked as Paid"),
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff1f4f8),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe0e5eb),
        ),
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
            controller: offenceController,
            hintText: "Type to search...",
            width: 270,
          ),

          searchBox(
            controller: challanController,
            hintText: "Search challan no...",
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
  // TABLE HEADER
  // =========================================================

  Widget tableHeader(String text) {
    return Text(
      text,
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
  // CHALLAN TABLE
  // =========================================================

  Widget buildChallanTable() {
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
                onPressed:
                    loadChallans,
                child:
                    const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredChallans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Text(
            "No challan records found",
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
            BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xffe0e5eb),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(4),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            horizontalMargin: 18,
            headingRowHeight: 48,
            dataRowMinHeight: 72,
            dataRowMaxHeight: 110,

            columns: [
              DataColumn(
                label: tableHeader("DATE"),
              ),
              DataColumn(
                label:
                    tableHeader("VEHICLE"),
              ),
              DataColumn(
                label: tableHeader(
                  "CHALLAN NO.",
                ),
              ),
              DataColumn(
                label:
                    tableHeader("OFFENCE"),
              ),
              DataColumn(
                label:
                    tableHeader("FINE"),
              ),
              DataColumn(
                label:
                    tableHeader("STATUS"),
              ),
              const DataColumn(
                label: Text(""),
              ),
            ],

            rows: filteredChallans
                .asMap()
                .entries
                .map<DataRow>(
              (entry) {
                final index =
                    entry.key;

                final data =
                    Map<String,
                            dynamic>.from(
                  entry.value,
                );

                final date =
                    getValue(data, [
                  "Date",
                  "date",
                  "ChallanDate",
                  "challanDate",
                  "ChallanDateTime",
                  "challanDateTime",
                ]);

                final vehicle =
                    getValue(data, [
                  "RegistrationNo",
                  "registrationNo",
                  "VehicleNo",
                  "vehicleNo",
                  "VehicleNumber",
                  "vehicleNumber",
                  "Vehicle",
                  "vehicle",
                ]);

                final challanNo =
                    getValue(data, [
                  "ChallanNo",
                  "challanNo",
                  "ChallanNumber",
                  "challanNumber",
                  "Challan_No",
                  "challan_no",
                ]);

                final offence =
                    getValue(data, [
                  "Offence",
                  "offence",
                  "OffenceDetails",
                  "offenceDetails",
                  "Description",
                  "description",
                ]);

                final fine =
                    getValue(data, [
                  "Fine",
                  "fine",
                  "FineAmount",
                  "fineAmount",
                  "Amount",
                  "amount",
                ]);

                final status =
                    getStatus(data);

                return DataRow(
                  cells: [
                    // DATE
                    DataCell(
                      Text(
                        formatDate(date),
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(0xff1e293b),
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
                              Color(0xff1e293b),
                        ),
                      ),
                    ),

                    // CHALLAN NO
                    DataCell(
                      SizedBox(
                        width: 230,
                        child: Text(
                          challanNo,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(0xff334155),
                          ),
                        ),
                      ),
                    ),

                    // OFFENCE
                    DataCell(
                      SizedBox(
                        width: 620,
                        child: Text(
                          offence,
                          maxLines: 4,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color:
                                Color(0xff94a8c0),
                          ),
                        ),
                      ),
                    ),

                    // FINE
                    DataCell(
                      Text(
                        "₹${fine == "-" ? "0" : fine}",
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              Color(0xff1e293b),
                        ),
                      ),
                    ),

                    // STATUS
                    DataCell(
                      statusBadge(status),
                    ),

                    // ACTION
                    DataCell(
                      isPaid(status)
                          ? const SizedBox()
                          : SizedBox(
                              width: 80,
                              height: 56,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    () {
                                  markPaid(
                                    index,
                                  );
                                },
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      const Color(
                                    0xff2161b5,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                ),
                                child:
                                    const Text(
                                  "Mark\nPaid",
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        14,
                                    fontWeight:
                                        FontWeight
                                            .w700,
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
                          "Challans",
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
                          "Vehicle challan management",
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
                    onPressed:
                        loadChallans,
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
                    // FILTER
                    buildFilterSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    // COUNT
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Challan Records: ${filteredChallans.length}",
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

                    // TABLE
                    buildChallanTable(),
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
    offenceController.dispose();
    challanController.dispose();

    super.dispose();
  }
}