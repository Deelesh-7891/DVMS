import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'add_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // =========================================================
  // AUTH SERVICE
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // SEARCH CONTROLLER
  // =========================================================

  final TextEditingController searchController = TextEditingController();

  // =========================================================
  // USER DATA
  // =========================================================

  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];

  bool isLoading = false;
  String? errorMessage;

  // =========================================================
  // CURRENT USER ROLE
  // =========================================================

  String currentUserRole = "";

  // Add User is visible ONLY for CorporateAdmin and StateAdmin.
  bool get canAddUser {
    final role = currentUserRole.trim().toLowerCase().replaceAll(" ", "");

    return role == "corporateadmin" || role == "stateadmin";
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(applySearch);

    loadCurrentUserRole();
    loadUsers();
  }

  // =========================================================
  // GET CURRENT USER ROLE
  // =========================================================

  Future<void> loadCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    // Use RoleName first because your role master uses RoleName.
    final role =
        prefs.getString("RoleName") ??
        prefs.getString("Role") ??
        prefs.getString("role") ??
        prefs.getString("UserRole") ??
        prefs.getString("userRole") ??
        "";

    if (!mounted) return;

    setState(() {
      currentUserRole = role.trim();
    });

    debugPrint("Current User Role: $currentUserRole");
    debugPrint("Can Add User: $canAddUser");
  }

  // =========================================================
  // GET USERS API
  // =========================================================

  Future<void> loadUsers() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getusers();

      if (!mounted) return;

      setState(() {
        allUsers = List<dynamic>.from(result);

        filteredUsers = List<dynamic>.from(result);

        isLoading = false;
      });

      debugPrint("Users loaded: ${allUsers.length}");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();

        allUsers = [];
        filteredUsers = [];
      });

      debugPrint("Users API Error: $e");
    }
  }

  // =========================================================
  // SAFE VALUE
  // =========================================================

  String getValue(Map<String, dynamic> user, List<String> keys) {
    for (final key in keys) {
      final value = user[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void applySearch() {
    final search = searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      if (!mounted) return;

      setState(() {
        filteredUsers = List<dynamic>.from(allUsers);
      });

      return;
    }

    final result = allUsers.where((item) {
      if (item is! Map) {
        return false;
      }

      final user = Map<String, dynamic>.from(item);

      final name = getValue(user, [
        "Name",
        "name",
        "FullName",
        "fullName",
        "UserName",
        "username",
      ]).toLowerCase();

      final email = getValue(user, ["Email", "email"]).toLowerCase();

      final phone = getValue(user, [
        "Phone",
        "phone",
        "Mobile",
        "mobile",
        "PhoneNumber",
        "phoneNumber",
      ]).toLowerCase();

      final role = getValue(user, [
        "Role",
        "role",
        "UserRole",
        "userRole",
      ]).toLowerCase();

      return name.contains(search) ||
          email.contains(search) ||
          phone.contains(search) ||
          role.contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredUsers = result;
    });
  }

  // =========================================================
  // RESET SEARCH
  // =========================================================

  void resetSearch() {
    searchController.clear();

    if (!mounted) return;

    setState(() {
      filteredUsers = List<dynamic>.from(allUsers);
    });
  }

  // =========================================================
  // ROLE BADGE
  // =========================================================

  Widget roleBadge(String role) {
    Color backgroundColor;
    Color textColor;

    switch (role.toLowerCase()) {
      case "admin":
      case "stateadmin":
      case "state admin":
        backgroundColor = const Color(0xffe0f2fe);

        textColor = const Color(0xff0284c7);

        break;

      case "security":
        backgroundColor = const Color(0xfffff3c4);

        textColor = const Color(0xffd97706);

        break;

      case "driver":
        backgroundColor = const Color(0xfff1f5f9);

        textColor = const Color(0xff475569);

        break;

      default:
        backgroundColor = const Color(0xfff1f5f9);

        textColor = const Color(0xff475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            role,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATE BADGE
  // =========================================================

  Widget stateBadge(dynamic state) {
    if (state == null) {
      return const Text("-");
    }

    if (state is List) {
      if (state.isEmpty) {
        return const Text("-");
      }

      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: state.map((item) {
          return singleStateBadge(item.toString());
        }).toList(),
      );
    }

    final text = state.toString();

    if (text.trim().isEmpty || text == "-") {
      return const Text("-");
    }

    if (text.contains(",")) {
      final states = text.split(",");

      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: states.map((item) {
          return singleStateBadge(item.trim());
        }).toList(),
      );
    }

    return singleStateBadge(text);
  }

  Widget singleStateBadge(String state) {
    if (state.trim().isEmpty || state == "-") {
      return const Text("-");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffe0f2fe),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xff0284c7)),
          const SizedBox(width: 5),
          Text(
            state.toUpperCase(),
            style: const TextStyle(
              color: Color(0xff0284c7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget statusBadge(String status) {
    final normalized = status.toLowerCase();

    final bool active =
        normalized == "active" || normalized == "true" || normalized == "1";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xffdcfce7) : const Color(0xffffe4e6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xff16a34a) : const Color(0xffdc2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? "Active" : "Inactive",
            style: TextStyle(
              color: active ? const Color(0xff16a34a) : const Color(0xffdc2626),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTION BUTTON
  // =========================================================

  Widget actionButton({
    required String title,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: danger
              ? const Color(0xffef4444)
              : const Color(0xff334155),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          side: BorderSide(
            color: danger ? const Color(0xffffd4d4) : const Color(0xffdbe2ea),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // =========================================================
  // EDIT USER
  // =========================================================

  void editUser(Map<String, dynamic> user) {
    final name = getValue(user, ["Name", "name", "FullName", "fullName"]);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Edit: $name")));
  }

  // =========================================================
  // DEACTIVATE USER
  // =========================================================

  void deactivateUser(Map<String, dynamic> user) {
    final name = getValue(user, ["Name", "name", "FullName", "fullName"]);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Deactivate: $name")));
  }

  // =========================================================
  // DELETE USER
  // =========================================================

  void deleteUser(Map<String, dynamic> user) {
    final name = getValue(user, ["Name", "name", "FullName", "fullName"]);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete User"),
          content: Text("Are you sure you want to delete $name?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  allUsers.remove(user);
                  filteredUsers.remove(user);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User removed from list")),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // USER TABLE
  // =========================================================

  Widget buildUserTable() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 55, color: Color(0xff94a3b8)),
              SizedBox(height: 12),
              Text(
                "No users found",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff64748b),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            horizontalMargin: 18,
            headingRowHeight: 52,
            dataRowMinHeight: 72,
            dataRowMaxHeight: 105,

            columns: const [
              DataColumn(label: TableHeader("NAME")),
              DataColumn(label: TableHeader("EMAIL")),
              DataColumn(label: TableHeader("PHONE")),
              DataColumn(label: TableHeader("ROLE")),
              DataColumn(label: TableHeader("STATE")),
              DataColumn(label: TableHeader("LOCATION")),
              DataColumn(label: TableHeader("STATUS")),
              DataColumn(label: TableHeader("LAST LOGIN")),
              DataColumn(label: TableHeader("ACTIONS")),
            ],

            rows: filteredUsers.map<DataRow>((item) {
              final user = Map<String, dynamic>.from(item);

              // ==========================================
              // NAME
              // ==========================================

              final name = getValue(user, [
                "Name",
                "name",
                "FullName",
                "fullName",
                "UserName",
                "username",
              ]);

              // ==========================================
              // EMAIL
              // ==========================================

              final email = getValue(user, ["Email", "email"]);

              // ==========================================
              // PHONE
              // ==========================================

              final phone = getValue(user, [
                "Phone",
                "phone",
                "Mobile",
                "mobile",
                "PhoneNumber",
                "phoneNumber",
              ]);

              // ==========================================
              // ROLE
              // ==========================================

              final role = getValue(user, [
                "Role",
                "role",
                "UserRole",
                "userRole",
              ]);

              // ==========================================
              // STATE
              // ==========================================

              final state =
                  user["State"] ??
                  user["state"] ??
                  user["States"] ??
                  user["states"] ??
                  "-";

              // ==========================================
              // LOCATION
              // ==========================================

              final location = getValue(user, [
                "Location",
                "location",
                "LocationName",
                "locationName",
              ]);

              // ==========================================
              // STATUS
              // ==========================================

              final status = getValue(user, [
                "Status",
                "status",
                "IsActive",
                "isActive",
              ]);

              // ==========================================
              // LAST LOGIN
              // ==========================================

              final lastLogin = getValue(user, [
                "LastLogin",
                "lastLogin",
                "LastLoginDate",
                "lastLoginDate",
                "LastLoginAt",
                "lastLoginAt",
              ]);

              return DataRow(
                cells: [
                  // ======================================
                  // NAME
                  // ======================================
                  DataCell(
                    SizedBox(
                      width: 145,
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff0f172a),
                        ),
                      ),
                    ),
                  ),

                  // ======================================
                  // EMAIL
                  // ======================================
                  DataCell(
                    SizedBox(
                      width: 240,
                      child: Text(
                        email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff334155),
                        ),
                      ),
                    ),
                  ),

                  // ======================================
                  // PHONE
                  // ======================================
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Text(phone, style: const TextStyle(fontSize: 13)),
                    ),
                  ),

                  // ======================================
                  // ROLE
                  // ======================================
                  DataCell(roleBadge(role)),

                  // ======================================
                  // STATE
                  // ======================================
                  DataCell(SizedBox(width: 150, child: stateBadge(state))),

                  // ======================================
                  // LOCATION
                  // ======================================
                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        location,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff334155),
                        ),
                      ),
                    ),
                  ),

                  // ======================================
                  // STATUS
                  // ======================================
                  DataCell(statusBadge(status)),

                  // ======================================
                  // LAST LOGIN
                  // ======================================
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Text(
                        lastLogin,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff475569),
                        ),
                      ),
                    ),
                  ),

                  // ======================================
                  // ACTIONS
                  // ======================================
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        actionButton(
                          title: "Edit",
                          onPressed: () {
                            editUser(user);
                          },
                        ),

                        const SizedBox(width: 7),

                        actionButton(
                          title: "Deactivate",
                          onPressed: () {
                            deactivateUser(user);
                          },
                        ),

                        const SizedBox(width: 7),

                        actionButton(
                          title: "Delete",
                          danger: true,
                          onPressed: () {
                            deleteUser(user);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1e293b),

        title: const Text(
          "Users",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // PAGE HEADER
              // =================================================

              // =================================================
              // PAGE HEADER + ADD USER
              // =================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      "User Management",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff0f172a),
                      ),
                    ),
                  ),

                  // Add User is shown only to CorporateAdmin / StateAdmin.
                  if (canAddUser)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddUserScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadUsers();
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text(
                        "Add User",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2161b5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              const Text(
                "Manage users, roles, locations and account status",
                style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
              ),

              const SizedBox(height: 18),

              // =================================================
              // SEARCH CARD
              // =================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool mobile = constraints.maxWidth < 600;

                    if (mobile) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: buildSearchField(),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: resetSearch,
                                    child: const Text("Reset"),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: loadUsers,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text("Refresh"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: buildSearchField(),
                          ),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: resetSearch,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff334155),
                              side: const BorderSide(color: Color(0xffdbe2ea)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Reset"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: loadUsers,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Refresh"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2161b5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // RECORD COUNT
              // =================================================
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 20,
                    color: Color(0xff64748b),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    "Users: ${filteredUsers.length}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff475569),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =================================================
              // USER TABLE
              // =================================================
              Expanded(child: SingleChildScrollView(child: buildUserTable())),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH FIELD
  // =========================================================

  Widget buildSearchField() {
    return TextField(
      controller: searchController,

      decoration: InputDecoration(
        hintText: "Search name / email / phone / role",

        prefixIcon: const Icon(
          Icons.search,
          size: 21,
          color: Color(0xff64748b),
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffdbe2ea)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffdbe2ea)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff2161b5), width: 1.5),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class TableHeader extends StatelessWidget {
  final String title;

  const TableHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }
}
