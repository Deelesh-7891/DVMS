import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All statuses";

  List<Map<String, dynamic>> allDrivers = [];
  List<Map<String, dynamic>> filteredDrivers = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _authService.getDrivers();

      setState(() {
        allDrivers = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredDrivers = List.from(allDrivers);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = "Unable to load drivers: $e";
      });
    }
  }

  // GET /drivers is a `SELECT *` off dbo.DriverMaster, and its exact column
  // set hasn't been confirmed against the live schema from this environment
  // (DB unreachable here) — so every field is read defensively across a few
  // plausible names rather than assuming one exact spelling.
  String _pick(Map<String, dynamic> d, List<String> keys) {
    for (final k in keys) {
      final v = d[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return "-";
  }

  String _name(Map<String, dynamic> d) =>
      _pick(d, ["DriverName", "FullName", "Name"]);
  String _mobile(Map<String, dynamic> d) =>
      _pick(d, ["Phone", "Mobile", "MobileNo", "ContactNo"]);
  String _license(Map<String, dynamic> d) =>
      _pick(d, ["LicenseNo", "DrivingLicenseNo", "DLNo", "License"]);
  String _status(Map<String, dynamic> d) {
    final active = d["IsActive"];
    if (active is bool) return active ? "Active" : "Inactive";
    return _pick(d, ["Status"]) == "-" ? "Active" : _pick(d, ["Status"]);
  }

  // ============================================================
  // FILTER
  // ============================================================

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredDrivers = allDrivers.where((driver) {
        final matchesSearch =
            _name(driver).toLowerCase().contains(search) ||
            _mobile(driver).toLowerCase().contains(search) ||
            _license(driver).toLowerCase().contains(search);

        final matchesStatus =
            selectedStatus == "All statuses" ||
            _status(driver) == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedStatus = "All statuses";
      filteredDrivers = List.from(allDrivers);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,

        title: const Text(
          "Drivers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadDrivers,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDrivers,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
          padding: const EdgeInsets.all(8),

          child: Column(
            children: [

              // ==================================================
              // FILTER CONTAINER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xffF1F4F8),
                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: const Color(0xffDCE3EC),
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {

                    final isSmall = width < 700;

                    // ==========================================
                    // MOBILE
                    // ==========================================

                    if (isSmall) {
                      return Column(
                        children: [

                          searchBox(),

                          const SizedBox(height: 10),

                          statusDropdown(),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              Expanded(
                                child: filterButton(),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: resetButton(),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // ==========================================
                    // DESKTOP / TABLET
                    // ==========================================

                    return Row(
                      children: [

                        SizedBox(
                          width: 300,
                          child: searchBox(),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 180,
                          child: statusDropdown(),
                        ),

                        const SizedBox(width: 12),

                        filterButton(),

                        const SizedBox(width: 12),

                        resetButton(),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TABLE
              // ==================================================

              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(
                      color: const Color(0xffDCE3EC),
                    ),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),

                    child: filteredDrivers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                "No drivers found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: SingleChildScrollView(
                        child: DataTable(

                          headingRowHeight: 48,

                          dataRowMinHeight: 66,
                          dataRowMaxHeight: 66,

                          columnSpacing: 35,

                          headingRowColor:
                              WidgetStateProperty.all(
                            const Color(0xffF8FAFD),
                          ),

                          // ======================================
                          // HEADERS
                          // ======================================

                          columns: const [

                            DataColumn(
                              label: Text("NAME"),
                            ),

                            DataColumn(
                              label: Text("MOBILE"),
                            ),

                            DataColumn(
                              label: Text("LICENSE"),
                            ),

                            DataColumn(
                              label: Text("STATUS"),
                            ),

                            DataColumn(
                              label: Text("CALL"),
                            ),

                            DataColumn(
                              label: Text("EDIT"),
                            ),
                          ],

                          // ======================================
                          // ROWS
                          // ======================================

                          rows: filteredDrivers.map((driver) {

                            return DataRow(
                              cells: [

                                // ==============================
                                // NAME
                                // ==============================

                                DataCell(
                                  Text(
                                    _name(driver),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // MOBILE
                                // ==============================

                                DataCell(
                                  Text(
                                    _mobile(driver),
                                    style: const TextStyle(
                                      color: Color(0xff334155),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // LICENSE
                                // ==============================

                                DataCell(
                                  Text(
                                    _license(driver),
                                    style: const TextStyle(
                                      color: Color(0xff334155),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // STATUS
                                // ==============================

                                DataCell(
                                  statusBadge(
                                    _status(driver),
                                  ),
                                ),

                                // ==============================
                                // CALL
                                // ==============================

                                DataCell(
                                  outlineButton(
                                    "Call",
                                    icon: Icons.phone,
                                    onPressed: () {
                                      callDriver(driver);
                                    },
                                  ),
                                ),

                                // ==============================
                                // EDIT
                                // ==============================

                                DataCell(
                                  outlineButton(
                                    "Edit",
                                    icon: Icons.edit,
                                    onPressed: () {
                                      editDriver(driver);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // TOTAL
              // ==================================================

              Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  "${filteredDrivers.length} drivers found",

                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

  Widget searchBox() {
    return TextField(
      controller: searchController,

      decoration: InputDecoration(
        hintText: "Search driver...",

        prefixIcon: const Icon(
          Icons.search,
          size: 20,
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget statusDropdown() {
    final statuses = [
      "All statuses",
      "Active",
      "Inactive",
    ];

    return DropdownButtonFormField<String>(
      value: selectedStatus,

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),
      ),

      items: statuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
      },
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton() {
    return ElevatedButton(
      onPressed: applyFilter,

      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      child: const Text(
        "Filter",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget resetButton() {
    return OutlinedButton(
      onPressed: resetFilter,

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff475569),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        side: const BorderSide(
          color: Color(0xffDCE3EC),
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      child: const Text(
        "Reset",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget statusBadge(String status) {

    Color background;
    Color textColor;

    if (status == "Active") {
      background = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else {
      background = const Color(0xffFEE2E2);
      textColor = const Color(0xffDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),

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
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            status,

            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget outlineButton(
    String text, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,

      icon: Icon(
        icon,
        size: 16,
      ),

      label: Text(text),

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff334155),

        side: const BorderSide(
          color: Color(0xffDCE3EC),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // CALL DRIVER — actually places the call via the device dialer
  // instead of just showing a snackbar.
  // ============================================================

  Future<void> callDriver(Map<String, dynamic> driver) async {
    final mobile = _mobile(driver);

    if (mobile == "-" || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No phone number on file for ${_name(driver)}")),
      );
      return;
    }

    final uri = Uri(scheme: "tel", path: mobile);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to place a call to $mobile")),
      );
    }
  }

  // ============================================================
  // EDIT DRIVER
  // ============================================================

  void editDriver(Map<String, dynamic> driver) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Edit ${_name(driver)}",
        ),
      ),
    );
  }
}
