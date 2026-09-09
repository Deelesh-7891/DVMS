import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AllocationsScreen extends StatefulWidget {
  const AllocationsScreen({super.key});

  @override
  State<AllocationsScreen> createState() =>
      _AllocationsScreenState();
}

class _AllocationsScreenState
    extends State<AllocationsScreen> {
  // =========================================================
  // AUTH SERVICE
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController vehicleController =
      TextEditingController();

  final TextEditingController employeeController =
      TextEditingController();

  // =========================================================
  // API DATA
  // =========================================================

  List<dynamic> allAllocations = [];

  List<dynamic> filteredAllocations = [];

  bool isLoading = false;

  String? errorMessage;

  // =========================================================
  // DATE FILTER
  // =========================================================

  DateTime? fromDate;

  DateTime? toDate;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadAllocations();

    vehicleController.addListener(
      applyFilters,
    );

    employeeController.addListener(
      applyFilters,
    );
  }

  // =========================================================
  // LOAD API
  // =========================================================

  Future<void> loadAllocations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await _authService.getmovement();

      if (!mounted) return;

      setState(() {
        allAllocations =
            List<dynamic>.from(result);

        filteredAllocations =
            List<dynamic>.from(result);

        isLoading = false;
      });

      applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage =
            e.toString();

        allAllocations = [];

        filteredAllocations = [];
      });

      debugPrint(
        "Allocation API Error: $e",
      );
    }
  }

  // =========================================================
  // SAFE VALUE
  // =========================================================

  String getValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() !=
              "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // VEHICLE
  // =========================================================

  String getVehicle(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "RegistrationNo",
        "Vehicle",
        "VehicleNo",
        "VehicleNumber",
        "VehicleName",
      ],
    );
  }

  // =========================================================
  // LOCATION
  // =========================================================

  String getLocation(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "Location",
        "LocationName",
        "GateLocation",
        "GateLocationName",
      ],
    );
  }

  // =========================================================
  // EMPLOYEE
  // =========================================================

  String getEmployee(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "EmployeeName",
        "Employee",
        "EmployeeFullName",
        "EmpName",
      ],
    );
  }

  // =========================================================
  // SALES EXECUTIVE
  // =========================================================

  String getSalesExecutive(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "SalesExecutive",
        "SalesExecutiveName",
        "Sales_Executive",
        "SalesPerson",
      ],
    );
  }

  // =========================================================
  // DRIVER
  // =========================================================

  String getDriver(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "DriverName",
        "Driver",
        "DriverFullName",
      ],
    );
  }

  // =========================================================
  // FROM
  // =========================================================

  String getFrom(
    Map<String, dynamic> data,
  ) {
    final location = getValue(
      data,
      [
        "FromLocationName",
        "FromLocation",
      ],
    );

    if (location != "-") {
      return location;
    }

    return getValue(
      data,
      [
        "FromCityName",
        "FromCity",
      ],
    );
  }

  // =========================================================
  // TO
  // =========================================================

  String getTo(
    Map<String, dynamic> data,
  ) {
    final location = getValue(
      data,
      [
        "ToLocationName",
        "ToLocation",
      ],
    );

    if (location != "-") {
      return location;
    }

    return getValue(
      data,
      [
        "ToCityName",
        "ToCity",
      ],
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  String getStatus(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "Status",
        "AllocationStatus",
        "MovementStatus",
      ],
    );
  }

  // =========================================================
  // REMARKS
  // =========================================================

  String getRemarks(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "Remarks",
        "Remark",
        "Comments",
        "Comment",
      ],
    );
  }

  // =========================================================
  // PARSE DATE
  // =========================================================

  DateTime? parseApiDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime
          .parse(
            value.toString(),
          )
          .toLocal();
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // APPLY FILTERS
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        vehicleController.text
            .trim()
            .toLowerCase();

    final employeeSearch =
        employeeController.text
            .trim()
            .toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(
      allAllocations,
    );

    // =======================================================
    // VEHICLE SEARCH
    // =======================================================

    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        return getVehicle(data)
            .toLowerCase()
            .contains(
              vehicleSearch,
            );
      }).toList();
    }

    // =======================================================
    // EMPLOYEE / DRIVER SEARCH
    // =======================================================

    if (employeeSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        final employee =
            getEmployee(data)
                .toLowerCase();

        final driver =
            getDriver(data)
                .toLowerCase();

        final salesExecutive =
            getSalesExecutive(data)
                .toLowerCase();

        return employee.contains(
              employeeSearch,
            ) ||
            driver.contains(
              employeeSearch,
            ) ||
            salesExecutive.contains(
              employeeSearch,
            );
      }).toList();
    }

    // =======================================================
    // FROM DATE
    // =======================================================

    if (fromDate != null) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        final date =
            parseApiDate(
          data["MovementTime"],
        );

        if (date == null) {
          return false;
        }

        final selectedFrom =
            DateTime(
          fromDate!.year,
          fromDate!.month,
          fromDate!.day,
        );

        final movementDate =
            DateTime(
          date.year,
          date.month,
          date.day,
        );

        return !movementDate
            .isBefore(
          selectedFrom,
        );
      }).toList();
    }

    // =======================================================
    // TO DATE
    // =======================================================

    if (toDate != null) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        final date =
            parseApiDate(
          data["MovementTime"],
        );

        if (date == null) {
          return false;
        }

        final selectedTo =
            DateTime(
          toDate!.year,
          toDate!.month,
          toDate!.day,
        );

        final movementDate =
            DateTime(
          date.year,
          date.month,
          date.day,
        );

        return !movementDate
            .isAfter(
          selectedTo,
        );
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredAllocations = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    vehicleController.clear();

    employeeController.clear();

    if (!mounted) return;

    setState(() {
      fromDate = null;

      toDate = null;

      filteredAllocations =
          List<dynamic>.from(
        allAllocations,
      );
    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({
    required bool isFromDate,
  }) async {
    DateTime initialDate =
        DateTime.now();

    if (isFromDate &&
        fromDate != null) {
      initialDate = fromDate!;
    }

    if (!isFromDate &&
        toDate != null) {
      initialDate = toDate!;
    }

    final picked =
        await showDatePicker(
      context: context,

      initialDate: initialDate,

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),

      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary:
                  Color(0xff2161b5),
            ),
          ),
          child:
              child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      if (isFromDate) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });

    applyFilters();
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return "dd-mm-yyyy";
    }

    return
        "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration searchDecoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color:
            Color(0xff64748b),
        fontSize: 15,
      ),

      filled: true,

      fillColor:
          Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            const BorderSide(
          color:
              Color(0xffdbe2ea),
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            const BorderSide(
          color:
              Color(0xffdbe2ea),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            const BorderSide(
          color:
              Color(0xff2161b5),
          width: 1.2,
        ),
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xfff1f4f8),

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              const Color(0xffe1e7ef),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x07000000),
            blurRadius: 6,
            offset:
                Offset(0, 2),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder:
            (
          context,
          constraints,
        ) {
          final isSmall =
              constraints.maxWidth <
                  900;

          if (isSmall) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                // SEARCH VEHICLE
                SizedBox(
                  width:
                      constraints.maxWidth >
                              300
                          ? 300
                          : constraints.maxWidth,
                  height: 44,

                  child: TextField(
                    controller:
                        vehicleController,

                    decoration:
                        searchDecoration(
                      "Type to search...",
                    ),
                  ),
                ),

                // SEARCH EMPLOYEE
                SizedBox(
                  width:
                      constraints.maxWidth >
                              300
                          ? 300
                          : constraints.maxWidth,
                  height: 44,

                  child: TextField(
                    controller:
                        employeeController,

                    decoration:
                        searchDecoration(
                      "Type to search...",
                    ),
                  ),
                ),

                // FROM
                buildDateBox(
                  title:
                      "From  ${formatDate(fromDate)}",

                  onTap: () =>
                      selectDate(
                    isFromDate:
                        true,
                  ),
                ),

                // TO
                buildDateBox(
                  title:
                      "To  ${formatDate(toDate)}",

                  onTap: () =>
                      selectDate(
                    isFromDate:
                        false,
                  ),
                ),

                // RESET
                buildResetButton(),
              ],
            );
          }

          // ===================================================
          // DESKTOP
          // ===================================================

          return Row(
            children: [

              // SEARCH 1
              SizedBox(
                width: 270,
                height: 44,

                child: TextField(
                  controller:
                      vehicleController,

                  decoration:
                      searchDecoration(
                    "Type to search...",
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // SEARCH 2
              SizedBox(
                width: 270,
                height: 44,

                child: TextField(
                  controller:
                      employeeController,

                  decoration:
                      searchDecoration(
                    "Type to search...",
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // FROM DATE
              Expanded(
                child: buildDateBox(
                  title:
                      "From  ${formatDate(fromDate)}",

                  onTap: () =>
                      selectDate(
                    isFromDate:
                        true,
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // TO DATE
              Expanded(
                child: buildDateBox(
                  title:
                      "To  ${formatDate(toDate)}",

                  onTap: () =>
                      selectDate(
                    isFromDate:
                        false,
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // RESET
              buildResetButton(),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // DATE BOX
  // =========================================================

  Widget buildDateBox({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(10),

      child: Container(
        height: 44,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            10,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xffdbe2ea,
            ),
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: RichText(
                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                text:
                    TextSpan(
                  children: [

                    if (title
                        .startsWith(
                      "From",
                    ))
                      const TextSpan(
                        text: "From  ",
                        style:
                            TextStyle(
                          fontSize: 15,
                          color:
                              Color(
                            0xff8da0b9,
                          ),
                        ),
                      ),

                    if (title
                        .startsWith(
                      "To",
                    ))
                      const TextSpan(
                        text: "To  ",
                        style:
                            TextStyle(
                          fontSize: 15,
                          color:
                              Color(
                            0xff8da0b9,
                          ),
                        ),
                      ),

                    TextSpan(
                      text: title
                          .replaceFirst(
                        "From  ",
                        "",
                      )
                          .replaceFirst(
                        "To  ",
                        "",
                      ),

                      style:
                          const TextStyle(
                        fontSize: 15,
                        color:
                            Color(
                          0xff111827,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Icon(
              Icons
                  .calendar_today_outlined,
              size: 18,
              color:
                  Color(0xff111827),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RESET BUTTON
  // =========================================================

  Widget buildResetButton() {
    return SizedBox(
      height: 44,

      child: OutlinedButton(
        onPressed:
            resetFilters,

        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              Colors.white,

          foregroundColor:
              const Color(
            0xff334155,
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),

          side:
              const BorderSide(
            color:
                Color(0xffd5dde7),
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
        ),

        child: const Text(
          "Reset",

          style:
              TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget buildTableHeader(
    String title,
  ) {
    return Text(
      title,

      maxLines: 1,

      overflow:
          TextOverflow.ellipsis,

      style:
          const TextStyle(
        fontSize: 12,

        fontWeight:
            FontWeight.w700,

        letterSpacing:
            0.4,

        color:
            Color(0xff8da0b9),
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget buildAllocationTable() {
    // =======================================================
    // LOADING
    // =======================================================

    if (isLoading) {
      return Container(
        width: double.infinity,

        height: 160,

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xffe2e8f0,
            ),
          ),
        ),

        child:
            const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // =======================================================
    // ERROR
    // =======================================================

    if (errorMessage != null) {
      return Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(40),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xffe2e8f0,
            ),
          ),
        ),

        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [

            const Icon(
              Icons.error_outline,
              color:
                  Colors.red,
              size: 45,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              errorMessage!,
              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Colors.red,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton(
              onPressed:
                  loadAllocations,

              child:
                  const Text(
                "Retry",
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // EMPTY
    // =======================================================

    if (filteredAllocations
        .isEmpty) {
      return Container(
        width: double.infinity,

        height: 162,

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xffe2e8f0,
            ),
          ),

          boxShadow: const [
            BoxShadow(
              color:
                  Color(0x06000000),
              blurRadius: 6,
              offset:
                  Offset(0, 2),
            ),
          ],
        ),

        child:
            Column(
          children: [

            // TABLE HEADER
            Container(
              height: 48,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),

              decoration:
                  const BoxDecoration(
                border:
                    Border(
                  bottom:
                      BorderSide(
                    color:
                        Color(
                      0xffe2e8f0,
                    ),
                  ),
                ),
              ),

              child:
                  Row(
                children: [

                  _headerCell(
                    "VEHICLE",
                    170,
                  ),

                  _headerCell(
                    "LOCATION",
                    190,
                  ),

                  _headerCell(
                    "EMPLOYEE",
                    190,
                  ),

                  _headerCell(
                    "SALES EXECUTIVE",
                    220,
                  ),

                  _headerCell(
                    "DRIVER",
                    170,
                  ),

                  _headerCell(
                    "FROM",
                    160,
                  ),

                  _headerCell(
                    "TO",
                    160,
                  ),

                  _headerCell(
                    "STATUS",
                    140,
                  ),

                  _headerCell(
                    "REMARKS",
                    180,
                  ),
                ],
              ),
            ),

            const Expanded(
              child:
                  Center(
                child:
                    Text(
                  "No allocations yet",

                  style:
                      TextStyle(
                    fontSize: 15,

                    color:
                        Color(
                      0xff8da0b9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // DATA TABLE
    // =======================================================

    return Container(
      width: double.infinity,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xffe2e8f0,
          ),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x06000000),
            blurRadius: 6,
            offset:
                Offset(0, 2),
          ),
        ],
      ),

      child:
          ClipRRect(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child:
              DataTable(
            horizontalMargin:
                18,

            columnSpacing:
                30,

            headingRowHeight:
                48,

            dataRowMinHeight:
                60,

            dataRowMaxHeight:
                76,

            columns: const [

              DataColumn(
                label:
                    AllocationHeader(
                  "VEHICLE",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "LOCATION",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "EMPLOYEE",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "SALES EXECUTIVE",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "DRIVER",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "FROM",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "TO",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "STATUS",
                ),
              ),

              DataColumn(
                label:
                    AllocationHeader(
                  "REMARKS",
                ),
              ),
            ],

            rows:
                filteredAllocations
                    .map<DataRow>(
              (item) {

                final data =
                    Map<String,
                            dynamic>.from(
                  item,
                );

                return DataRow(
                  cells: [

                    // VEHICLE
                    DataCell(
                      SizedBox(
                        width: 150,

                        child:
                            Text(
                          getVehicle(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight
                                    .w700,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // LOCATION
                    DataCell(
                      SizedBox(
                        width: 170,

                        child:
                            Text(
                          getLocation(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // EMPLOYEE
                    DataCell(
                      SizedBox(
                        width: 170,

                        child:
                            Text(
                          getEmployee(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight
                                    .w600,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SALES EXECUTIVE
                    DataCell(
                      SizedBox(
                        width: 200,

                        child:
                            Text(
                          getSalesExecutive(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // DRIVER
                    DataCell(
                      SizedBox(
                        width: 150,

                        child:
                            Text(
                          getDriver(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // FROM
                    DataCell(
                      SizedBox(
                        width: 150,

                        child:
                            Text(
                          getFrom(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TO
                    DataCell(
                      SizedBox(
                        width: 150,

                        child:
                            Text(
                          getTo(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff111827,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // STATUS
                    DataCell(
                      statusBadge(
                        getStatus(
                          data,
                        ),
                      ),
                    ),

                    // REMARKS
                    DataCell(
                      SizedBox(
                        width: 170,

                        child:
                            Text(
                          getRemarks(
                            data,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff64748b,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY HEADER CELL
  // =========================================================

  Widget _headerCell(
    String title,
    double width,
  ) {
    return SizedBox(
      width: width,

      child:
          Text(
        title,

        maxLines: 1,

        overflow:
            TextOverflow.ellipsis,

        style:
            const TextStyle(
          fontSize: 12,

          fontWeight:
              FontWeight.w700,

          letterSpacing:
              0.4,

          color:
              Color(0xff8da0b9),
        ),
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget statusBadge(
    String status,
  ) {
    final value =
        status.toLowerCase();

    Color background;
    Color foreground;

    if (value == "active" ||
        value == "allocated" ||
        value == "approved" ||
        value == "completed") {
      background =
          const Color(
        0xffdcfce7,
      );

      foreground =
          const Color(
        0xff15803d,
      );
    } else if (value ==
            "pending" ||
        value == "in progress") {
      background =
          const Color(
        0xfffff1c7,
      );

      foreground =
          const Color(
        0xffb45309,
      );
    } else if (value ==
            "cancelled" ||
        value == "rejected") {
      background =
          const Color(
        0xffffe4e6,
      );

      foreground =
          const Color(
        0xffbe123c,
      );
    } else {
      background =
          const Color(
        0xfff1f5f9,
      );

      foreground =
          const Color(
        0xff475569,
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color: background,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        status == "-"
            ? "Pending"
            : status,

        style:
            TextStyle(
          fontSize: 12,

          fontWeight:
              FontWeight.w700,

          color:
              foreground,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xfff4f7fb,
      ),

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            20,
          ),

          child:
              Column(
            children: [

              // =================================================
              // FILTER
              // =================================================

              buildFilterSection(),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // TABLE
              // =================================================

              buildAllocationTable(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    vehicleController.dispose();

    employeeController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class AllocationHeader
    extends StatelessWidget {
  final String title;

  const AllocationHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,

      maxLines: 1,

      overflow:
          TextOverflow.ellipsis,

      style:
          const TextStyle(
        fontSize: 12,

        fontWeight:
            FontWeight.w700,

        letterSpacing:
            0.4,

        color:
            Color(0xff8da0b9),
      ),
    );
  }
}