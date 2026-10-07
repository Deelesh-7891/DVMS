import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import '../driver/add_fuel_screen.dart';
import '../driver/upload_bill_screen.dart';
import '../driver/my_vehicle_screen.dart';
import '../driver/report_damage_screen.dart';
import '../driver/my_bills_screen.dart';
import '../driver/profile_screen.dart';

import '../../services/auth_service.dart';
import '../../services/driver_tracking_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver {
  final DriverTracker tracker = DriverTracker.instance;
  final AuthService _authService = AuthService();

  String name = '';
  List<dynamic> vehicles = [];
  String? selectedVehicle;

  bool isLoading = true;
  String? vehicleError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadUser();
    loadVehicles();
    tracker.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      tracker.checkNow();
    }
  }

  // Greeting based on local device time.
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Safely read a field from the vehicle API response.
  String vehicleValue(dynamic vehicle, String key) {
    if (vehicle is Map) {
      final value = vehicle[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'N/A';
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        name = prefs.getString('fullName') ?? '';
      });
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  Future<void> loadVehicles() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        vehicleError = null;
      });
    }

    try {
      final data = await _authService.getVehicles();

      if (!mounted) return;

      setState(() {
        vehicles = data;
        isLoading = false;
        vehicleError = null;
      });
    } catch (e) {
      debugPrint('Load vehicles error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        vehicleError = e.toString();
      });
    }
  }

  // Logout and clear local session.
  Future<void> logout() async {
    try {
      await tracker.stop();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  // Trip tracking status banner.
  Widget tripCard(TrackerStatus s) {
    Color bg;
    IconData icon;
    String title;

    switch (s.state) {
      case TrackerState.tracking:
        bg = const Color(0xff16A34A);
        icon = Icons.gps_fixed;
        title = 'On trip · ${s.vehicle ?? ''}';
        break;

      case TrackerState.permissionNeeded:
        bg = const Color(0xffDC2626);
        icon = Icons.location_off;
        title = 'Location needed';
        break;

      case TrackerState.noDriverLink:
        bg = const Color(0xffD97706);
        icon = Icons.link_off;
        title = 'Not linked to a driver';
        break;

      case TrackerState.error:
        bg = const Color(0xffD97706);
        icon = Icons.cloud_off;
        title = 'Connection problem';
        break;

      case TrackerState.idle:
        bg = const Color(0xff64748B);
        icon = Icons.gps_not_fixed;
        title = 'Not on a trip';
        break;
    }

    final lines = <String>[
      s.message,
      if (s.state == TrackerState.tracking && s.since != null)
        'Out since ${TimeOfDay.fromDateTime(s.since!.toLocal()).format(context)}',
      if (s.queued > 0) '${s.queued} points waiting for network',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lines.join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (s.state != TrackerState.tracking)
            IconButton(
              tooltip: 'Check again',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => tracker.checkNow(),
            ),
        ],
      ),
    );
  }

  // Reusable menu tile.
  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff4F46E5), size: 26),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Header.
  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff4338CA), Color(0xff4F46E5)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${name.isNotEmpty ? name : 'Driver'} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${getGreeting()},',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Assigned vehicle card.
  Widget buildVehicleCard() {
    final dynamic assignedVehicle = vehicles.isNotEmpty ? vehicles.first : null;

    final registration = assignedVehicle == null
        ? ''
        : vehicleValue(assignedVehicle, 'RegistrationNo');

    final model = assignedVehicle == null
        ? ''
        : vehicleValue(assignedVehicle, 'Model');

    final fuel = assignedVehicle == null
        ? ''
        : vehicleValue(assignedVehicle, 'FuelType');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6366F1), Color(0xff4F46E5)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY ASSIGNED VEHICLE',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Text(
              'Loading vehicles...',
              style: TextStyle(color: Colors.white, fontSize: 20),
            )
          else
            Text(
              registration.isEmpty ? 'No vehicle assigned' : registration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            isLoading
                ? 'Please wait'
                : assignedVehicle == null
                ? 'Vehicle details unavailable'
                : '$model · $fuel',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Vehicle table heading.
  Widget buildVehicleTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffE8EEF9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Vehicle No',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('Fuel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Actions for a selected vehicle.
  Widget buildVehicleMenu(dynamic vehicle) {
    return Column(
      children: [
        menuTile(
          icon: Icons.local_gas_station,
          title: 'Add Fuel Entry',
          subtitle: 'Log litres & amount',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddFuelScreen(
                  vehicleId: vehicle['VehicleId'],
                  registrationNo: vehicle['RegistrationNo'],
                  model: vehicle['Model'],
                ),
              ),
            );
          },
        ),
        menuTile(
          icon: Icons.receipt_long,
          title: 'Upload Bill',
          subtitle: 'Snap a photo',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadBillScreen(
                  vehicleId: vehicle['VehicleId'],
                  registrationNo: vehicle['RegistrationNo'],
                  model: vehicle['Model'],
                ),
              ),
            );
          },
        ),
        menuTile(
          icon: Icons.speed,
          title: 'Update Odometer',
          subtitle: 'Current KM',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Odometer screen is not connected yet.'),
              ),
            );
          },
        ),
        menuTile(
          icon: Icons.warning_amber,
          title: 'Report Damage',
          subtitle: 'Notify Branch Admin',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportDamageScreen()),
            );
          },
        ),
        menuTile(
          icon: Icons.directions_car,
          title: 'My Vehicle & QR',
          subtitle: 'Insurance, PUC & Service',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyVehicleScreen()),
            );
          },
        ),
      ],
    );
  }

  // Single vehicle row with expandable actions.
  Widget buildVehicleRow(dynamic vehicle) {
    final registration = vehicleValue(vehicle, 'RegistrationNo');
    final isOpen = selectedVehicle == registration;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              selectedVehicle = isOpen ? null : registration;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xffEEF2FF) : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    registration,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(flex: 3, child: Text(vehicleValue(vehicle, 'Model'))),
                Expanded(
                  flex: 2,
                  child: Text(vehicleValue(vehicle, 'FuelType')),
                ),
                Expanded(flex: 2, child: Text(vehicleValue(vehicle, 'Status'))),
              ],
            ),
          ),
        ),
        if (isOpen) buildVehicleMenu(vehicle),
      ],
    );
  }

  // Vehicle list with loading, empty and error states.
  Widget buildVehicleList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(25),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vehicleError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Unable to load vehicles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              vehicleError!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: loadVehicles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (vehicles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No vehicles assigned.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: vehicles.map((vehicle) {
          return buildVehicleRow(vehicle);
        }).toList(),
      ),
    );
  }

  // Bottom navigation.
  Widget buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xff4F46E5),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) {
          return;
        }

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyBillsScreen()),
          );
        }

        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bills'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadVehicles,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ValueListenableBuilder<TrackerStatus>(
                          valueListenable: tracker.status,
                          builder: (_, status, __) {
                            return tripCard(status);
                          },
                        ),
                        buildVehicleCard(),
                        const SizedBox(height: 16),
                        buildVehicleTableHeader(),
                        const SizedBox(height: 6),
                        buildVehicleList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigation(),
    );
  }
}
