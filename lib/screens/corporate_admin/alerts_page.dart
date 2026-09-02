import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? complianceData;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCompliance();
  }

Future<void> loadCompliance() async {
  try {
    final data = await _authService.dashboardCompliance();

    setState(() {
      complianceData = data;
      isLoading = false;
    });

    final insurance = complianceData?["insurance"] ?? [];
    final puc = complianceData?["puc"] ?? [];
    final fitness = complianceData?["fitness"] ?? [];

    debugPrint("Compliance Data: $complianceData");
    debugPrint("Insurance Count: ${insurance.length}");
    debugPrint("PUC Count: ${puc.length}");
    debugPrint("Fitness Count: ${fitness.length}");

  } catch (e) {
    debugPrint(e.toString());

    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),

      body: SafeArea(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xff2458A6),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "🔔 Compliance Alerts",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Insurance, PUC & Fitness Alerts",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...(complianceData?["insurance"] ?? []).map<Widget>((item) {
                  return alertTile(
                    Icons.shield_outlined,
                    item["RegistrationNo"],
                    "Insurance",
                    "Expires in ${item["DaysToExpiry"]} days",
                    item["InsuranceState"] == "Expired",
                  );
                }).toList(),


  ...(complianceData?["puc"] ?? []).map<Widget>((item) {
  return alertTile(
    Icons.shield_outlined,
    item["RegistrationNo"],
    "PUC",
    "Expires in ${item["DaysToExpiry"]} days",
    item["PUCState"] == "Expired",
  );
}).toList(),

...(complianceData?["fitness"] ?? []).map<Widget>((item) {
  return alertTile(
    Icons.shield_outlined,
    item["RegistrationNo"],
    "Fitness",
    "Expires in ${item["DaysToExpiry"]} days",
    item["FitnessState"] == "Expired",
  );
}).toList(),
                  // alertTile(
                  //   Icons.shield_outlined,
                  //   "RJ14 DM 0007",
                  //   "Insurance",
                  //   "Expired 18 Jun 2026",
                  //   true,
                  // ),

                  // alertTile(
                  //   Icons.description_outlined,
                  //   "RJ14 DM 0021",
                  //   "PUC",
                  //   "Expires in 5 days",
                  //   false,
                  // ),

                  // alertTile(
                  //   Icons.shield_outlined,
                  //   "DL01 DM 0103",
                  //   "Insurance",
                  //   "Expires in 11 days",
                  //   false,
                  // ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget alertTile(
      IconData icon,
      String vehicle,
      String type,
      String date,
      bool expired,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade50,
          child: Icon(icon),
        ),

        title: Text(
          "$vehicle\n• $type",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text(date),

        trailing: Chip(
          backgroundColor: expired
              ? Colors.red.shade100
              : Colors.orange.shade100,
          label: Text(expired ? "Expired" : "Soon"),
        ),
      ),
    );
  }
}