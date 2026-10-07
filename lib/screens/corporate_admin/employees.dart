import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  // =========================================================
  // AUTH SERVICE
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController nameController = TextEditingController();

  final TextEditingController codeController = TextEditingController();

  final TextEditingController departmentController = TextEditingController();

  // =========================================================
  // API DATA
  // =========================================================

  List<dynamic> allEmployees = [];

  List<dynamic> filteredEmployees = [];

  bool isLoading = false;

  String? errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadEmployees();

    nameController.addListener(applyFilters);

    codeController.addListener(applyFilters);

    departmentController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD EMPLOYEES
  // =========================================================

  Future<void> loadEmployees() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getemployees();

      if (!mounted) return;

      setState(() {
        allEmployees = List<dynamic>.from(result);

        filteredEmployees = List<dynamic>.from(result);

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e.toString();

        allEmployees = [];

        filteredEmployees = [];
      });

      debugPrint("Employees API Error: $e");
    }
  }

  // =========================================================
  // GET VALUE HELPER
  // =========================================================

  String getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // NAME
  // =========================================================

  String getEmployeeName(Map<String, dynamic> data) {
    return getValue(data, [
      "Name",
      "EmployeeName",
      "Employee_Name",
      "FullName",
      "Full_Name",
      "UserName",
      "Username",
    ]);
  }

  // =========================================================
  // CODE
  // =========================================================

  String getEmployeeCode(Map<String, dynamic> data) {
    return getValue(data, [
      "Code",
      "EmployeeCode",
      "Employee_Code",
      "EmpCode",
      "Emp_Code",
    ]);
  }

  // =========================================================
  // DEPARTMENT
  // =========================================================

  String getDepartment(Map<String, dynamic> data) {
    return getValue(data, [
      "Department",
      "DepartmentName",
      "Department_Name",
      "DeptName",
      "Dept",
    ]);
  }

  // =========================================================
  // LOCATION
  // =========================================================

  String getLocation(Map<String, dynamic> data) {
    return getValue(data, [
      "Location",
      "LocationName",
      "Location_Name",
      "EmployeeLocation",
      "Address",
    ]);
  }

  // =========================================================
  // CONTACT
  // =========================================================

  String getContact(Map<String, dynamic> data) {
    return getValue(data, [
      "Contact",
      "ContactNo",
      "ContactNumber",
      "Mobile",
      "MobileNo",
      "Phone",
      "PhoneNumber",
    ]);
  }

  // =========================================================
  // FUEL USED
  // =========================================================

  double getFuelUsed(Map<String, dynamic> data) {
    final value = getValue(data, [
      "FuelUsed",
      "Fuel_Used",
      "FuelUsage",
      "FuelUsageThisMonth",
      "MonthlyFuelUsed",
      "UsedFuel",
    ]);

    return double.tryParse(value) ?? 0;
  }

  // =========================================================
  // FUEL LIMIT
  // =========================================================

  double getFuelLimit(Map<String, dynamic> data) {
    final value = getValue(data, [
      "FuelLimit",
      "Fuel_Limit",
      "MonthlyFuelLimit",
      "FuelQuota",
      "FuelLimitThisMonth",
      "Limit",
    ]);

    return double.tryParse(value) ?? 0;
  }

  // =========================================================
  // APPLY FILTERS
  // =========================================================

  void applyFilters() {
    final nameSearch = nameController.text.trim().toLowerCase();

    final codeSearch = codeController.text.trim().toLowerCase();

    final departmentSearch = departmentController.text.trim().toLowerCase();

    List<dynamic> result = List<dynamic>.from(allEmployees);

    // =======================================================
    // NAME FILTER
    // =======================================================

    if (nameSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final name = getEmployeeName(data).toLowerCase();

        return name.contains(nameSearch);
      }).toList();
    }

    // =======================================================
    // CODE FILTER
    // =======================================================

    if (codeSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final code = getEmployeeCode(data).toLowerCase();

        return code.contains(codeSearch);
      }).toList();
    }

    // =======================================================
    // DEPARTMENT FILTER
    // =======================================================

    if (departmentSearch.isNotEmpty) {
      result = result.where((item) {
        final data = Map<String, dynamic>.from(item);

        final department = getDepartment(data).toLowerCase();

        return department.contains(departmentSearch);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredEmployees = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    nameController.clear();
    codeController.clear();
    departmentController.clear();

    if (!mounted) return;

    setState(() {
      filteredEmployees = List<dynamic>.from(allEmployees);
    });
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration employeeInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xff64748b), fontSize: 14),

      filled: true,

      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

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

        borderSide: const BorderSide(color: Color(0xff2161b5), width: 1.2),
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),

      decoration: BoxDecoration(
        color: const Color(0xfff1f4f8),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xffe1e7ef)),

        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Wrap(
        spacing: 14,
        runSpacing: 12,

        crossAxisAlignment: WrapCrossAlignment.center,

        children: [
          // =================================================
          // SEARCH NAME
          // =================================================
          SizedBox(
            width: 270,
            height: 44,

            child: TextField(
              controller: nameController,

              decoration: employeeInputDecoration("Search name..."),
            ),
          ),

          // =================================================
          // SEARCH CODE
          // =================================================
          SizedBox(
            width: 270,
            height: 44,

            child: TextField(
              controller: codeController,

              decoration: employeeInputDecoration("Search code..."),
            ),
          ),

          // =================================================
          // DEPARTMENT
          // =================================================
          SizedBox(
            width: 270,
            height: 44,

            child: TextField(
              controller: departmentController,

              decoration: employeeInputDecoration("Type to search..."),
            ),
          ),

          // =================================================
          // FILTER BUTTON
          // =================================================
          SizedBox(
            height: 44,

            child: ElevatedButton(
              onPressed: applyFilters,

              style: ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor: const Color(0xff2161b5),

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(horizontal: 20),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: const Text(
                "Filter",

                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // =================================================
          // RESET BUTTON
          // =================================================
          SizedBox(
            height: 44,

            child: OutlinedButton(
              onPressed: resetFilters,

              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,

                foregroundColor: const Color(0xff475569),

                side: const BorderSide(color: Color(0xffd8e0e9)),

                padding: const EdgeInsets.symmetric(horizontal: 18),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: const Text(
                "Reset",

                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPLOYEE TABLE
  // =========================================================

  Widget buildEmployeeTable() {
    // =======================================================
    // LOADING
    // =======================================================

    if (isLoading) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(50),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xffe2e8f0)),
        ),

        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // =======================================================
    // ERROR
    // =======================================================

    if (errorMessage != null) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(40),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xffe2e8f0)),
        ),

        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),

              const SizedBox(height: 10),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,

                style: const TextStyle(color: Colors.red),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: loadEmployees,

                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // EMPTY
    // =======================================================

    if (filteredEmployees.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(50),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xffe2e8f0)),
        ),

        child: const Center(
          child: Text(
            "No employees found",

            style: TextStyle(fontSize: 15, color: Color(0xff64748b)),
          ),
        ),
      );
    }

    // =======================================================
    // TABLE
    // =======================================================

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xffe2e8f0)),

        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: DataTable(
            horizontalMargin: 18,

            columnSpacing: 32,

            headingRowHeight: 48,

            dataRowMinHeight: 66,

            dataRowMaxHeight: 82,

            columns: const [
              // NAME
              DataColumn(label: EmployeeHeader("NAME")),

              // CODE
              DataColumn(label: EmployeeHeader("CODE")),

              // DEPARTMENT
              DataColumn(label: EmployeeHeader("DEPARTMENT")),

              // LOCATION
              DataColumn(label: EmployeeHeader("LOCATION")),

              // CONTACT
              DataColumn(label: EmployeeHeader("CONTACT")),

              // FUEL
              DataColumn(label: EmployeeHeader("THIS MONTH'S FUEL USAGE")),
            ],

            rows: filteredEmployees.map<DataRow>((item) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(item);

              final name = getEmployeeName(data);

              final code = getEmployeeCode(data);

              final department = getDepartment(data);

              final location = getLocation(data);

              final contact = getContact(data);

              final fuelUsed = getFuelUsed(data);

              final fuelLimit = getFuelLimit(data);

              final bool hasLimit = fuelLimit > 0;

              double progress = 0;

              if (hasLimit) {
                progress = fuelUsed / fuelLimit;

                if (progress < 0) {
                  progress = 0;
                }

                if (progress > 1) {
                  progress = 1;
                }
              }

              return DataRow(
                cells: [
                  // =================================================
                  // NAME
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 195,

                      child: Text(
                        name,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 15,

                          fontWeight: FontWeight.w800,

                          color: Color(0xff0f172a),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // CODE
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 140,

                      child: Text(
                        code,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,

                          color: Color(0xff8ba0bb),

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // DEPARTMENT
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 170,

                      child: Text(
                        department,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,

                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // LOCATION
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 370,

                      child: Text(
                        location,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,

                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // CONTACT
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 150,

                      child: Text(
                        contact,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,

                          color: Color(0xff8ba0bb),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // FUEL USAGE
                  // =================================================
                  DataCell(
                    SizedBox(
                      width: 320,

                      child: hasLimit
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  "${fuelUsed.toStringAsFixed(0)}L / "
                                  "${fuelLimit.toStringAsFixed(0)}L",

                                  style: const TextStyle(
                                    fontSize: 14,

                                    color: Color(0xff0f172a),
                                  ),
                                ),

                                const SizedBox(height: 7),

                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),

                                  child: LinearProgressIndicator(
                                    value: progress,

                                    minHeight: 10,

                                    backgroundColor: const Color(0xffedf1f6),

                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress >= 1
                                          ? const Color(0xffef4444)
                                          : const Color(0xff2161b5),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              "No limit",

                              style: TextStyle(
                                fontSize: 14,

                                color: Color(0xff64748b),
                              ),
                            ),
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

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // PAGE HEADER
            // =================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),

              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Employees",

                          style: TextStyle(
                            fontSize: 25,

                            fontWeight: FontWeight.w800,

                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "Employee fuel usage and information",

                          style: TextStyle(
                            fontSize: 13,

                            color: Color(0xff64748b),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Total Employees: "
                                "${filteredEmployees.length}",

                                style: const TextStyle(
                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: Color(0xff475569),
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip: "Refresh",

                              onPressed: loadEmployees,

                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      // =================================================
                      // TITLE
                      // =================================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: const [
                            Text(
                              "Employees",

                              style: TextStyle(
                                fontSize: 25,

                                fontWeight: FontWeight.w800,

                                color: Colors.black,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              "Employee fuel usage and information",

                              style: TextStyle(
                                fontSize: 14,

                                color: Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =================================================
                      // COUNT
                      // =================================================
                      Text(
                        "Total Employees: "
                        "${filteredEmployees.length}",

                        style: const TextStyle(
                          fontSize: 14,

                          fontWeight: FontWeight.w600,

                          color: Color(0xff475569),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // =================================================
                      // REFRESH
                      // =================================================
                      IconButton(
                        tooltip: "Refresh",

                        onPressed: loadEmployees,

                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  );
                },
              ),
            ),

            // =================================================
            // MAIN CONTENT
            // =================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // FILTER
                    // =================================================
                    buildFilterSection(),

                    const SizedBox(height: 18),

                    // =================================================
                    // TABLE
                    // =================================================
                    buildEmployeeTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    nameController.dispose();

    codeController.dispose();

    departmentController.dispose();

    super.dispose();
  }
}

// =============================================================
// EMPLOYEE TABLE HEADER
// =============================================================

class EmployeeHeader extends StatelessWidget {
  final String title;

  const EmployeeHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,

      maxLines: 1,

      overflow: TextOverflow.ellipsis,

      style: const TextStyle(
        fontSize: 12,

        fontWeight: FontWeight.w700,

        letterSpacing: 0.4,

        color: Color(0xff8da0b9),
      ),
    );
  }
}
