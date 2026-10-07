import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'report_accident_screen.dart';
import 'add_fuel_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AuthService _authService = AuthService();

  late Future<List<dynamic>> movementFuture;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String searchText = "";

  // ============================================================
  // DATE / TIME FILTER
  // ============================================================

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    movementFuture = _authService.getmovement();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    setState(() {
      movementFuture = _authService.getmovement();
    });

    await movementFuture;
  }

  // ============================================================
  // FORMAT MOVEMENT TIME
  // ============================================================

  String formatMovementTime(dynamic value) {
    if (value == null) {
      return "";
    }

    try {
      final rawValue = value.toString().trim();

      if (rawValue.isEmpty) {
        return "";
      }

      final utcTime = DateTime.parse(rawValue);

      final indiaTime = tz.TZDateTime.from(
        utcTime.toUtc(),
        tz.getLocation("Asia/Kolkata"),
      );

      return DateFormat("dd MMM yyyy, hh:mm a").format(indiaTime);
    } catch (e) {
      debugPrint("MovementTime Format Error: $e");

      return value.toString();
    }
  }

  // ============================================================
  // GET INDIA MOVEMENT DATETIME
  // ============================================================

  DateTime? getIndiaMovementDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      final rawValue = value.toString().trim();

      if (rawValue.isEmpty) {
        return null;
      }

      final parsed = DateTime.parse(rawValue);

      final indiaTime = tz.TZDateTime.from(
        parsed.toUtc(),
        tz.getLocation("Asia/Kolkata"),
      );

      return DateTime(
        indiaTime.year,
        indiaTime.month,
        indiaTime.day,
        indiaTime.hour,
        indiaTime.minute,
        indiaTime.second,
      );
    } catch (e) {
      debugPrint("DateTime Parse Error: $e");

      return null;
    }
  }

  // ============================================================
  // OPEN DATE PICKER
  // ============================================================

  Future<void> selectDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select Movement Date",
      cancelText: "CANCEL",
      confirmText: "SELECT",
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
    });
  }

  // ============================================================
  // OPEN TIME PICKER
  // ============================================================

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: "Select Movement Time",
      cancelText: "CANCEL",
      confirmText: "SELECT",
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      selectedTime = pickedTime;
    });
  }

  // ============================================================
  // CLEAR DATE
  // ============================================================

  void clearDate() {
    setState(() {
      selectedDate = null;
    });
  }

  // ============================================================
  // CLEAR TIME
  // ============================================================

  void clearTime() {
    setState(() {
      selectedTime = null;
    });
  }

  // ============================================================
  // CLEAR ALL SEARCH
  // ============================================================

  void clearAllFilters() {
    _searchController.clear();

    setState(() {
      searchText = "";
      selectedDate = null;
      selectedTime = null;
    });
  }

  // ============================================================
  // DATE MATCH
  // ============================================================

  bool matchesSelectedDate(dynamic movementValue) {
    if (selectedDate == null) {
      return true;
    }

    final movementDate = getIndiaMovementDateTime(movementValue);

    if (movementDate == null) {
      return false;
    }

    return movementDate.year == selectedDate!.year &&
        movementDate.month == selectedDate!.month &&
        movementDate.day == selectedDate!.day;
  }

  // ============================================================
  // TIME MATCH
  // ============================================================

  bool matchesSelectedTime(dynamic movementValue) {
    if (selectedTime == null) {
      return true;
    }

    final movementDate = getIndiaMovementDateTime(movementValue);

    if (movementDate == null) {
      return false;
    }

    // Exact hour + minute match
    return movementDate.hour == selectedTime!.hour &&
        movementDate.minute == selectedTime!.minute;
  }

  // ============================================================
  // FILTER MOVEMENTS
  // ============================================================

  List<dynamic> filterMovements(List<dynamic> movements) {
    final query = searchText.trim().toLowerCase();

    return movements.where((item) {
      // ========================================================
      // DATE FILTER
      // ========================================================

      if (!matchesSelectedDate(item["MovementTime"])) {
        return false;
      }

      // ========================================================
      // TIME FILTER
      // ========================================================

      if (!matchesSelectedTime(item["MovementTime"])) {
        return false;
      }

      // ========================================================
      // TEXT SEARCH
      // ========================================================

      if (query.isEmpty) {
        return true;
      }

      // ========================================================
      // VEHICLE
      // ========================================================

      final vehicle = (item["RegistrationNo"] ?? "").toString().toLowerCase();

      // ========================================================
      // DRIVER
      // ========================================================

      final driver = (item["DriverName"] ?? "").toString().toLowerCase();

      // ========================================================
      // ODOMETER
      // ========================================================

      final odometer = (item["Odometer"] ?? "").toString().toLowerCase();

      // ========================================================
      // MOVEMENT TIME
      // ========================================================

      final rawMovementTime = (item["MovementTime"] ?? "")
          .toString()
          .toLowerCase();

      final formattedMovementTime = formatMovementTime(
        item["MovementTime"],
      ).toLowerCase();

      // ========================================================
      // MOVEMENT TYPE
      // ========================================================

      final movementType = (item["MovementType"] ?? "")
          .toString()
          .toLowerCase();

      // ========================================================
      // DIRECTION
      // ========================================================

      final direction = (item["Direction"] ?? "").toString().toLowerCase();

      // ========================================================
      // CUSTOMER
      // ========================================================

      final customer = (item["CustomerName"] ?? "").toString().toLowerCase();

      // ========================================================
      // SALES EXECUTIVE
      // ========================================================

      final salesExecutive = (item["SalesExecutive"] ?? "")
          .toString()
          .toLowerCase();

      // ========================================================
      // PURPOSE
      // ========================================================

      final purpose = (item["Purpose"] ?? "").toString().toLowerCase();

      // ========================================================
      // FROM LOCATION
      // ========================================================

      final fromLocation = (item["FromLocationName"] ?? "")
          .toString()
          .toLowerCase();

      // ========================================================
      // TO LOCATION
      // ========================================================

      final toLocation = (item["ToLocationName"] ?? "")
          .toString()
          .toLowerCase();

      // ========================================================
      // SEARCH
      // ========================================================

      return vehicle.contains(query) ||
          driver.contains(query) ||
          odometer.contains(query) ||
          rawMovementTime.contains(query) ||
          formattedMovementTime.contains(query) ||
          movementType.contains(query) ||
          direction.contains(query) ||
          customer.contains(query) ||
          salesExecutive.contains(query) ||
          purpose.contains(query) ||
          fromLocation.contains(query) ||
          toLocation.contains(query);
    }).toList();
  }

  // ============================================================
  // SEARCH / FILTER AREA
  // ============================================================

  // ============================================================
  // VEHICLE HELPERS FOR ADD FUEL
  // ============================================================

  int? getVehicleId(Map<String, dynamic> item) {
    final value =
        item["VehicleId"] ??
        item["VehicleID"] ??
        item["vehicleId"] ??
        item["Vehicle_Id"] ??
        item["Id"] ??
        item["ID"];
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String getRegistrationNo(Map<String, dynamic> item) {
    return (item["RegistrationNo"] ??
            item["RegistrationNumber"] ??
            item["registrationNo"] ??
            item["VehicleNo"] ??
            "")
        .toString()
        .trim();
  }

  String getVehicleModel(Map<String, dynamic> item) {
    return (item["Model"] ??
            item["VehicleModel"] ??
            item["model"] ??
            item["Vehicle_Model"] ??
            "")
        .toString()
        .trim();
  }

  Future<void> showAddFuelVehicleSelection() async {
    final movements = await movementFuture;
    if (!mounted) return;

    final Map<String, Map<String, dynamic>> vehicleMap = {};
    for (final rawItem in movements) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final registrationNo = getRegistrationNo(item);
      if (registrationNo.isNotEmpty) {
        vehicleMap.putIfAbsent(registrationNo.toUpperCase(), () => item);
      }
    }

    final vehicles = vehicleMap.values.toList();
    final searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final search = searchController.text.trim().toLowerCase();
          final filteredVehicles = vehicles.where((item) {
            final reg = getRegistrationNo(item).toLowerCase();
            final model = getVehicleModel(item).toLowerCase();
            return search.isEmpty ||
                reg.contains(search) ||
                model.contains(search);
          }).toList();

          return AlertDialog(
            title: const Text(
              "Select Vehicle",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 430,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search vehicle / model...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredVehicles.isEmpty
                        ? const Center(child: Text("No vehicle found"))
                        : ListView.separated(
                            itemCount: filteredVehicles.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredVehicles[index];
                              final registrationNo = getRegistrationNo(item);
                              final model = getVehicleModel(item);
                              final vehicleId = getVehicleId(item);

                              return ListTile(
                                leading: const Icon(
                                  Icons.directions_car,
                                  color: Color(0xff2458A6),
                                ),
                                title: Text(
                                  registrationNo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  model.isEmpty
                                      ? "Vehicle ID: ${vehicleId ?? '-'}"
                                      : "$model • Vehicle ID: ${vehicleId ?? '-'}",
                                ),
                                onTap: () {
                                  if (vehicleId == null) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Vehicle ID is missing for this vehicle.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (model.isEmpty) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Vehicle model is missing for this vehicle.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(dialogContext);
                                  Navigator.push(
                                    this.context,
                                    MaterialPageRoute(
                                      builder: (_) => AddFuelScreen(
                                        vehicleId: vehicleId,
                                        registrationNo: registrationNo,
                                        model: model,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("CANCEL"),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
  }

  void confirmAddFuel() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Add Fuel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Do you want to add fuel?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "NO",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showAddFuelVehicleSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2458A6),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "YES",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget searchArea() {
    final bool hasDate = selectedDate != null;

    final bool hasTime = selectedTime != null;

    final bool hasAnyFilter =
        searchText.trim().isNotEmpty || hasDate || hasTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: const Color(0xffEEF2F7),
      child: Column(
        children: [
          // ======================================================
          // TEXT SEARCH
          // ======================================================
          TextField(
            controller: _searchController,

            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },

            textInputAction: TextInputAction.search,

            decoration: InputDecoration(
              hintText: "Search Vehicle, Driver, Odometer...",

              prefixIcon: const Icon(Icons.search, color: Color(0xff2458A6)),

              suffixIcon: searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          searchText = "";
                        });
                      },
                    )
                  : null,

              filled: true,
              fillColor: Colors.white,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xff2458A6),
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // DATE + TIME BUTTONS
          // ======================================================
          Row(
            children: [
              // ==================================================
              // DATE BUTTON
              // ==================================================
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectDate,

                  icon: const Icon(Icons.calendar_month, size: 20),

                  label: Text(
                    hasDate
                        ? DateFormat("dd MMM yyyy").format(selectedDate!)
                        : "Select Date",

                    overflow: TextOverflow.ellipsis,
                  ),

                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,

                    foregroundColor: const Color(0xff2458A6),

                    side: BorderSide(
                      color: hasDate
                          ? const Color(0xff2458A6)
                          : Colors.grey.shade300,
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 13),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // TIME BUTTON
              // ==================================================
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectTime,

                  icon: const Icon(Icons.access_time, size: 20),

                  label: Text(
                    hasTime ? selectedTime!.format(context) : "Select Time",

                    overflow: TextOverflow.ellipsis,
                  ),

                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,

                    foregroundColor: const Color(0xff2458A6),

                    side: BorderSide(
                      color: hasTime
                          ? const Color(0xff2458A6)
                          : Colors.grey.shade300,
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 13),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // CLEAR ALL
              // ==================================================
              if (hasAnyFilter)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    tooltip: "Clear Filters",

                    onPressed: clearAllFilters,

                    icon: const Icon(Icons.filter_alt_off, color: Colors.red),
                  ),
                ),
            ],
          ),

          // ======================================================
          // SELECTED FILTER CHIPS
          // ======================================================
          if (hasDate || hasTime)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (hasDate)
                    InputChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),

                      label: Text(
                        DateFormat("dd MMM yyyy").format(selectedDate!),
                      ),

                      onDeleted: clearDate,

                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),

                  if (hasDate && hasTime) const SizedBox(width: 6),

                  if (hasTime)
                    InputChip(
                      avatar: const Icon(Icons.access_time, size: 16),

                      label: Text(selectedTime!.format(context)),

                      onDeleted: clearTime,

                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT COUNT
  // ============================================================

  Widget resultCount(int total, int filtered) {
    final bool hasFilter =
        searchText.trim().isNotEmpty ||
        selectedDate != null ||
        selectedTime != null;

    if (!hasFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: const Color(0xffEEF2F7),
      child: Text(
        "$filtered result${filtered == 1 ? "" : "s"} found from $total movement${total == 1 ? "" : "s"}",
        style: const TextStyle(
          color: Color(0xff2458A6),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),

      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(color: Color(0xff2458A6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📋 Today's Movements",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Security • Main Gate",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==============================================
                  // LOGOUT
                  // ==============================================
                  TextButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();

                      await prefs.clear();

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // ADD FUEL + REPORT ACCIDENT
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              color: const Color(0xffEEF2F7),
              child: Row(
                children: [
                  // ==================================================
                  // ADD FUEL - LEFT
                  // ==================================================
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: confirmAddFuel,
                      icon: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 19,
                      ),
                      label: const Text(
                        "Add Fuel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2458A6),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==================================================
                  // REPORT ACCIDENT - RIGHT
                  // ==================================================
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportAccidentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      label: const Text(
                        "Report Accident",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // SEARCH AREA
            // ====================================================
            searchArea(),

            // ====================================================
            // MOVEMENT DATA
            // ====================================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,

                child: FutureBuilder<List<dynamic>>(
                  future: movementFuture,

                  builder: (context, snapshot) {
                    // ============================================
                    // LOADING
                    // ============================================

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // ============================================
                    // ERROR
                    // ============================================

                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }

                    // ============================================
                    // NO DATA
                    // ============================================

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Icon(
                            Icons.directions_car_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Text(
                              "No Movement Found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // ============================================
                    // ALL DATA
                    // ============================================

                    final allMovements = snapshot.data!;

                    // ============================================
                    // FILTER DATA
                    // ============================================

                    final movements = filterMovements(allMovements);

                    return Column(
                      children: [
                        // ==========================================
                        // RESULT COUNT
                        // ==========================================
                        resultCount(allMovements.length, movements.length),

                        // ==========================================
                        // LIST
                        // ==========================================
                        Expanded(
                          child: movements.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 80),
                                    Icon(
                                      Icons.search_off,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 15),
                                    Center(
                                      child: Text(
                                        "No matching movement found",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        "Try another search, date or time",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: movements.length,
                                  itemBuilder: (context, index) {
                                    return movementTile(movements[index]);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOVEMENT TILE
  // ============================================================

  Widget movementTile(Map<String, dynamic> item) {
    final direction = (item["Direction"] ?? "").toString().toLowerCase();

    final bool isEntry = direction == "entry";

    final String movementTime = formatMovementTime(item["MovementTime"]);

    final vehicle = (item["RegistrationNo"] ?? "-").toString();

    final driver = (item["DriverName"] ?? "-").toString();

    final movementType = (item["MovementType"] ?? "-").toString();

    final customer = (item["CustomerName"] ?? "-").toString();

    final salesExecutive = (item["SalesExecutive"] ?? "-").toString();

    final purpose = (item["Purpose"] ?? "-").toString();

    final fromLocation = (item["FromLocationName"] ?? "-").toString();

    final toLocation = (item["ToLocationName"] ?? "-").toString();

    final odometer = (item["Odometer"] ?? "-").toString();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isEntry ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        // ========================================================
        // ICON
        // ========================================================
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isEntry ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEntry ? Icons.login : Icons.logout,
            color: isEntry ? Colors.green : Colors.red,
          ),
        ),

        // ========================================================
        // VEHICLE
        // ========================================================
        title: Text(
          vehicle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // ========================================================
        // DETAILS
        // ========================================================
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Driver : $driver"),

              Text("Movement : $movementType"),

              const SizedBox(height: 6),

              // ================================================
              // DIRECTION
              // ================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEntry ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  direction.isEmpty ? "-" : direction.toUpperCase(),
                  style: TextStyle(
                    color: isEntry ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text("Customer : $customer"),

              Text("Sales Executive : $salesExecutive"),

              Text("Purpose : $purpose"),

              Text("From Location : $fromLocation"),

              Text("To Location : $toLocation"),

              Text("Odometer : $odometer km"),

              const SizedBox(height: 8),

              // ================================================
              // DATE TIME
              // ================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      movementTime.isEmpty ? "-" : movementTime,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ========================================================
        // ARROW
        // ========================================================
        trailing: Icon(
          isEntry ? Icons.arrow_downward : Icons.arrow_upward,
          color: isEntry ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
