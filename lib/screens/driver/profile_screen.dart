import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../driver/driver_home_screen.dart';
import '../driver/my_bills_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // USER DETAILS
  // ============================================================

  String name = "Driver";
  String phone = "";
  String email = "";

  String role = "";
  String stateName = "";
  String cityName = "";

  int userId = 0;
  int roleId = 0;
  int branchId = 0;
  int stateId = 0;
  int cityId = 0;

  bool isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ============================================================
  // LOAD USER FROM SHARED PREFERENCES
  // ============================================================

  Future<void> loadUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userId =
          prefs.getInt("userId") ?? 0;

      name =
          prefs.getString("name") ?? "Driver";

      phone =
          prefs.getString("phone") ?? "";

      email =
          prefs.getString("email") ?? "";

      role =
          prefs.getString("role") ?? "";

      roleId =
          prefs.getInt("roleId") ?? 0;

      branchId =
          prefs.getInt("branchId") ?? 0;

      stateId =
          prefs.getInt("stateId") ?? 0;

      stateName =
          prefs.getString("stateName") ?? "";

      cityId =
          prefs.getInt("cityId") ?? 0;

      cityName =
          prefs.getString("cityName") ?? "";

      isLoading = false;
    });

    // Debug
    print("================================");
    print("PROFILE DATA");
    print("================================");
    print("User ID     : $userId");
    print("Name        : $name");
    print("Email       : $email");
    print("Phone       : $phone");
    print("Role        : $role");
    print("Role ID     : $roleId");
    print("Branch ID   : $branchId");
    print("State ID    : $stateId");
    print("State Name  : $stateName");
    print("City ID     : $cityId");
    print("City Name   : $cityName");
    print("================================");
  }

  // ============================================================
  // GET INITIALS
  // ============================================================

  String getInitials() {
    if (name.trim().isEmpty) {
      return "D";
    }

    final List<String> parts =
        name.trim().split(" ");

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (
      parts.first[0] +
      parts.last[0]
    ).toUpperCase();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffEEF2F7),

      // ========================================================
      // BODY
      // ========================================================

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [

                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    50,
                    20,
                    20,
                  ),

                  color:
                      const Color(0xff2457B3),

                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          Icon(
                            Icons.person,
                            color:
                                Colors.white,
                          ),

                          SizedBox(
                            width: 8,
                          ),

                          Text(
                            "Profile",
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 5,
                      ),

                      Text(
                        "Account & Location Details",
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CONTENT
                // ==================================================

                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child: Column(
                      children: [

                        // ==========================================
                        // PROFILE CARD
                        // ==========================================

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets.all(
                            20,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.grey
                                        .shade300,

                                blurRadius:
                                    8,

                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),

                          child:
                              Column(
                            children: [

                              // Avatar
                              CircleAvatar(
                                radius: 40,

                                backgroundColor:
                                    const Color(
                                  0xff2457B3,
                                ),

                                child: Text(
                                  getInitials(),

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,

                                    fontSize:
                                        28,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              // Name
                              Text(
                                name,

                                textAlign:
                                    TextAlign
                                        .center,

                                style:
                                    const TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              // Role + State
                              Text(
                                role.isEmpty
                                    ? stateName
                                    : "$role • $stateName",

                                textAlign:
                                    TextAlign
                                        .center,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,

                                  fontSize:
                                      16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==========================================
                        // BASIC DETAILS
                        // ==========================================

                        _buildSectionTitle(
                          "Personal Details",
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Container(
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.grey
                                        .shade300,

                                blurRadius:
                                    8,

                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),

                          child:
                              Column(
                            children: [

                              profileTile(
                                Icons.email,
                                Colors.blue,
                                "Email",
                                email.isEmpty
                                    ? "-"
                                    : email,
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons.phone,
                                Colors.red,
                                "Phone",
                                phone.isEmpty
                                    ? "-"
                                    : phone,
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons.badge,
                                Colors.deepPurple,
                                "Role",
                                role.isEmpty
                                    ? "-"
                                    : role,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==========================================
                        // LOCATION DETAILS
                        // ==========================================

                        _buildSectionTitle(
                          "Location Details",
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Container(
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.grey
                                        .shade300,

                                blurRadius:
                                    8,

                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),

                          child:
                              Column(
                            children: [

                              profileTile(
                                Icons.map,
                                Colors.green,
                                "State",
                                stateName.isEmpty
                                    ? "-"
                                    : stateName,
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons.location_city,
                                Colors.orange,
                                "City",
                                cityName.isEmpty
                                    ? "-"
                                    : cityName,
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons.business,
                                Colors.blue,
                                "Branch ID",
                                branchId
                                    .toString(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==========================================
                        // ACCOUNT DETAILS
                        // ==========================================

                        _buildSectionTitle(
                          "Account Details",
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Container(
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.grey
                                        .shade300,

                                blurRadius:
                                    8,

                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),

                          child:
                              Column(
                            children: [

                              profileTile(
                                Icons
                                    .account_circle,
                                Colors.indigo,
                                "User ID",
                                userId
                                    .toString(),
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons
                                    .admin_panel_settings,
                                Colors.purple,
                                "Role ID",
                                roleId
                                    .toString(),
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons.map_outlined,
                                Colors.teal,
                                "State ID",
                                stateId
                                    .toString(),
                              ),

                              const Divider(
                                height: 1,
                              ),

                              profileTile(
                                Icons
                                    .location_city_outlined,
                                Colors.deepOrange,
                                "City ID",
                                cityId
                                    .toString(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        

                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 2,

        selectedItemColor:
            const Color(
          0xff2457B3,
        ),

        unselectedItemColor:
            Colors.grey,

        type:
            BottomNavigationBarType
                .fixed,

        onTap: (index) {

          // HOME
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DriverHomeScreen(),
              ),
            );
          }

          // BILLS
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const MyBillsScreen(),
              ),
            );
          }

          // PROFILE
          if (index == 2) {
            // Already on Profile
          }
        },

        items: const [

          BottomNavigationBarItem(
            icon:
                Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(
              Icons.receipt_long,
            ),
            label: "Bills",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,

      child: Text(
        title,

        style:
            const TextStyle(
          fontSize: 17,

          fontWeight:
              FontWeight.bold,

          color:
              Color(0xff12386B),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE TILE
  // ============================================================

  Widget profileTile(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      leading:
          Container(
        width: 48,
        height: 48,

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xffEEF4FF,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        child:
            Icon(
          icon,
          color: color,
        ),
      ),

      title:
          Text(
        title,

        style:
            const TextStyle(
          fontWeight:
              FontWeight.bold,

          fontSize: 16,
        ),
      ),

      subtitle:
          Padding(
        padding:
            const EdgeInsets.only(
          top: 3,
        ),

        child:
            Text(
          subtitle,

          maxLines: 2,

          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            color:
                Colors.grey,

            fontSize: 14,
          ),
        ),
      ),
    );
  }
}