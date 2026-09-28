import 'package:flutter/material.dart';

import '../services/session.dart';

import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'employees_screen.dart';
import 'vehicles_screen.dart';
import 'allocations_screen.dart';
import 'movement_screen.dart';
import 'fuel_screen.dart';
import 'expenses_screen.dart';
import 'accidents_screen.dart';
import 'challan_screen.dart';
import 'fastag_screen.dart';
import 'fitness_screen.dart';
import 'insurance_screen.dart';
import 'puc_screen.dart';
import 'documents_screen.dart';
import 'mileage_screen.dart';
import 'mapping_screen.dart';
import 'reports_screen.dart';
import 'vehicle_info_screen.dart';
import 'qr_print_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() {
    return _HomeShellState();
  }
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final List<String> names = const [
    'Dashboard',
    'Users',
    'Employees',
    'Vehicles',
    'Allocations',
    'QR Movement',
    'Fuel',
    'Expenses',
    'Accidents',
    'Challan',
    'FASTag',
    'Fitness',
    'Insurance',
    'PUC',
    'Documents',
    'Mileage',
    'Mapping',
    'Reports',
    'Vehicle Info',
    'QR Print',
  ];

  late final List<Widget> screens = <Widget>[
    const DashboardScreen(),
    const UsersScreen(),
    const EmployeesScreen(),
    const VehiclesScreen(),
    const AllocationsScreen(),
    const MovementScreen(),
    const FuelScreen(),
    const ExpensesScreen(),
    const AccidentsScreen(),
    const ChallanScreen(),
    const FastagScreen(),
    const FitnessScreen(),
    const InsuranceScreen(),
    const PucScreen(),
    const DocumentsScreen(),
    const MileageScreen(),
    const MappingScreen(),
    const ReportsScreen(),
    const VehicleInfoScreen(),
    const QrPrintScreen(),
  ];

  Future<void> logout() async {
    await Session.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          names[index],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 130,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xff2458A6),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'DVMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ...List.generate(
                names.length,
                (i) {
                  return ListTile(
                    selected: i == index,
                    leading: Icon(
                      _icon(i),
                      color: i == index
                          ? const Color(0xff2458A6)
                          : null,
                    ),
                    title: Text(
                      names[i],
                      style: TextStyle(
                        fontWeight: i == index
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        index = i;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),

      body: IndexedStack(
        index: index,
        children: screens,
      ),
    );
  }

  IconData _icon(int i) {
    const List<IconData> icons = [
      Icons.dashboard,
      Icons.people,
      Icons.badge,
      Icons.directions_car,
      Icons.assignment,
      Icons.qr_code_scanner,
      Icons.local_gas_station,
      Icons.receipt_long,
      Icons.car_crash,
      Icons.receipt,
      Icons.credit_card,
      Icons.verified,
      Icons.security,
      Icons.description,
      Icons.folder,
      Icons.speed,
      Icons.map,
      Icons.bar_chart,
      Icons.info,
      Icons.qr_code,
    ];

    if (i < 0 || i >= icons.length) {
      return Icons.apps;
    }

    return icons[i];
  }
}