import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'approvals_page.dart';
import 'alerts_page.dart';
class CorporateAdminHomeScreen extends StatefulWidget {
  const CorporateAdminHomeScreen({super.key});

  @override
  State<CorporateAdminHomeScreen> createState() =>
      _CorporateAdminHomeScreenState();
}

class _CorporateAdminHomeScreenState extends State<CorporateAdminHomeScreen> {

  int currentIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ApprovalsPage(),
    AlertsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index){
          setState(() {
            currentIndex=index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Stats",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: "Approvals",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: "Alerts",
          ),

        ],
      ),
    );
  }
}