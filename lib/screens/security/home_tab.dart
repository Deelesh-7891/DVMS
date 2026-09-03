import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'report_accident_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AuthService _authService = AuthService();

  late Future<List<dynamic>> movementFuture;

  @override
  void initState() {
    super.initState();
    movementFuture = _authService.getmovement();
  }

  Future<void> _refresh() async {
    setState(() {
      movementFuture = _authService.getmovement();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),
      body: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xff2458A6),
              ),
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ======================================================
                  // LOGOUT
                  // ======================================================
                  TextButton.icon(
                    onPressed: () async {
                      final prefs =
                          await SharedPreferences.getInstance();
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

            // ============================================================
            // FIXED REPORT ACCIDENT AREA
            // This area stays fixed. Only the movement list below scrolls.
            // ============================================================
           Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    vertical: 12,
  ),
  color: const Color(0xffEEF2F7),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReportAccidentScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          "Report Accident",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff2458A6),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  ),
),





            // ============================================================
            // BODY
            // ============================================================
            Expanded(

              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<dynamic>>(
                  future: movementFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Movement Found",
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }

                    final movements = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: movements.length,
                      itemBuilder: (context, index) {
                        return movementTile(movements[index]);
                      },
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

  // ========================================================================
  // MOVEMENT TILE
  // ========================================================================
  Widget movementTile(Map<String, dynamic> item) {
    final direction =
        (item["Direction"] ?? "").toString().toLowerCase();

    final bool isEntry = direction == "entry";

    String movementTime = "";

    try {
      final utcTime = DateTime.parse(
        item["MovementTime"].toString(),
      );

      final indiaTime = tz.TZDateTime.from(
        utcTime.toUtc(),
        tz.getLocation("Asia/Kolkata"),
      );

      movementTime = DateFormat(
        "dd MMM yyyy, hh:mm a",
      ).format(indiaTime);
    } catch (e) {
      debugPrint("MovementTime Error: $e");
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isEntry
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isEntry
                ? Colors.green.shade100
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEntry ? Icons.login : Icons.logout,
            color: isEntry ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          item["RegistrationNo"] ?? "",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Driver : ${item["DriverName"] ?? "-"}"),
              Text("Movement : ${item["MovementType"] ?? "-"}"),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEntry
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item["Direction"] ?? "",
                  style: TextStyle(
                    color: isEntry ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text("Customer : ${item["CustomerName"] ?? "-"}"),
              Text(
                "Sales Executive : ${item["SalesExecutive"] ?? "-"}",
              ),
              Text("Purpose : ${item["Purpose"] ?? "-"}"),
              Text("From Location : ${item["FromLocationName"] ?? "-"}"),
              Text("To Location : ${item["ToLocationName"] ?? "-"}"),
              Text("Odometer : ${item["Odometer"] ?? "-"} km"),
                 

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    movementTime,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          isEntry ? Icons.arrow_downward : Icons.arrow_upward,
          // color: isEntry ? Colors.green : Colors.red,
        ),
      ),
    );
  }

}
