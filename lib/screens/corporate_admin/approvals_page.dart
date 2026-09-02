import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}


class _ApprovalsPageState extends State<ApprovalsPage> {

  final AuthService _authService = AuthService();

  List<dynamic> expenseList = [];

  bool isLoading = true;


Future<void> loadExpenses() async {
  try {

    final data = await _authService.expenses();

    setState(() {
      expenseList = data["data"] ?? [];
      isLoading = false;
    });

    print(expenseList);

  } catch (e) {

    print(e);

    setState(() {
      isLoading = false;
    });

  }
}

  @override
void initState() {
  super.initState();
  loadExpenses();
}

  @override
  Widget build(BuildContext context) {
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
                    "✓ Approvals",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "7 bills awaiting verification",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),


Expanded(
  child: ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: expenseList.length,
    itemBuilder: (context, index) {

      final item = expenseList[index];

      return approvalTile(
        Icons.build,
        item["RegistrationNo"] ?? "",
        item["TypeName"] ?? "",
        item["Vendor"] ?? "",
        "₹${item["Amount"] ?? 0}",
        item["ApprovalStatus"] ?? "Pending",
      );

    },
  ),
),


          ],
        ),
      ),
    );
  }

  Widget approvalTile(
      IconData icon,
      String vehicle,
      String type,
      String vendor,
      String amount,
      String approvalStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon),
        ),

        title: Text(
          "$vehicle\n• $type",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text("$vendor\n$amount"),
        trailing: approvalStatus == "Pending"
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [

          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.shade100,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.check,
                color: Colors.green,
                size: 18,
              ),
              onPressed: () {
                // Approve API
              },
            ),
          ),

          const SizedBox(width: 8),

          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.red.shade100,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close,
                color: Colors.red,
                size: 18,
              ),
              onPressed: () {
                // Reject API
              },
            ),
          ),
        ],
      )
    : Chip(
        backgroundColor:
            approvalStatus == "Approved"
                ? Colors.green.shade100
                : Colors.red.shade100,
        label: Text(
          approvalStatus,
          style: TextStyle(
            color: approvalStatus == "Approved"
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
  }

  Widget approvalTileApproved(
      IconData icon,
      String vehicle,
      String type,
      String vendor,
      String amount,
      String approvalStatus,
      ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade50,
          child: Icon(icon),
        ),

        title: Text(
          "$vehicle\n• $type",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text("$vendor\n$amount"),

        trailing: Chip(
          label: const Text("Approved"),
          backgroundColor: Colors.green.shade100,
        ),
      ),
    );
  }
}