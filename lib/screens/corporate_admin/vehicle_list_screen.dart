import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  String selectedModel = "All models";
  String selectedStatus = "All statuses";

  List<Map<String, dynamic>> allVehicles = [];
  List<Map<String, dynamic>> filteredVehicles = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _authService.getVehicles();

      setState(() {
        allVehicles = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredVehicles = List.from(allVehicles);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = "Unable to load vehicles: $e";
      });
    }
  }

  // Server field names, read defensively since not every vehicle has every
  // field populated (e.g. LocationName/CityName are null on a lot of rows —
  // see the DVMS backend notes on VehicleMaster.LOC_CD coverage).
  String _regNo(Map<String, dynamic> v) =>
      (v["RegistrationNo"] ?? "-").toString();
  String _model(Map<String, dynamic> v) => (v["Model"] ?? "-").toString();
  String _variant(Map<String, dynamic> v) => (v["Variant"] ?? "-").toString();
  String _fuel(Map<String, dynamic> v) => (v["FuelType"] ?? "-").toString();
  String _odometer(Map<String, dynamic> v) {
    final odo = v["CurrentOdometer"];
    if (odo == null) return "-";
    return "$odo km";
  }

  String _location(Map<String, dynamic> v) {
    final loc = v["LocationName"] ?? v["CityName"];
    if (loc == null || loc.toString().trim().isEmpty) return "-";
    return loc.toString();
  }

  String _status(Map<String, dynamic> v) => (v["Status"] ?? "-").toString();

  String _fitness(Map<String, dynamic> v) {
    final required = v["FitnessRequired"];
    if (required == true) return "Required";
    return "Not required";
  }

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredVehicles = allVehicles.where((vehicle) {
        final matchesSearch = _regNo(vehicle).toLowerCase().contains(search);

        final matchesModel =
            selectedModel == "All models" || _model(vehicle) == selectedModel;

        final matchesStatus =
            selectedStatus == "All statuses" ||
            _status(vehicle) == selectedStatus;

        return matchesSearch && matchesModel && matchesStatus;
      }).toList();
    });
  }

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedModel = "All models";
      selectedStatus = "All statuses";
      filteredVehicles = List.from(allVehicles);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        title: const Text(
          "Vehicles",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadVehicles,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

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
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVehicles,
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

              // =========================
              // FILTER SECTION
              // =========================

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

                    if (isSmall) {
                      return Column(
                        children: [
                          searchBox(),
                          const SizedBox(height: 10),
                          modelDropdown(),
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

                    return Row(
                      children: [
                        SizedBox(
                          width: 245,
                          child: searchBox(),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 200,
                          child: modelDropdown(),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 140,
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

              // =========================
              // VEHICLE TABLE
              // =========================

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
                    child: filteredVehicles.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                "No vehicles found",
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

                          columnSpacing: 30,

                          headingRowColor:
                              WidgetStateProperty.all(
                            const Color(0xffF8FAFD),
                          ),

                          columns: const [

                            DataColumn(
                              label: Text("REG NO"),
                            ),

                            DataColumn(
                              label: Text("MODEL"),
                            ),

                            DataColumn(
                              label: Text("VARIANT"),
                            ),

                            DataColumn(
                              label: Text("FUEL"),
                            ),

                            DataColumn(
                              label: Text("ODOMETER"),
                            ),

                            DataColumn(
                              label: Text("LOCATION"),
                            ),

                            DataColumn(
                              label: Text("STATUS"),
                            ),

                            DataColumn(
                              label: Text("FITNESS"),
                            ),

                            DataColumn(
                              label: Text("QR"),
                            ),

                            DataColumn(
                              label: Text("ALLOCATION"),
                            ),

                            DataColumn(
                              label: Text("EDIT"),
                            ),
                          ],

                          rows: filteredVehicles.map((vehicle) {

                            return DataRow(
                              cells: [

                                // REG NO
                                DataCell(
                                  Text(
                                    _regNo(vehicle),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // MODEL
                                DataCell(
                                  Text(
                                    _model(vehicle),
                                    style: const TextStyle(
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // VARIANT
                                DataCell(
                                  Text(_variant(vehicle)),
                                ),

                                // FUEL
                                DataCell(
                                  Text(_fuel(vehicle)),
                                ),

                                // ODOMETER
                                DataCell(
                                  Text(_odometer(vehicle)),
                                ),

                                // LOCATION
                                DataCell(
                                  Text(_location(vehicle)),
                                ),

                                // STATUS
                                DataCell(
                                  statusBadge(
                                    _status(vehicle),
                                  ),
                                ),

                                // FITNESS
                                DataCell(
                                  fitnessBadge(
                                    _fitness(vehicle),
                                  ),
                                ),

                                // QR
                                DataCell(
                                  outlineButton(
                                    "QR",
                                    onPressed: () {
                                      showQR(vehicle);
                                    },
                                  ),
                                ),

                                // ALLOCATE
                                DataCell(
                                  outlineButton(
                                    "Allocate",
                                    onPressed: () {
                                      allocateVehicle(vehicle);
                                    },
                                  ),
                                ),

                                // EDIT
                                DataCell(
                                  outlineButton(
                                    "Edit",
                                    onPressed: () {
                                      editVehicle(vehicle);
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

              // TOTAL
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${filteredVehicles.length} vehicles found",
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
  // SEARCH
  // ============================================================

  Widget searchBox() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search reg no...",
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
  // MODEL DROPDOWN
  // ============================================================

  Widget modelDropdown() {

    final models = [
      "All models",
      ...allVehicles
          .map((e) => _model(e))
          .toSet(),
    ];

    return DropdownButtonFormField<String>(
      value: selectedModel,
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
      items: models.map((model) {
        return DropdownMenuItem(
          value: model,
          child: Text(model),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedModel = value!;
        });
      },
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget statusDropdown() {

    final statuses = [
      "All statuses",
      ...allVehicles.map((e) => _status(e)).toSet(),
    ];

    return DropdownButtonFormField<String>(
      value: statuses.contains(selectedStatus)
          ? selectedStatus
          : "All statuses",
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
        return DropdownMenuItem(
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

    if (status == "Available") {
      background = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else if (status == "OnDemo" || status == "On Demo") {
      background = const Color(0xffDBEAFE);
      textColor = const Color(0xff2563EB);
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
  // FITNESS BADGE
  // ============================================================

  Widget fitnessBadge(String fitness) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            size: 8,
            color: Color(0xff64748B),
          ),
          const SizedBox(width: 7),
          Text(
            fitness,
            style: const TextStyle(
              color: Color(0xff334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OUTLINE BUTTON
  // ============================================================

  Widget outlineButton(
    String text, {
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
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
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // QR — fetches the real QR code image from the server instead of
  // showing a placeholder icon.
  // ============================================================

  void showQR(Map<String, dynamic> vehicle) {
    final vehicleId = vehicle["VehicleId"];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Vehicle QR"),
          content: SizedBox(
            width: 220,
            height: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<Uint8List>(
                  future: _authService.getVehicleQr(vehicleId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }

                    return Image.memory(
                      snapshot.data!,
                      width: 180,
                      height: 180,
                    );
                  },
                ),
                const SizedBox(height: 15),
                Text(
                  _regNo(vehicle),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ALLOCATE
  // ============================================================

  void allocateVehicle(Map<String, dynamic> vehicle) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Allocate ${_regNo(vehicle)}",
        ),
      ),
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  void editVehicle(Map<String, dynamic> vehicle) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Edit ${_regNo(vehicle)}",
        ),
      ),
    );
  }
}
