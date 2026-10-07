import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController searchController = TextEditingController();

  final TextEditingController certificateController = TextEditingController();

  // =========================================================
  // DATA
  // =========================================================

  List<dynamic> allFitness = [];
  List<dynamic> filteredFitness = [];

  bool isLoading = false;
  String? errorMessage;

  DateTime? fromDate;
  DateTime? toDate;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadFitness();
  }

  // =========================================================
  // LOAD FITNESS
  // =========================================================

  Future<void> loadFitness() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getfitness();

      if (!mounted) return;

      setState(() {
        allFitness = List<dynamic>.from(result);
        filteredFitness = List<dynamic>.from(result);
        isLoading = false;
      });

      debugPrint("FITNESS API RESPONSE: $result");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        allFitness = [];
        filteredFitness = [];
      });

      debugPrint("Fitness API Error: $e");
    }
  }

  // =========================================================
  // GET VALUE
  // =========================================================

  String getValue(Map<String, dynamic> item, List<String> keys) {
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
      "RegistrationNumber",
      "registrationNumber",
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
      "FitnessCertificateNo",
      "fitnessCertificateNo",
      "FitnessCertificateNumber",
      "fitnessCertificateNumber",
      "FitnessNo",
      "fitnessNo",
    ]);
  }

  // =========================================================
  // EXPIRY
  // =========================================================

  String getExpiryValue(Map<String, dynamic> item) {
    return getValue(item, [
      "Expiry",
      "expiry",
      "ExpiryDate",
      "expiryDate",
      "FitnessExpiry",
      "fitnessExpiry",
      "FitnessExpiryDate",
      "fitnessExpiryDate",
      "ValidTill",
      "validTill",
      "ValidityDate",
      "validityDate",
    ]);
  }

  // =========================================================
  // STATE
  // =========================================================

  String getState(Map<String, dynamic> item) {
    return getValue(item, [
      "State",
      "state",
      "FitnessState",
      "fitnessState",
      "Status",
      "status",
    ]);
  }

  // =========================================================
  // PARSE DATE
  // =========================================================

  DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == "-") {
      return null;
    }

    // ISO DATE
    try {
      return DateTime.parse(text).toLocal();
    } catch (_) {}

    // dd/MM/yyyy
    try {
      final parts = text.split("/");

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
      final parts = text.split("-");

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

  String formatDate(dynamic value) {
    final date = parseDate(value);

    if (date == null) {
      return "-";
    }

    return "${date.day}/"
        "${date.month}/"
        "${date.year}";
  }

  // =========================================================
  // DAYS LEFT
  // =========================================================

  int? getDaysLeft(dynamic value) {
    final expiry = parseDate(value);

    if (expiry == null) {
      return null;
    }

    final today = DateTime.now();

    final todayOnly = DateTime(today.year, today.month, today.day);

    final expiryOnly = DateTime(expiry.year, expiry.month, expiry.day);

    return expiryOnly.difference(todayOnly).inDays;
  }

  // =========================================================
  // FILTER
  // =========================================================

  void applyFilters() {
    final vehicleSearch = searchController.text.trim().toLowerCase();

    final certificateSearch = certificateController.text.trim().toLowerCase();

    List<dynamic> result = List<dynamic>.from(allFitness);

    // VEHICLE SEARCH
    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) {
          return false;
        }

        final data = Map<String, dynamic>.from(item);

        return getVehicle(data).toLowerCase().contains(vehicleSearch);
      }).toList();
    }

    // CERTIFICATE SEARCH
    if (certificateSearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) {
          return false;
        }

        final data = Map<String, dynamic>.from(item);

        return getCertificateNo(data).toLowerCase().contains(certificateSearch);
      }).toList();
    }

    // FROM DATE
    if (fromDate != null) {
      result = result.where((item) {
        if (item is! Map) {
          return false;
        }

        final data = Map<String, dynamic>.from(item);

        final expiry = parseDate(getExpiryValue(data));

        if (expiry == null) {
          return false;
        }

        final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);

        final selectedFrom = DateTime(
          fromDate!.year,
          fromDate!.month,
          fromDate!.day,
        );

        return !expiryDate.isBefore(selectedFrom);
      }).toList();
    }

    // TO DATE
    if (toDate != null) {
      result = result.where((item) {
        if (item is! Map) {
          return false;
        }

        final data = Map<String, dynamic>.from(item);

        final expiry = parseDate(getExpiryValue(data));

        if (expiry == null) {
          return false;
        }

        final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);

        final selectedTo = DateTime(toDate!.year, toDate!.month, toDate!.day);

        return !expiryDate.isAfter(selectedTo);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredFitness = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    searchController.clear();
    certificateController.clear();

    setState(() {
      fromDate = null;
      toDate = null;

      filteredFitness = List<dynamic>.from(allFitness);
    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({required bool isFromDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? fromDate ?? DateTime.now()
          : toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
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
  }

  // =========================================================
  // TODAY TEXT
  // =========================================================

  String todayText() {
    final now = DateTime.now();

    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${weekdays[now.weekday - 1]}, "
        "${now.day} "
        "${months[now.month - 1]} "
        "${now.year}";
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 750;

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fitness Certificates",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  "RTO Fitness monitoring for tagged demo vehicles",
                  style: TextStyle(fontSize: 15, color: Color(0xff64748b)),
                ),

                const SizedBox(height: 12),

                buildHeaderActions(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fitness Certificates",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff111827),
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      "RTO Fitness monitoring for tagged demo vehicles",
                      style: TextStyle(fontSize: 15, color: Color(0xff64748b)),
                    ),
                  ],
                ),
              ),

              buildHeaderActions(),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER ACTIONS
  // NO ADD CERTIFICATE BUTTON
  // =========================================================

  Widget buildHeaderActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          todayText(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff1e293b),
          ),
        ),

        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xff2161b5),
            shape: BoxShape.circle,
          ),
          child: const Text(
            "SY",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INFORMATION
  // =========================================================

  Widget buildInfoText() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Only vehicles tagged Fitness Required in Vehicle Master appear here.",
          style: TextStyle(fontSize: 16, color: Color(0xff8aa0c0)),
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(
          top: BorderSide(color: Color(0xffe2e8f0)),
          bottom: BorderSide(color: Color(0xffe2e8f0)),
        ),
      ),
      child: Wrap(
        spacing: 13,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // VEHICLE SEARCH
          SizedBox(
            width: 270,
            height: 44,
            child: TextField(
              controller: searchController,
              decoration: inputDecoration("Type to search..."),
            ),
          ),

          // CERTIFICATE SEARCH
          SizedBox(
            width: 270,
            height: 44,
            child: TextField(
              controller: certificateController,
              decoration: inputDecoration("Search certificate no..."),
            ),
          ),

          // FROM DATE
          buildDateBox(
            title: fromDate == null
                ? "dd-mm-yyyy"
                : formatSelectedDate(fromDate!),
            onTap: () {
              selectDate(isFromDate: true);
            },
          ),

          // TO DATE
          buildDateBox(
            title: toDate == null ? "dd-mm-yyyy" : formatSelectedDate(toDate!),
            onTap: () {
              selectDate(isFromDate: false);
            },
          ),

          // FILTER BUTTON
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2161b5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Filter",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // RESET BUTTON
          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff475569),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xffdbe2ea)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Reset"),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff8b8f96)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffdbe2ea)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffdbe2ea)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff2161b5)),
      ),
    );
  }

  // =========================================================
  // DATE BOX
  // =========================================================

  Widget buildDateBox({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 190,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffdbe2ea)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xff475569)),
              ),
            ),

            const Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: Color(0xff111827),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FORMAT SELECTED DATE
  // =========================================================

  String formatSelectedDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget buildTable() {
    // LOADING
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ERROR
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),

              const SizedBox(height: 12),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: loadFitness,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    // EMPTY
    if (filteredFitness.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Text(
            "No fitness records found",
            style: TextStyle(fontSize: 16, color: Color(0xff64748b)),
          ),
        ),
      );
    }

    // TABLE
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 18,
            columnSpacing: 70,
            headingRowHeight: 48,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 72,
            dividerThickness: 0.7,

            columns: const [
              DataColumn(label: FitnessHeader("VEHICLE")),
              DataColumn(label: FitnessHeader("CERTIFICATE NO.")),
              DataColumn(label: FitnessHeader("EXPIRY")),
              DataColumn(label: FitnessHeader("DAYS LEFT")),
              DataColumn(label: FitnessHeader("STATE")),
            ],

            rows: filteredFitness.map<DataRow>((item) {
              final data = Map<String, dynamic>.from(item);

              final vehicle = getVehicle(data);

              final certificate = getCertificateNo(data);

              final expiry = getExpiryValue(data);

              final daysLeft = getDaysLeft(expiry);

              return DataRow(
                cells: [
                  // VEHICLE
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        vehicle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // CERTIFICATE NO
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        certificate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // EXPIRY
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        formatDate(expiry),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // DAYS LEFT
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        daysLeft == null ? "-" : "$daysLeft days",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // STATE
                  DataCell(fitnessStatusBadge(daysLeft)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget fitnessStatusBadge(int? daysLeft) {
    String text;
    Color background;
    Color foreground;

    if (daysLeft == null) {
      text = "Unknown";

      background = const Color(0xffe2e8f0);

      foreground = const Color(0xff475569);
    } else if (daysLeft < 0) {
      text = "Expired";

      background = const Color(0xffffdddd);

      foreground = const Color(0xffdc2626);
    } else if (daysLeft <= 30) {
      text = "Expiring Soon";

      background = const Color(0xffffedd5);

      foreground = const Color(0xffea580c);
    } else {
      text = "Valid";

      background = const Color(0xffdcfce7);

      foreground = const Color(0xff15803d);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 7),

          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            buildHeader(),

            // INFORMATION
            buildInfoText(),

            // FILTER
            buildFilterSection(),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
                child: Column(
                  children: [
                    // RECORD COUNT + REFRESH
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Fitness Records: "
                            "${filteredFitness.length}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ),

                        IconButton(
                          tooltip: "Refresh",
                          onPressed: loadFitness,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    // TABLE
                    buildTable(),
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
    certificateController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class FitnessHeader extends StatelessWidget {
  final String title;

  const FitnessHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }
}
