import 'package:flutter/material.dart';

class MyVehicleScreen extends StatelessWidget {
  const MyVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),
       appBar: AppBar(
        backgroundColor: const Color(0xff2457B3),
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             "My Vehicle",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Currently assigned",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
     
          //================ HEADER =================
              
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          //   color: const Color(0xff2457B3),
          //   child: const Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [

          //       Row(
          //         children: [

          //           Icon(
          //             Icons.directions_car,
          //             color: Colors.white,
          //           ),

          //           SizedBox(width: 8),

          //           Text(
          //             "My Vehicle",
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 28,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ],
          //       ),

          //       SizedBox(height: 5),

          //       Text(
          //         "Currently assigned",
          //         style: TextStyle(
          //           color: Colors.white70,
          //           fontSize: 15,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  //================ VEHICLE CARD =================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff2F66C6),
                          Color(0xff4A86E8),
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "TATA HARRIER · XZA",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          "RJ14 DM 0002",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          "1,180 km · Jaipur Branch",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  //================ QR CARD =================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        const Icon(
                          Icons.qr_code_2,
                          size: 120,
                          color: Colors.black87,
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "Show this QR at the gate",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  //================ DETAILS =================

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        vehicleTile(
                          Icons.shield_outlined,
                          Colors.blue,
                          "Insurance",
                          "Valid till 18 Sep 2026",
                        ),

                        Divider(height: 1),

                        vehicleTile(
                          Icons.speed,
                          Colors.blueGrey,
                          "PUC",
                          "Valid till 02 Oct 2026",
                        ),

                        Divider(height: 1),

                        vehicleTile(
                          Icons.build,
                          Colors.black87,
                          "Last Service",
                          "14 Jun 2026 · 800 km",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget vehicleTile(
      IconData icon,
      Color color,
      String title,
      String subtitle,
      ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xffEEF4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}