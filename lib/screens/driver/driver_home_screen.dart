import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data_table_2/data_table_2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../driver/add_fuel_screen.dart';
import '../driver/upload_bill_screen.dart';
import '../driver/my_vehicle_screen.dart';
import '../driver/report_damage_screen.dart';
import '../driver/my_bills_screen.dart';
import '../driver/profile_screen.dart';
import '../../services/auth_service.dart';


class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}



class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String name = "";
  bool showMenu = false;
  final AuthService _authService = AuthService();
  List<dynamic> vehicles = [];
  String? selectedVehicle;
  bool isLoading = true; 
  Future<void> loadVehicles() async {
  try {
    final data = await _authService.getVehicles();
    setState(() {
      vehicles = data;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    debugPrint(e.toString());
  }
}
  @override
  void initState() {
    super.initState();
    loadUser();
    loadVehicles();
  }


  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString("name") ?? "Driver";
    });
  }

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.blue,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  backgroundColor: const Color(0xffF1F5F9),

  body: SafeArea(
    child: Column(
      children: [

        ///================ HEADER ==================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff4338CA),
                Color(0xff4F46E5),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// LEFT
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Hi, $name 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Driver · Jaipur Branch",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              /// LOGOUT
              TextButton.icon(
                onPressed: () async {

                  final prefs =
                      await SharedPreferences.getInstance();

                  await prefs.clear();

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
              ),
            ],
          ),
        ),

        ///================ BODY ==================
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [

                  /// VEHICLE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff6366F1),
                          Color(0xff4F46E5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          "MY ASSIGNED VEHICLE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          "Tata Harrier · XZA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "RJ14 DM 0002 · 1,180 km",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// TABLE HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8EEF9),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [

                        Expanded(
                          flex: 3,
                          child: Text(
                            "Vehicle No",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 3,
                          child: Text(
                            "Model",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Text(
                            "Fuel",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Text(
                            "Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),


                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: vehicles.map((vehicle) {
                        bool isOpen = selectedVehicle == vehicle["RegistrationNo"];

                        return Column(
                          children: [

                            /// VEHICLE ROW
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isOpen) {
                                    selectedVehicle = null;
                                  } else {
                                    selectedVehicle = vehicle["RegistrationNo"];
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                

                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    vehicle["RegistrationNo"].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 3,
                                  child: Text(vehicle["Model"].toString()),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(vehicle["FuelType"].toString()),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(vehicle["Status"].toString()),
                                ),
                              ],
                            ),


                              ),
                            ),

                            /// MENU
                            if (isOpen)
                              Column(
                                children: [

                                  menuTile(
                                    icon: Icons.local_gas_station,
                                    title: "Add Fuel Entry",
                                    subtitle: "Log litres & amount",
                                    onTap: () {
                                      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AddFuelScreen(
      vehicleId: vehicle["VehicleId"],
      registrationNo: vehicle["RegistrationNo"],
      model: vehicle["Model"],
    ),
  ),
);
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (_) => const AddFuelScreen(),
                                      //   ),
                                      // );
                                    },
                                  ),

                                  menuTile(
                                    icon: Icons.receipt_long,
                                    title: "Upload Bill",
                                    subtitle: "Snap a photo",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const UploadBillScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  menuTile(
                                    icon: Icons.speed,
                                    title: "Update Odometer",
                                    subtitle: "Current KM",
                                  ),

                                  menuTile(
                                    icon: Icons.warning_amber,
                                    title: "Report Damage",
                                    subtitle: "Notify Branch Admin",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ReportDamageScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  menuTile(
                                    icon: Icons.directions_car,
                                    title: "My Vehicle & QR",
                                    subtitle:
                                        "Insurance, PUC & Service",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MyVehicleScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
             ],
            ),
          ),
        ),
      ),
    ],
  ),
),
  
    
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DriverHomeScreen(),
            ),
          );
        }

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const MyBillsScreen(),
            ),
          );
        }

        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ProfileScreen(),
            ),
          );
        }
      },

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "Bills",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    ),
  );
}
}