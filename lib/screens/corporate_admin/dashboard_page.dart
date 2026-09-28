
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import 'vehicle_list_screen.dart';
import 'driver_list_screen.dart';
import 'fuel_bill_list_screen.dart';
import 'service_list_screen.dart';
import 'insurance_list_screen.dart';
import 'reports_screen.dart';
import 'qr_movement.dart';
import 'fastag.dart';
import 'challans.dart';
import 'puc.dart';
import 'expenses.dart';
import 'fitness.dart';
import 'employees.dart';
import 'accidents.dart';
import 'allocations.dart';
import 'users.dart';
import 'mileage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();

  Map<String, dynamic> dashboardData = {};

  bool isLoading = true;
  bool hasError = false;

  String fullName = "";
  String errorMessage = "";

  // Prevent multiple navigation calls.
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    debugPrint("======================================");
    debugPrint("DASHBOARD INIT START");
    debugPrint("======================================");

    // Load logged-in user's name.
    loadUserName();

    // Load dashboard only once after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      debugPrint("DASHBOARD FIRST FRAME COMPLETE");

      loadDashboard();
    });
  }

  // ============================================================
  // GET GREETING BASED ON DEVICE LOCAL TIME
  // ============================================================

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  // ============================================================
  // LOAD USER FULL NAME
  // ============================================================

  Future<void> loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedName = prefs.getString("fullName") ?? "";

      debugPrint("Saved FullName: $savedName");

      if (!mounted) return;

      setState(() {
        fullName = savedName;
      });
    } catch (e) {
      debugPrint("LOAD FULL NAME ERROR: $e");
    }
  }

  // ============================================================
  // DASHBOARD API
  // ============================================================

  Future<void> loadDashboard() async {
    if (!mounted) return;

    debugPrint("======================================");
    debugPrint("DASHBOARD LOAD START");
    debugPrint("======================================");

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = "";
    });

    final stopwatch = Stopwatch()..start();

    try {
      debugPrint("Calling DashboardSummary API...");

      final data = await _authService.DashboardSummary();

      stopwatch.stop();

      debugPrint(
        "Dashboard API completed in "
        "${stopwatch.elapsedMilliseconds} ms",
      );

      debugPrint(
        "Dashboard response type: ${data.runtimeType}",
      );

      if (!mounted) {
        debugPrint("Dashboard disposed before API completed");
        return;
      }

      Map<String, dynamic> safeData = {};

      if (data is Map<String, dynamic>) {
        safeData = data;
      } else if (data is Map) {
        safeData = Map<String, dynamic>.from(data);
      }

      setState(() {
        dashboardData = safeData;
        isLoading = false;
        hasError = false;
      });

      debugPrint("DASHBOARD STATE UPDATED");
      debugPrint("DASHBOARD LOAD COMPLETE");
      debugPrint("======================================");
    } catch (e, stackTrace) {
      stopwatch.stop();

      debugPrint("======================================");
      debugPrint("DASHBOARD ERROR");
      debugPrint(
        "Time: ${stopwatch.elapsedMilliseconds} ms",
      );
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      debugPrint("======================================");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
        dashboardData = {};
      });
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (_isNavigating) return;

    _isNavigating = true;

    debugPrint("LOGOUT START");

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();

      debugPrint("SHARED PREFERENCES CLEARED");

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );

      debugPrint("NAVIGATED TO LOGIN");
    } catch (e) {
      debugPrint("LOGOUT ERROR: $e");

      _isNavigating = false;
    }
  }

  // ============================================================
  // SAFE NAVIGATION
  // ============================================================

  void _openPage(
    Widget page,
    String pageName,
  ) {
    if (!mounted) return;

    if (_isNavigating) {
      debugPrint(
        "Navigation blocked: already navigating",
      );
      return;
    }

    _isNavigating = true;

    debugPrint("======================================");
    debugPrint("NAVIGATION START");
    debugPrint("PAGE: $pageName");
    debugPrint("======================================");

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) {
          debugPrint(
            "BUILDING PAGE: $pageName",
          );

          return page;
        },
      ),
    )
        .then((_) {
      _isNavigating = false;

      debugPrint(
        "RETURNED FROM PAGE: $pageName",
      );
    });
  }

  // ============================================================
  // VEHICLE QR
  // ============================================================

  void _openVehicleQr() {
    if (!mounted) return;

    Navigator.of(context).pop();

    Future.microtask(() {
      if (!mounted) return;

      _openPage(
        const QrMovementScreen(),
        "QrMovementScreen",
      );
    });
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildFleetDrawer(
    BuildContext context,
  ) {
    return Drawer(
      width: 285,
      backgroundColor: const Color(0xff12345B),
      child: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // DRAWER HEADER
            // ======================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                10,
                18,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      "Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white24,
              height: 1,
            ),

            // ======================================================
            // MENU
            // ======================================================

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                children: [
                  _drawerItem(
                    context,
                    Icons.directions_car,
                    "Vehicles",
                    Colors.orange,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const VehicleListScreen(),
                          "VehicleListScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.qr_code,
                    "Vehicle QR",
                    Colors.lightBlueAccent,
                    _openVehicleQr,
                  ),

                  _drawerItem(
                    context,
                    Icons.assignment,
                    "Allocations",
                    Colors.white,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const AllocationsScreen(),
                          "AllocationsScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.traffic,
                    "QR Movement",
                    Colors.greenAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const QrMovementScreen(),
                          "QrMovementScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.receipt_long,
                    "Expenses",
                    Colors.white,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const ExpensesScreen(),
                          "ExpensesScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.shield_outlined,
                    "Insurance",
                    Colors.white,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const InsuranceListScreen(),
                          "InsuranceListScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.local_gas_station,
                    "Fuel Bills",
                    Colors.redAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const FuelBillListScreen(),
                          "FuelBillListScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.confirmation_number,
                    "Fastag",
                    Colors.cyanAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const FastagScreen(),
                          "FastagScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.warning_amber,
                    "Challans",
                    Colors.white,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const ChallansScreen(),
                          "ChallansScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.verified,
                    "PUC",
                    Colors.lightBlueAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const PucScreen(),
                          "PucScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.car_repair,
                    "Fitness",
                    Colors.orangeAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const FitnessScreen(),
                          "FitnessScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.badge,
                    "Employees",
                    Colors.purpleAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const EmployeesScreen(),
                          "EmployeesScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.car_crash,
                    "Accidents",
                    Colors.redAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const AccidentsScreen(),
                          "AccidentsScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.people_alt,
                    "Users",
                    Colors.deepOrangeAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const UsersScreen(),
                          "UsersScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.speed,
                    "Mileage",
                    Colors.amber,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const MileageScreen(),
                          "MileageScreen",
                        );
                      });
                    },
                  ),

                  _drawerItem(
                    context,
                    Icons.analytics,
                    "Reports",
                    Colors.cyanAccent,
                    () {
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (!mounted) return;

                        _openPage(
                          const ReportsScreen(),
                          "ReportsScreen",
                        );
                      });
                    },
                  ),

                  const Divider(
                    color: Colors.white24,
                    indent: 15,
                    endIndent: 15,
                  ),

                  _drawerItem(
                    context,
                    Icons.logout,
                    "Logout",
                    Colors.redAccent,
                    _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      minVerticalPadding: 3,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 2,
      ),
      leading: SizedBox(
        width: 30,
        child: Icon(
          icon,
          color: iconColor,
          size: 23,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xffB8D1F0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      onTap: onTap,
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget statCard(
    String title,
    String value,
    Color color, {
    double valueFontSize = 20,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 62,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY SPEND
  // ============================================================

  Widget _monthlySpendCard() {
    final monthlyService =
        dashboardData["MonthlyServiceCost"] ?? 0;

    final monthlyFuel =
        dashboardData["MonthlyFuelCost"] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "MONTHLY SPEND",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "₹$monthlyService",
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Fuel ₹$monthlyFuel",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              "Dashboard could not be loaded",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboardContent() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        // ROW 1
        Row(
          children: [
            Expanded(
              child: statCard(
                "TOTAL VEHICLES",
                "${dashboardData["TotalVehicles"] ?? 0}",
                Colors.black87,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: statCard(
                "AVAILABLE",
                "${dashboardData["Available"] ?? 0}",
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ROW 2
        Row(
          children: [
            Expanded(
              child: statCard(
                "EXPIRED PUC",
                "${dashboardData["ExpiredPUC"] ?? 0}",
                Colors.red,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: statCard(
                "MONTHLY FUEL COST",
                "${dashboardData["MonthlyFuelCost"] ?? 0}",
                Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ROW 3
        Row(
          children: [
            Expanded(
              child: statCard(
                "EXPIRED FITNESS",
                "${dashboardData["ExpiredFitness"] ?? 0}",
                Colors.red,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: statCard(
                "MONTHLY FASTAG",
                "${dashboardData["MonthlyFASTag"] ?? 0}",
                Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ROW 4
        Row(
          children: [
            Expanded(
              child: statCard(
                "ON DEMO",
                "${dashboardData["OnDemo"] ?? 0}",
                Colors.blue,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: statCard(
                "MONTHLY SERVICE",
                "${dashboardData["MonthlyServiceCost"] ?? 0}",
                Colors.orange,
                valueFontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ROW 5
        Row(
          children: [
            Expanded(
              child: statCard(
                "EXP. INSURANCE",
                "${dashboardData["ExpiredInsurance"] ?? 0}",
                Colors.red,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: statCard(
                "PENDING CHALLANS",
                "${dashboardData["PendingChallans"] ?? 0}",
                Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _monthlySpendCard(),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    debugPrint("DASHBOARD BUILD");

    return Scaffold(
      backgroundColor:
          const Color(0xffEEF2F7),

      drawer: _buildFleetDrawer(context),

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // HEADER
            // ======================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration:
                  const BoxDecoration(
                color: Color(0xff2458A6),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // IMPORTANT:
                  // No const here because fullName
                  // and greeting are runtime values.
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "${getGreeting()}, "
                          "${fullName.isNotEmpty ? fullName : "Admin"}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Builder(
                    builder: (drawerContext) {
                      return IconButton(
                        tooltip: "Menu",
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          debugPrint(
                            "DRAWER OPEN",
                          );

                          Scaffold.of(
                            drawerContext,
                          ).openDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // ======================================================
            // BODY
            // ======================================================

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : hasError
                      ? _buildErrorView()
                      : RefreshIndicator(
                          onRefresh:
                              loadDashboard,
                          child:
                              _buildDashboardContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    debugPrint(
      "======================================",
    );
    debugPrint("DASHBOARD DISPOSE");
    debugPrint(
      "======================================",
    );

    super.dispose();
  }
}
