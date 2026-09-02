import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
// import '../login/login_screen.dart';



class AccountsHomeScreen extends StatelessWidget {
  const AccountsHomeScreen({super.key});

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
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

          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xffEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xff4F46E5),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          )
        ],
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

            /// HEADER
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

      /// LEFT SIDE
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Hi, Accounts 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 4),

              Text(
                "Driver · Jaipur Branch",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          /// RIGHT SIDE LOGOUT
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

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.all(14),
                  child: Column(
                    children: [

                      /// VEHICLE CARD
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                                18),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(
                                  0xff6366F1),
                              Color(
                                  0xff4F46E5),
                            ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            Text(
                              "MY ASSIGNED VEHICLE",
                              style:
                                  TextStyle(
                                color: Colors
                                    .white70,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              "Tata Harrier · XZA",
                              style:
                                  TextStyle(
                                color: Colors
                                    .white,
                                fontSize: 28,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              "RJ14 DM 0002 · 1,180 km",
                              style:
                                  TextStyle(
                                color: Colors
                                    .white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 16),

                      /// MENU CARD
                      Container(
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                          border: Border.all(
                            color: Colors
                                .grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [

                            menuTile(
                              icon:
                                  Icons.local_gas_station,
                              title:
                                  "Add Fuel Entry",
                              subtitle:
                                  "Log litres & amount",
                            ),

                            menuTile(
                              icon:
                                  Icons.receipt_long,
                              title:
                                  "Upload Bill",
                              subtitle:
                                  "Snap a photo",
                            ),

                            menuTile(
                              icon:
                                  Icons.av_timer,
                              title:
                                  "Update Odometer",
                              subtitle:
                                  "Last: 1,180 km",
                            ),

                            menuTile(
                              icon:
                                  Icons.warning_amber,
                              title:
                                  "Report Damage",
                              subtitle:
                                  "Notify branch admin",
                            ),
                          ],
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

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor:
            const Color(0xff4F46E5),
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Bills",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}