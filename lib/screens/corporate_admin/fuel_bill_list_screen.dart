
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../core/widgets/photo_thumbnail.dart';
import '../../core/widgets/voice_search_button.dart';
import '../../services/auth_service.dart';
import '../../screens/security/add_fuel_screen.dart';

class FuelBillListScreen extends StatefulWidget {
  const FuelBillListScreen({super.key});

  @override
  State<FuelBillListScreen> createState() => _FuelBillListScreenState();
}

class _FuelBillListScreenState extends State<FuelBillListScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController searchController = TextEditingController();

  final TextEditingController vehicleSearchController = TextEditingController();

  String selectedFuel = "All fuels";

  List<Map<String, dynamic>> allFuelBills = [];
  List<Map<String, dynamic>> filteredFuelBills = [];

  // Complete vehicle list
  List<Map<String, dynamic>> vehiclesList = [];
  List<Map<String, dynamic>> filteredVehiclesList = [];

  bool _loading = true;
  bool _vehiclesLoading = false;

  String? _loadError;

  @override
  void initState() {
    super.initState();

    _loadFuelBills();
    _loadVehicles();
  }

  @override
  void dispose() {
    searchController.dispose();
    vehicleSearchController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD FUEL BILLS
  // =========================================================

  Future<void> _loadFuelBills() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final data = await _authService.getFuelBills();

      if (!mounted) return;

      final bills = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        allFuelBills = bills;

        filteredFuelBills = List<Map<String, dynamic>>.from(allFuelBills);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = "Unable to load fuel bills: $e";
      });
    }
  }

  // =========================================================
  // LOAD VEHICLES
  // =========================================================

  Future<void> _loadVehicles() async {
    if (mounted) {
      setState(() {
        _vehiclesLoading = true;
      });
    }

    try {
      /*
       IMPORTANT:

       AuthService mein ye method hona chahiye:

       Future<List<dynamic>> getVehicles()

       Agar aapke method ka naam different hai,
       sirf neeche getVehicles() ko apne method name
       se replace karein.
      */

      final data = await _authService.getVehicles();

      if (!mounted) return;

      final vehicles = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((vehicle) {
            final id = getVehicleId(vehicle);

            return id != null && id > 0;
          })
          .toList();

      // Remove duplicate VehicleId
      final Map<int, Map<String, dynamic>> uniqueVehicles = {};

      for (final vehicle in vehicles) {
        final id = getVehicleId(vehicle);

        if (id != null) {
          uniqueVehicles[id] = vehicle;
        }
      }

      final finalVehicles = uniqueVehicles.values.toList();

      // Sort by registration number
      finalVehicles.sort(
        (a, b) => getRegistrationNo(
          a,
        ).toLowerCase().compareTo(getRegistrationNo(b).toLowerCase()),
      );

      setState(() {
        vehiclesList = finalVehicles;

        filteredVehiclesList = List<Map<String, dynamic>>.from(vehiclesList);

        _vehiclesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _vehiclesLoading = false;
      });

      debugPrint("Vehicle API Error: $e");
    }
  }

  // =========================================================
  // VEHICLE ID
  // =========================================================

  int? getVehicleId(Map<String, dynamic> item) {
    final value =
        item["VehicleId"] ??
        item["VehicleID"] ??
        item["vehicleId"] ??
        item["Vehicle_Id"] ??
        item["Id"] ??
        item["ID"];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  // =========================================================
  // REGISTRATION NUMBER
  // =========================================================

  String getRegistrationNo(Map<String, dynamic> item) {
    return (item["RegistrationNo"] ??
            item["RegistrationNumber"] ??
            item["registrationNo"] ??
            item["VehicleNo"] ??
            item["VehicleNumber"] ??
            "")
        .toString()
        .trim();
  }

  // =========================================================
  // VEHICLE MODEL
  // =========================================================

  String getVehicleModel(Map<String, dynamic> item) {
    return (item["Model"] ??
            item["VehicleModel"] ??
            item["model"] ??
            item["Vehicle_Model"] ??
            item["VehicleName"] ??
            "")
        .toString()
        .trim();
  }

  // =========================================================
  // BILL NO
  // =========================================================

  String _billNo(Map<String, dynamic> b) {
    return "FB-${b["FuelId"] ?? "-"}";
  }

  // =========================================================
  // VEHICLE NO FOR BILL
  // =========================================================

  String _vehicleNo(Map<String, dynamic> b) {
    return (b["RegistrationNo"] ??
            b["RegistrationNumber"] ??
            b["VehicleNo"] ??
            "-")
        .toString();
  }

  // =========================================================
  // DATE
  // =========================================================

  String _date(Map<String, dynamic> b) {
    final raw = b["TxnDate"];

    if (raw == null) {
      return "-";
    }

    try {
      return DateFormat("dd-MM-yyyy").format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  // =========================================================
  // FUEL
  // =========================================================

  String _fuel(Map<String, dynamic> b) {
    return (b["FuelType"] ?? "-").toString();
  }

  // =========================================================
  // LITRES
  // =========================================================

  String _litres(Map<String, dynamic> b) {
    return b["Quantity"] == null ? "-" : "${b["Quantity"]} L";
  }

  // =========================================================
  // AMOUNT
  // =========================================================

  String _amount(Map<String, dynamic> b) {
    return b["Amount"] == null ? "-" : "₹${b["Amount"]}";
  }

  // =========================================================
  // VENDOR
  // =========================================================

  String _vendor(Map<String, dynamic> b) {
    return (b["FuelStation"] ?? "-").toString();
  }

  // =========================================================
  // PHOTO
  // =========================================================

  String? _photoPath(Map<String, dynamic> b) {
    return b["PhotoPath"]?.toString();
  }

  // =========================================================
  // FUEL FILTER
  // =========================================================

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredFuelBills = allFuelBills.where((bill) {
        final matchesSearch =
            _billNo(bill).toLowerCase().contains(search) ||
            _vehicleNo(bill).toLowerCase().contains(search);

        final matchesFuel =
            selectedFuel == "All fuels" || _fuel(bill) == selectedFuel;

        return matchesSearch && matchesFuel;
      }).toList();
    });
  }

  // =========================================================
  // RESET FILTER
  // =========================================================

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedFuel = "All fuels";

      filteredFuelBills = List<Map<String, dynamic>>.from(allFuelBills);
    });
  }

  // =========================================================
  // ADD FUEL
  // =========================================================

  void openAddFuel() {
    openVehicleSelection();
  }

  // =========================================================
  // VEHICLE SEARCH
  // =========================================================

  void searchVehicles(String value) {
    final search = value.trim().toLowerCase();

    setState(() {
      if (search.isEmpty) {
        filteredVehiclesList = List<Map<String, dynamic>>.from(vehiclesList);

        return;
      }

      filteredVehiclesList = vehiclesList.where((vehicle) {
        final registration = getRegistrationNo(vehicle).toLowerCase();

        final model = getVehicleModel(vehicle).toLowerCase();

        final id = getVehicleId(vehicle)?.toString() ?? "";

        return registration.contains(search) ||
            model.contains(search) ||
            id.contains(search);
      }).toList();
    });
  }

  // =========================================================
  // VEHICLE SELECTION
  // =========================================================

  void openVehicleSelection() {
    vehicleSearchController.clear();

    filteredVehiclesList = List<Map<String, dynamic>>.from(vehiclesList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // ========================================
                    // HEADER
                    // ========================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xffE8F0FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Color(0xff2458A6),
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Select Vehicle",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Select vehicle for fuel entry",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    // ========================================
                    // SEARCH
                    // ========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: vehicleSearchController,

                        onChanged: (value) {
                          final search = value.trim().toLowerCase();

                          setSheetState(() {
                            if (search.isEmpty) {
                              filteredVehiclesList =
                                  List<Map<String, dynamic>>.from(vehiclesList);
                            } else {
                              filteredVehiclesList = vehiclesList.where((
                                vehicle,
                              ) {
                                final reg = getRegistrationNo(
                                  vehicle,
                                ).toLowerCase();

                                final model = getVehicleModel(
                                  vehicle,
                                ).toLowerCase();

                                final id =
                                    getVehicleId(vehicle)?.toString() ?? "";

                                return reg.contains(search) ||
                                    model.contains(search) ||
                                    id.contains(search);
                              }).toList();
                            }
                          });
                        },

                        decoration: InputDecoration(
                          hintText: "Search vehicle number / model / ID",

                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xff2458A6),
                          ),

                          suffixIcon: vehicleSearchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    vehicleSearchController.clear();

                                    setSheetState(() {
                                      filteredVehiclesList =
                                          List<Map<String, dynamic>>.from(
                                            vehiclesList,
                                          );
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,

                          filled: true,
                          fillColor: const Color(0xffF8FAFC),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xffDCE3EC),
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xffDCE3EC),
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xff2458A6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ========================================
                    // COUNT
                    // ========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Text(
                            "${filteredVehiclesList.length} vehicles",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff475569),
                            ),
                          ),

                          const Spacer(),

                          if (_vehiclesLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ========================================
                    // VEHICLE LIST
                    // ========================================
                    Expanded(
                      child: _vehiclesLoading && vehiclesList.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : filteredVehiclesList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_car_outlined,
                                    size: 55,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    vehiclesList.isEmpty
                                        ? "No vehicles found"
                                        : "No matching vehicle",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: filteredVehiclesList.length,
                              itemBuilder: (context, index) {
                                final vehicle = filteredVehiclesList[index];

                                final vehicleId = getVehicleId(vehicle);

                                final registrationNo = getRegistrationNo(
                                  vehicle,
                                );

                                final model = getVehicleModel(vehicle);

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xffE2E8F0),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),

                                    leading: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffE8F0FE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Color(0xff2458A6),
                                      ),
                                    ),

                                    title: Text(
                                      registrationNo.isEmpty
                                          ? "Vehicle"
                                          : registrationNo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if (model.isNotEmpty) model,
                                          if (vehicleId != null) "",
                                          // "ID: $vehicleId",
                                        ].join(
                                          // " • ",
                                          " ",
                                        ),
                                      ),
                                    ),

                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xff64748B),
                                    ),

                                    onTap: () {
                                      if (vehicleId == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Vehicle ID is missing.",
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      Navigator.pop(sheetContext);

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddFuelScreen(
                                            vehicleId: vehicleId,
                                            registrationNo: registrationNo,
                                            model: model,
                                          ),
                                        ),
                                      ).then((_) {
                                        _loadFuelBills();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,

        title: const Text(
          "Fuel Bills",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          // ================================================
          // ADD FUEL
          // ================================================
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ElevatedButton.icon(
              onPressed: _loading ? null : openAddFuel,

              icon: const Icon(Icons.local_gas_station, size: 18),

              label: const Text(
                "Add Fuel",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff2458A6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // ================================================
          // REFRESH
          // ================================================
          IconButton(
            onPressed: _loading
                ? null
                : () {
                    _loadFuelBills();
                    _loadVehicles();
                  },

            icon: const Icon(Icons.refresh),

            tooltip: "Refresh",
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
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
                        onPressed: _loadFuelBills,
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
                    // ==================================
                    // FILTER CARD
                    // ==================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F4F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffDCE3EC)),
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

                                fuelDropdown(),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(child: filterButton()),

                                    const SizedBox(width: 10),

                                    Expanded(child: resetButton()),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              SizedBox(width: 260, child: searchBox()),

                              const SizedBox(width: 12),

                              SizedBox(width: 160, child: fuelDropdown()),

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

                    // ==================================
                    // TABLE
                    // ==================================
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffDCE3EC)),
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),

                          child: filteredFuelBills.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      "No fuel bills found",
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

                                      headingRowColor: WidgetStateProperty.all(
                                        const Color(0xffF8FAFD),
                                      ),

                                      columns: const [
                                        DataColumn(label: Text("BILL NO")),
                                        DataColumn(label: Text("VEHICLE NO")),
                                        DataColumn(label: Text("DATE")),
                                        DataColumn(label: Text("FUEL")),
                                        DataColumn(label: Text("LITRES")),
                                        DataColumn(label: Text("AMOUNT")),
                                        DataColumn(label: Text("VENDOR")),
                                        DataColumn(label: Text("PHOTO")),
                                        DataColumn(label: Text("VIEW")),
                                      ],

                                      rows: filteredFuelBills.map((bill) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                _billNo(bill),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xff172033),
                                                ),
                                              ),
                                            ),

                                            DataCell(
                                              Text(
                                                _vehicleNo(bill),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),

                                            DataCell(Text(_date(bill))),

                                            DataCell(Text(_fuel(bill))),

                                            DataCell(Text(_litres(bill))),

                                            DataCell(
                                              Text(
                                                _amount(bill),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xff172033),
                                                ),
                                              ),
                                            ),

                                            DataCell(Text(_vendor(bill))),

                                            DataCell(
  IconButton(
    icon: const Icon(
      Icons.image_outlined,
      color: Color(0xff2458A6),
    ),
    onPressed: () => viewBill(bill),
  ),
),

                                            DataCell(
                                              outlineButton(
                                                "View",
                                                icon: Icons.visibility,
                                                onPressed: () => viewBill(bill),
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

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${filteredFuelBills.length} fuel bills found",
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

  // =========================================================
  // SEARCH BOX
  // =========================================================

  Widget searchBox() {
    return TextField(
      controller: searchController,

      onSubmitted: (_) => applyFilter(),

      decoration: InputDecoration(
        hintText: "Search bill / vehicle no...",

        prefixIcon: const Icon(Icons.search, size: 20),

        suffixIcon: VoiceSearchButton(
          onResult: (digits) {
            searchController.text = digits;

            applyFilter();
          },
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(horizontal: 14),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),
    );
  }

  // =========================================================
  // FUEL DROPDOWN
  // =========================================================

  Widget fuelDropdown() {
    final fuels = [
      "All fuels",
      ...allFuelBills.map((e) => _fuel(e)).where((e) => e != "-").toSet(),
    ];

    return DropdownButtonFormField<String>(
      initialValue: fuels.contains(selectedFuel) ? selectedFuel : "All fuels",

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(horizontal: 14),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),

      items: fuels
          .map(
            (fuel) => DropdownMenuItem<String>(value: fuel, child: Text(fuel)),
          )
          .toList(),

      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedFuel = value;
        });

        applyFilter();
      },
    );
  }

  // =========================================================
  // FILTER BUTTON
  // =========================================================

  Widget filterButton() {
    return ElevatedButton(
      onPressed: applyFilter,

      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2458A6),

        foregroundColor: Colors.white,

        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      child: const Text(
        "Filter",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // =========================================================
  // RESET BUTTON
  // =========================================================

  Widget resetButton() {
    return OutlinedButton(
      onPressed: resetFilter,

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff475569),

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

        side: const BorderSide(color: Color(0xffDCE3EC)),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // =========================================================
  // OUTLINE BUTTON
  // =========================================================

  Widget outlineButton(
    String text, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,

      icon: Icon(icon, size: 16),

      label: Text(text),

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff334155),

        side: const BorderSide(color: Color(0xffDCE3EC)),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // =========================================================
  // VIEW BILL
  // =========================================================

  void viewBill(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Fuel Bill ${_billNo(bill)}"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vehicle: ${_vehicleNo(bill)}"),

                const SizedBox(height: 8),

                Text("Date: ${_date(bill)}"),

                const SizedBox(height: 8),

                Text("Fuel: ${_fuel(bill)}"),

                const SizedBox(height: 8),

                Text("Litres: ${_litres(bill)}"),

                const SizedBox(height: 8),

                Text("Amount: ${_amount(bill)}"),

                const SizedBox(height: 8),

                Text("Vendor: ${_vendor(bill)}"),

                const SizedBox(height: 12),

                PhotoThumbnail(photoPath: _photoPath(bill), size: 120),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),

              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
