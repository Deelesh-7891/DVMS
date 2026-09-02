import 'package:flutter/material.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedModel = "All models";
  String selectedStatus = "All statuses";

  final List<Map<String, dynamic>> allVehicles = [
    {
      "regNo": "RJ18SS2800",
      "model": "HONDA SHINE",
      "variant": "Shine",
      "fuel": "PETROL",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CH4954",
      "model": "Alto 800",
      "variant": "LXI",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CH1505",
      "model": "Alto 800",
      "variant": "VXI",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CF8745",
      "model": "WagonR",
      "variant": "ZXI AGS",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CJ2696",
      "model": "S-Presso",
      "variant": "VXI AGS",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CQ9977",
      "model": "Celerio",
      "variant": "ZXI+",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ45CT7222",
      "model": "Alto K10",
      "variant": "VXI+ 1.0L",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ60CA7012",
      "model": "Swift",
      "variant": "ZXI+",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
    {
      "regNo": "RJ60CC4712",
      "model": "Dzire",
      "variant": "ZXI+",
      "fuel": "Petrol",
      "odometer": "0 km",
      "location": "-",
      "status": "Available",
      "fitness": "Not required",
    },
  ];

  List<Map<String, dynamic>> filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    filteredVehicles = List.from(allVehicles);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredVehicles = allVehicles.where((vehicle) {
        final matchesSearch =
            vehicle["regNo"].toString().toLowerCase().contains(search);

        final matchesModel =
            selectedModel == "All models" ||
            vehicle["model"] == selectedModel;

        final matchesStatus =
            selectedStatus == "All statuses" ||
            vehicle["status"] == selectedStatus;

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
      ),

      body: SafeArea(
        child: Padding(
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
                    child: SingleChildScrollView(
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
                                    vehicle["regNo"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // MODEL
                                DataCell(
                                  Text(
                                    vehicle["model"],
                                    style: const TextStyle(
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // VARIANT
                                DataCell(
                                  Text(vehicle["variant"]),
                                ),

                                // FUEL
                                DataCell(
                                  Text(vehicle["fuel"]),
                                ),

                                // ODOMETER
                                DataCell(
                                  Text(vehicle["odometer"]),
                                ),

                                // LOCATION
                                DataCell(
                                  Text(vehicle["location"]),
                                ),

                                // STATUS
                                DataCell(
                                  statusBadge(
                                    vehicle["status"],
                                  ),
                                ),

                                // FITNESS
                                DataCell(
                                  fitnessBadge(
                                    vehicle["fitness"],
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
          .map((e) => e["model"].toString())
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
      "Available",
      "On Demo",
      "Service",
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
    } else if (status == "On Demo") {
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
  // QR
  // ============================================================

  void showQR(Map<String, dynamic> vehicle) {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Vehicle QR",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_2,
                size: 150,
              ),
              const SizedBox(height: 15),
              Text(
                vehicle["regNo"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
          "Allocate ${vehicle["regNo"]}",
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
          "Edit ${vehicle["regNo"]}",
        ),
      ),
    );
  }
}