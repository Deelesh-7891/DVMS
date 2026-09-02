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


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
final AuthService _authService = AuthService();

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final data = await _authService.DashboardSummary();
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard Error : $e");

      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),
      body: SafeArea(
        child: Column(
          children: [

            /// Header
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xff2458A6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fleet Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Manager • All Branches",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

            // RIGHT SIDE LOGOUT
            TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [

                    Row(
                      children: [

                        Expanded(
                          child: statCard(
                            "TOTAL VEHICLES",
                            "${dashboardData?["TotalVehicles"]}",
                            Colors.black87,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: statCard(
                          "AVAILABLE",
                          "${dashboardData?["Available"]}",
                          
                          Colors.green,
                        ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [

                        Expanded(
                          child: statCard(
                          "ON DEMO",
                          "${dashboardData?["OnDemo"]}",
                          Colors.blue,
                        ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: statCard(
                            "IN SERVICE",
                            "${dashboardData?["InService"]}",
                            Colors.orange,
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [

                        Expanded(
                          child: statCard(
                          "EXP.INSURANCE",
                          "${dashboardData?["ExpiredInsurance"] }",
                          Colors.red,
                        ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: statCard(
                          "PENDING",
                          "${dashboardData?["PendingChallans"] }",
                          Colors.red,
                        ),
                                              ),

                                            ],
                                          ),

                                          const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MONTHLY SPEND",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "₹${dashboardData?["MonthlyServiceCost"] ?? 0}",
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Fuel ₹${dashboardData?["MonthlyServiceCost"] ?? 0}",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [

                        actionCard(
      Icons.directions_car,
      "Vehicles",
      Colors.blue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VehicleListScreen(),
          ),
        );
      },
    ),

    actionCard(
      Icons.people,
      "Drivers",
      Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverListScreen(),
          ),
        );
      },
    ),

    actionCard(
      Icons.receipt_long,
      "Fuel Bills",
      Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FuelBillListScreen(),
          ),
        );
      },
    ),

    actionCard(
      Icons.build,
      "Service",
      Colors.red,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ServiceListScreen(),
          ),
        );
      },
    ),

    actionCard(
      Icons.warning,
      "Insurance",
      Colors.purple,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InsuranceListScreen(),
          ),
        );
      },
    ),
      actionCard(
      Icons.analytics,
      "Reports",
      Colors.teal,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
          ),
        );
      },
    ),
      actionCard(
      Icons.analytics,
      "QR Movement",
      Colors.teal,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QrMovementScreen(),
          ),
        );
      },
    ),

                      ],
                    ),

                  ],
                ),
              ),
            ),

          ],
        ),
      ),
      
      
    );
  }

  Widget statCard(
      String title,
      String value,
      Color valueColor,
      ) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              color: Color(0xff9AA8C5),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),

        ],
      ),
    );
  }

 Widget actionCard(
  IconData icon,
  String title,
  Color color, {
  VoidCallback? onTap,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(.15),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
}
