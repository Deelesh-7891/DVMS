import 'package:flutter/material.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All statuses";

  final List<Map<String, dynamic>> allDrivers = [
    {
      "name": "Rahul Kumar",
      "mobile": "9876543210",
      "license": "RJ142023001",
      "status": "Active",
    },
    {
      "name": "Amit Sharma",
      "mobile": "9876543211",
      "license": "RJ142023002",
      "status": "Active",
    },
    {
      "name": "Vijay Singh",
      "mobile": "9876543212",
      "license": "RJ142023003",
      "status": "Inactive",
    },
  ];

  List<Map<String, dynamic>> filteredDrivers = [];

  @override
  void initState() {
    super.initState();
    filteredDrivers = List.from(allDrivers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER
  // ============================================================

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredDrivers = allDrivers.where((driver) {
        final name = driver["name"].toString().toLowerCase();
        final mobile = driver["mobile"].toString().toLowerCase();
        final license = driver["license"].toString().toLowerCase();

        final matchesSearch =
            name.contains(search) ||
            mobile.contains(search) ||
            license.contains(search);

        final matchesStatus =
            selectedStatus == "All statuses" ||
            driver["status"] == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedStatus = "All statuses";
      filteredDrivers = List.from(allDrivers);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,

        title: const Text(
          "Drivers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),

          child: Column(
            children: [

              // ==================================================
              // FILTER CONTAINER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xffF1F4F8),
                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: const Color(0xffDCE3EC),
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {

                    final isSmall = width < 700;

                    // ==========================================
                    // MOBILE
                    // ==========================================

                    if (isSmall) {
                      return Column(
                        children: [

                          searchBox(),

                          const SizedBox(height: 10),

                          statusDropdown(),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              Expanded(
                                child: filterButton(),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: resetButton(),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // ==========================================
                    // DESKTOP / TABLET
                    // ==========================================

                    return Row(
                      children: [

                        SizedBox(
                          width: 300,
                          child: searchBox(),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 180,
                          child: statusDropdown(),
                        ),

                        const SizedBox(width: 12),

                        filterButton(),

                        const SizedBox(width: 12),

                        resetButton(),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TABLE
              // ==================================================

              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(
                      color: const Color(0xffDCE3EC),
                    ),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),

                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: SingleChildScrollView(
                        child: DataTable(

                          headingRowHeight: 48,

                          dataRowMinHeight: 66,
                          dataRowMaxHeight: 66,

                          columnSpacing: 35,

                          headingRowColor:
                              WidgetStateProperty.all(
                            const Color(0xffF8FAFD),
                          ),

                          // ======================================
                          // HEADERS
                          // ======================================

                          columns: const [

                            DataColumn(
                              label: Text("NAME"),
                            ),

                            DataColumn(
                              label: Text("MOBILE"),
                            ),

                            DataColumn(
                              label: Text("LICENSE"),
                            ),

                            DataColumn(
                              label: Text("STATUS"),
                            ),

                            DataColumn(
                              label: Text("CALL"),
                            ),

                            DataColumn(
                              label: Text("EDIT"),
                            ),
                          ],

                          // ======================================
                          // ROWS
                          // ======================================

                          rows: filteredDrivers.map((driver) {

                            return DataRow(
                              cells: [

                                // ==============================
                                // NAME
                                // ==============================

                                DataCell(
                                  Text(
                                    driver["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // MOBILE
                                // ==============================

                                DataCell(
                                  Text(
                                    driver["mobile"],
                                    style: const TextStyle(
                                      color: Color(0xff334155),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // LICENSE
                                // ==============================

                                DataCell(
                                  Text(
                                    driver["license"],
                                    style: const TextStyle(
                                      color: Color(0xff334155),
                                    ),
                                  ),
                                ),

                                // ==============================
                                // STATUS
                                // ==============================

                                DataCell(
                                  statusBadge(
                                    driver["status"],
                                  ),
                                ),

                                // ==============================
                                // CALL
                                // ==============================

                                DataCell(
                                  outlineButton(
                                    "Call",
                                    icon: Icons.phone,
                                    onPressed: () {
                                      callDriver(driver);
                                    },
                                  ),
                                ),

                                // ==============================
                                // EDIT
                                // ==============================

                                DataCell(
                                  outlineButton(
                                    "Edit",
                                    icon: Icons.edit,
                                    onPressed: () {
                                      editDriver(driver);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // TOTAL
              // ==================================================

              Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  "${filteredDrivers.length} drivers found",

                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

  Widget searchBox() {
    return TextField(
      controller: searchController,

      decoration: InputDecoration(
        hintText: "Search driver...",

        prefixIcon: const Icon(
          Icons.search,
          size: 20,
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget statusDropdown() {
    final statuses = [
      "All statuses",
      "Active",
      "Inactive",
    ];

    return DropdownButtonFormField<String>(
      value: selectedStatus,

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: const BorderSide(
            color: Color(0xffDCE3EC),
          ),
        ),
      ),

      items: statuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
      },
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton() {
    return ElevatedButton(
      onPressed: applyFilter,

      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      child: const Text(
        "Filter",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget resetButton() {
    return OutlinedButton(
      onPressed: resetFilter,

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff475569),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        side: const BorderSide(
          color: Color(0xffDCE3EC),
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      child: const Text(
        "Reset",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget statusBadge(String status) {

    Color background;
    Color textColor;

    if (status == "Active") {
      background = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else {
      background = const Color(0xffFEE2E2);
      textColor = const Color(0xffDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [

          Container(
            width: 8,
            height: 8,

            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            status,

            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget outlineButton(
    String text, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,

      icon: Icon(
        icon,
        size: 16,
      ),

      label: Text(text),

      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff334155),

        side: const BorderSide(
          color: Color(0xffDCE3EC),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // CALL DRIVER
  // ============================================================

  void callDriver(Map<String, dynamic> driver) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Call ${driver["name"]} - ${driver["mobile"]}",
        ),
      ),
    );
  }

  // ============================================================
  // EDIT DRIVER
  // ============================================================

  void editDriver(Map<String, dynamic> driver) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Edit ${driver["name"]}",
        ),
      ),
    );
  }
}