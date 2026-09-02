import 'package:flutter/material.dart';

class FuelBillListScreen extends StatefulWidget {
  const FuelBillListScreen({super.key});

  @override
  State<FuelBillListScreen> createState() => _FuelBillListScreenState();
}

class _FuelBillListScreenState extends State<FuelBillListScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedFuel = "All fuels";
  String selectedStatus = "All statuses";

  // ============================================================
  // SAMPLE FUEL BILL DATA
  // ============================================================

  final List<Map<String, dynamic>> allFuelBills = [
    {
      "billNo": "FB-1001",
      "vehicleNo": "RJ18SS2800",
      "date": "17-08-2026",
      "fuel": "Petrol",
      "litres": "35",
      "amount": "₹3,500",
      "vendor": "Indian Oil",
      "status": "Approved",
    },
    {
      "billNo": "FB-1002",
      "vehicleNo": "RJ45CH4954",
      "date": "16-08-2026",
      "fuel": "Petrol",
      "litres": "42",
      "amount": "₹4,200",
      "vendor": "HP Petrol Pump",
      "status": "Pending",
    },
    {
      "billNo": "FB-1003",
      "vehicleNo": "RJ45CH1505",
      "date": "15-08-2026",
      "fuel": "Diesel",
      "litres": "50",
      "amount": "₹4,800",
      "vendor": "BPCL",
      "status": "Approved",
    },
    {
      "billNo": "FB-1004",
      "vehicleNo": "RJ45CF8745",
      "date": "14-08-2026",
      "fuel": "Petrol",
      "litres": "30",
      "amount": "₹3,000",
      "vendor": "Indian Oil",
      "status": "Rejected",
    },
    {
      "billNo": "FB-1005",
      "vehicleNo": "RJ60CA7012",
      "date": "13-08-2026",
      "fuel": "Petrol",
      "litres": "38",
      "amount": "₹3,800",
      "vendor": "HP Petrol Pump",
      "status": "Approved",
    },
  ];

  List<Map<String, dynamic>> filteredFuelBills = [];

  @override
  void initState() {
    super.initState();

    filteredFuelBills = List.from(allFuelBills);
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
    final search =
        searchController.text.trim().toLowerCase();

    setState(() {
      filteredFuelBills = allFuelBills.where((bill) {

        final billNo =
            bill["billNo"].toString().toLowerCase();

        final vehicleNo =
            bill["vehicleNo"].toString().toLowerCase();

        final matchesSearch =
            billNo.contains(search) ||
            vehicleNo.contains(search);

        final matchesFuel =
            selectedFuel == "All fuels" ||
            bill["fuel"] == selectedFuel;

        final matchesStatus =
            selectedStatus == "All statuses" ||
            bill["status"] == selectedStatus;

        return matchesSearch &&
            matchesFuel &&
            matchesStatus;

      }).toList();
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedFuel = "All fuels";
      selectedStatus = "All statuses";

      filteredFuelBills =
          List.from(allFuelBills);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    final width =
        MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor:
          const Color(0xffF4F7FB),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            const Color(0xff2458A6),

        foregroundColor: Colors.white,

        title: const Text(
          "Fuel Bills",
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
              // FILTER SECTION
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color:
                      const Color(0xffF1F4F8),

                  borderRadius:
                      BorderRadius.circular(16),

                  border: Border.all(
                    color:
                        const Color(0xffDCE3EC),
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset:
                          Offset(0, 2),
                    ),
                  ],
                ),

                child: LayoutBuilder(
                  builder:
                      (context, constraints) {

                    final isSmall =
                        width < 700;

                    // ==========================================
                    // MOBILE
                    // ==========================================

                    if (isSmall) {

                      return Column(
                        children: [

                          searchBox(),

                          const SizedBox(
                            height: 10,
                          ),

                          fuelDropdown(),

                          const SizedBox(
                            height: 10,
                          ),

                          statusDropdown(),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [

                              Expanded(
                                child:
                                    filterButton(),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    resetButton(),
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
                          width: 260,
                          child: searchBox(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 160,
                          child: fuelDropdown(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 160,
                          child: statusDropdown(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        filterButton(),

                        const SizedBox(
                          width: 12,
                        ),

                        resetButton(),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // TABLE
              // ==================================================

              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(16),

                    border: Border.all(
                      color:
                          const Color(0xffDCE3EC),
                    ),
                  ),

                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),

                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,

                      child:
                          SingleChildScrollView(
                        child: DataTable(

                          headingRowHeight: 48,

                          dataRowMinHeight: 66,

                          dataRowMaxHeight: 66,

                          columnSpacing: 30,

                          headingRowColor:
                              WidgetStateProperty
                                  .all(
                            const Color(
                              0xffF8FAFD,
                            ),
                          ),

                          // ====================================
                          // COLUMNS
                          // ====================================

                          columns: const [

                            DataColumn(
                              label:
                                  Text("BILL NO"),
                            ),

                            DataColumn(
                              label:
                                  Text("VEHICLE NO"),
                            ),

                            DataColumn(
                              label:
                                  Text("DATE"),
                            ),

                            DataColumn(
                              label:
                                  Text("FUEL"),
                            ),

                            DataColumn(
                              label:
                                  Text("LITRES"),
                            ),

                            DataColumn(
                              label:
                                  Text("AMOUNT"),
                            ),

                            DataColumn(
                              label:
                                  Text("VENDOR"),
                            ),

                            DataColumn(
                              label:
                                  Text("STATUS"),
                            ),

                            DataColumn(
                              label:
                                  Text("VIEW"),
                            ),

                            DataColumn(
                              label:
                                  Text("EDIT"),
                            ),
                          ],

                          // ====================================
                          // ROWS
                          // ====================================

                          rows:
                              filteredFuelBills
                                  .map((bill) {

                            return DataRow(
                              cells: [

                                // BILL NO
                                DataCell(
                                  Text(
                                    bill["billNo"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Color(
                                        0xff172033,
                                      ),
                                    ),
                                  ),
                                ),

                                // VEHICLE NO
                                DataCell(
                                  Text(
                                    bill["vehicleNo"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // DATE
                                DataCell(
                                  Text(
                                    bill["date"],
                                  ),
                                ),

                                // FUEL
                                DataCell(
                                  Text(
                                    bill["fuel"],
                                  ),
                                ),

                                // LITRES
                                DataCell(
                                  Text(
                                    "${bill["litres"]} L",
                                  ),
                                ),

                                // AMOUNT
                                DataCell(
                                  Text(
                                    bill["amount"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Color(
                                        0xff172033,
                                      ),
                                    ),
                                  ),
                                ),

                                // VENDOR
                                DataCell(
                                  Text(
                                    bill["vendor"],
                                  ),
                                ),

                                // STATUS
                                DataCell(
                                  statusBadge(
                                    bill["status"],
                                  ),
                                ),

                                // VIEW
                                DataCell(
                                  outlineButton(
                                    "View",
                                    icon:
                                        Icons.visibility,
                                    onPressed: () {
                                      viewBill(
                                        bill,
                                      );
                                    },
                                  ),
                                ),

                                // EDIT
                                DataCell(
                                  outlineButton(
                                    "Edit",
                                    icon:
                                        Icons.edit,
                                    onPressed: () {
                                      editBill(
                                        bill,
                                      );
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

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // TOTAL
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  "${filteredFuelBills.length} fuel bills found",

                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.w600,
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
      controller:
          searchController,

      decoration:
          InputDecoration(
        hintText:
            "Search bill / vehicle no...",

        prefixIcon:
            const Icon(
          Icons.search,
          size: 20,
        ),

        filled: true,

        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),

          borderSide:
              const BorderSide(
            color:
                Color(0xffDCE3EC),
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),

          borderSide:
              const BorderSide(
            color:
                Color(0xffDCE3EC),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FUEL DROPDOWN
  // ============================================================

  Widget fuelDropdown() {

    final fuels = [
      "All fuels",
      "Petrol",
      "Diesel",
      "CNG",
    ];

    return DropdownButtonFormField<String>(
      value:
          selectedFuel,

      decoration:
          InputDecoration(
        filled: true,

        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),

          borderSide:
              const BorderSide(
            color:
                Color(0xffDCE3EC),
          ),
        ),
      ),

      items:
          fuels.map((fuel) {

        return DropdownMenuItem<String>(
          value: fuel,

          child:
              Text(fuel),
        );
      }).toList(),

      onChanged:
          (value) {

        setState(() {
          selectedFuel =
              value!;
        });
      },
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget statusDropdown() {

    final statuses = [
      "All statuses",
      "Approved",
      "Pending",
      "Rejected",
    ];

    return DropdownButtonFormField<String>(
      value:
          selectedStatus,

      decoration:
          InputDecoration(
        filled: true,

        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),

          borderSide:
              const BorderSide(
            color:
                Color(0xffDCE3EC),
          ),
        ),
      ),

      items:
          statuses.map((status) {

        return DropdownMenuItem<String>(
          value: status,

          child:
              Text(status),
        );
      }).toList(),

      onChanged:
          (value) {

        setState(() {
          selectedStatus =
              value!;
        });
      },
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton() {

    return ElevatedButton(
      onPressed:
          applyFilter,

      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(
          0xff2458A6,
        ),

        foregroundColor:
            Colors.white,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),

      child:
          const Text(
        "Filter",
        style:
            TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget resetButton() {

    return OutlinedButton(
      onPressed:
          resetFilter,

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(
          0xff475569,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        side:
            const BorderSide(
          color:
              Color(0xffDCE3EC),
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),

      child:
          const Text(
        "Reset",
        style:
            TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget statusBadge(
    String status,
  ) {

    Color background;
    Color textColor;

    if (status == "Approved") {

      background =
          const Color(
        0xffDCFCE7,
      );

      textColor =
          const Color(
        0xff16A34A,
      );

    } else if (status == "Pending") {

      background =
          const Color(
        0xffFEF3C7,
      );

      textColor =
          const Color(
        0xffD97706,
      );

    } else {

      background =
          const Color(
        0xffFEE2E2,
      );

      textColor =
          const Color(
        0xffDC2626,
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),

      decoration:
          BoxDecoration(
        color:
            background,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 8,
            height: 8,

            decoration:
                BoxDecoration(
              color:
                  textColor,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            status,

            style:
                TextStyle(
              color:
                  textColor,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OUTLINE BUTTON
  // ============================================================

  Widget outlineButton(
    String text, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {

    return OutlinedButton.icon(
      onPressed:
          onPressed,

      icon:
          Icon(
        icon,
        size: 16,
      ),

      label:
          Text(text),

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(
          0xff334155,
        ),

        side:
            const BorderSide(
          color:
              Color(0xffDCE3EC),
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // VIEW BILL
  // ============================================================

  void viewBill(
    Map<String, dynamic> bill,
  ) {

    showDialog(
      context: context,

      builder:
          (context) {

        return AlertDialog(
          title:
              Text(
            "Fuel Bill ${bill["billNo"]}",
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                "Vehicle: ${bill["vehicleNo"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Date: ${bill["date"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Fuel: ${bill["fuel"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Litres: ${bill["litres"]} L",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Amount: ${bill["amount"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Vendor: ${bill["vendor"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Status: ${bill["status"]}",
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child:
                  const Text(
                "Close",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDIT BILL
  // ============================================================

  void editBill(
    Map<String, dynamic> bill,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          "Edit ${bill["billNo"]}",
        ),
      ),
    );
  }
}