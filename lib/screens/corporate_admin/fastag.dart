import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class FastagScreen extends StatefulWidget {
  const FastagScreen({super.key});

  @override
  State<FastagScreen> createState() => _FastagScreenState();
}

class _FastagScreenState extends State<FastagScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController searchController =
      TextEditingController();

  List<dynamic> allFastag = [];
  List<dynamic> filteredFastag = [];

  bool isLoading = false;
  String? errorMessage;

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();

    loadFastag();

    searchController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD FASTAG API
  // =========================================================

  Future<void> loadFastag() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getfastag();

      if (!mounted) return;

      setState(() {
        allFastag = List<dynamic>.from(result);
        filteredFastag = List<dynamic>.from(result);
        isLoading = false;
      });

      applyFilters();

      debugPrint("FASTAG RECORDS: ${result.length}");
      debugPrint("FASTAG RESPONSE: $result");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        allFastag = [];
        filteredFastag = [];
      });

      debugPrint("Fastag API Error: $e");
    }
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
  // DATE
  // =========================================================

  String getDateValue(Map<String, dynamic> item) {
    return getValue(item, [
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
    ]);
  }

  // =========================================================
  // PROVIDER
  // =========================================================

  String getProvider(Map<String, dynamic> item) {
    return getValue(item, [
      "Provider",
      "provider",
      "FastagProvider",
      "fastagProvider",
      "Issuer",
      "issuer",
      "Bank",
      "bank",
    ]);
  }

  // =========================================================
  // TYPE
  // =========================================================

  String getType(Map<String, dynamic> item) {
    return getValue(item, [
      "Type",
      "type",
      "TransactionType",
      "transactionType",
      "FastagType",
      "fastagType",
    ]);
  }

  // =========================================================
  // AMOUNT
  // =========================================================

  String getAmount(Map<String, dynamic> item) {
    final value = getValue(item, [
      "Amount",
      "amount",
      "TollAmount",
      "tollAmount",
      "TransactionAmount",
      "transactionAmount",
    ]);

    if (value == "-") return "₹0";

    return value.startsWith("₹") ? value : "₹$value";
  }

  // =========================================================
  // BALANCE
  // =========================================================

  String getBalance(Map<String, dynamic> item) {
    return getValue(item, [
      "Balance",
      "balance",
      "FastagBalance",
      "fastagBalance",
      "AvailableBalance",
      "availableBalance",
    ]);
  }

  // =========================================================
  // TOLL PLAZA
  // =========================================================

  String getTollPlaza(Map<String, dynamic> item) {
    return getValue(item, [
      "TollPlaza",
      "tollPlaza",
      "TollPlazaName",
      "tollPlazaName",
      "PlazaName",
      "plazaName",
      "TollName",
      "tollName",
    ]);
  }

  // =========================================================
  // PARSE DATE
  // =========================================================

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text == "-") {
      return null;
    }

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
      if (value == null) return "-";
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
        searchController.text.trim().toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(allFastag);

    // Vehicle filter
    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        return getVehicle(data)
            .toLowerCase()
            .contains(vehicleSearch);
      }).toList();
    }

    // From date
    if (fromDate != null) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        final date =
            parseDate(getDateValue(data));

        if (date == null) return false;

        final selectedFrom = DateTime(
          fromDate!.year,
          fromDate!.month,
          fromDate!.day,
        );

        final recordDate = DateTime(
          date.year,
          date.month,
          date.day,
        );

        return !recordDate.isBefore(selectedFrom);
      }).toList();
    }

    // To date
    if (toDate != null) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        final date =
            parseDate(getDateValue(data));

        if (date == null) return false;

        final selectedTo = DateTime(
          toDate!.year,
          toDate!.month,
          toDate!.day,
        );

        final recordDate = DateTime(
          date.year,
          date.month,
          date.day,
        );

        return !recordDate.isAfter(selectedTo);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredFastag = result;
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
          List<dynamic>.from(allFastag);
    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({
    required bool isFromDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? fromDate ?? DateTime.now()
          : toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 195,
        height: 44,
        padding:
            const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xffdbe2ea),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff334155),
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xff111827),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe2e8f0),
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Type to search...",
                hintStyle: const TextStyle(
                  color: Color(0xff64748b),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdbe2ea),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdbe2ea),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xff2161b5),
                  ),
                ),
              ),
            ),
          ),

          // FROM DATE
          buildDateBox(
            title: fromDate == null
                ? "dd-mm-yyyy"
                : formatDate(fromDate),
            onTap: () {
              selectDate(isFromDate: true);
            },
          ),

          // TO DATE
          buildDateBox(
            title: toDate == null
                ? "dd-mm-yyyy"
                : formatDate(toDate),
            onTap: () {
              selectDate(isFromDate: false);
            },
          ),

          // RESET
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xff475569),
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xffd5dde7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Reset",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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

  Widget typeBadge(String type) {
    final text =
        type.trim().isEmpty || type == "-"
            ? "Toll"
            : type;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffe0f2fe),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xff0284c7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff0369a1),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget buildFastagTable() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: loadFastag,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredFastag.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Text(
            "No Fastag records found",
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe2e8f0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 42,
            horizontalMargin: 18,
            headingRowHeight: 48,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 70,
            dividerThickness: 0.7,

            columns: const [
              DataColumn(
                label: TableHeader("DATE"),
              ),
              DataColumn(
                label: TableHeader("VEHICLE"),
              ),
              DataColumn(
                label: TableHeader("PROVIDER"),
              ),
              DataColumn(
                label: TableHeader("TYPE"),
              ),
              DataColumn(
                label: TableHeader("AMOUNT"),
              ),
              DataColumn(
                label: TableHeader("BALANCE"),
              ),
              DataColumn(
                label: TableHeader("TOLL PLAZA"),
              ),
            ],

            rows: filteredFastag.map<DataRow>(
              (item) {
                final data =
                    Map<String, dynamic>.from(item);

                final date =
                    getDateValue(data);

                final vehicle =
                    getVehicle(data);

                final provider =
                    getProvider(data);

                final type =
                    getType(data);

                final amount =
                    getAmount(data);

                final balance =
                    getBalance(data);

                final tollPlaza =
                    getTollPlaza(data);

                return DataRow(
                  cells: [
                    // DATE
                    DataCell(
                      Text(
                        formatDate(date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff1e293b),
                        ),
                      ),
                    ),

                    // VEHICLE
                    DataCell(
                      Text(
                        vehicle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),

                    // PROVIDER
                    DataCell(
                      Text(
                        provider,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),

                    // TYPE
                    DataCell(
                      typeBadge(type),
                    ),

                    // AMOUNT
                    DataCell(
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),

                    // BALANCE
                    DataCell(
                      Text(
                        balance,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),

                    // TOLL PLAZA
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          tollPlaza,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff94a3b8),
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
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
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
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fastag",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight:
                                FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "FASTag transaction records",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: "Refresh",
                    onPressed: loadFastag,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    buildFilterSection(),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Fastag Records: "
                            "${filteredFastag.length}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xff475569),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

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
    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class TableHeader extends StatelessWidget {
  final String title;

  const TableHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }
}