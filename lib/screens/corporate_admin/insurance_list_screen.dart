import 'package:flutter/material.dart';

class InsuranceListScreen extends StatefulWidget {
  const InsuranceListScreen({super.key});

  @override
  State<InsuranceListScreen> createState() =>
      _InsuranceListScreenState();
}

class _InsuranceListScreenState extends State<InsuranceListScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedInsuranceType = "All types";
  String selectedStatus = "All statuses";

  // ============================================================
  // SAMPLE INSURANCE DATA
  // ============================================================

  final List<Map<String, dynamic>> allInsurance = [
    {
      "policyNo": "POL-1001",
      "vehicleNo": "RJ18SS2800",
      "company": "ICICI Lombard",
      "type": "Comprehensive",
      "startDate": "01-08-2025",
      "expiryDate": "31-07-2026",
      "premium": "₹18,500",
      "status": "Expired",
    },
    {
      "policyNo": "POL-1002",
      "vehicleNo": "RJ45CH4954",
      "company": "HDFC ERGO",
      "type": "Comprehensive",
      "startDate": "15-08-2025",
      "expiryDate": "14-08-2026",
      "premium": "₹16,200",
      "status": "Active",
    },
    {
      "policyNo": "POL-1003",
      "vehicleNo": "RJ45CH1505",
      "company": "Bajaj Allianz",
      "type": "Third Party",
      "startDate": "20-08-2025",
      "expiryDate": "19-08-2026",
      "premium": "₹8,500",
      "status": "Expiring Soon",
    },
    {
      "policyNo": "POL-1004",
      "vehicleNo": "RJ45CF8745",
      "company": "New India Assurance",
      "type": "Comprehensive",
      "startDate": "01-09-2025",
      "expiryDate": "31-08-2026",
      "premium": "₹19,800",
      "status": "Active",
    },
    {
      "policyNo": "POL-1005",
      "vehicleNo": "RJ60CA7012",
      "company": "Tata AIG",
      "type": "Third Party",
      "startDate": "10-07-2025",
      "expiryDate": "09-07-2026",
      "premium": "₹7,900",
      "status": "Expired",
    },
  ];

  List<Map<String, dynamic>> filteredInsurance = [];

  @override
  void initState() {
    super.initState();

    filteredInsurance = List.from(allInsurance);
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
      filteredInsurance =
          allInsurance.where((insurance) {

        final policyNo =
            insurance["policyNo"]
                .toString()
                .toLowerCase();

        final vehicleNo =
            insurance["vehicleNo"]
                .toString()
                .toLowerCase();

        final matchesSearch =
            policyNo.contains(search) ||
            vehicleNo.contains(search);

        final matchesType =
            selectedInsuranceType == "All types" ||
            insurance["type"] ==
                selectedInsuranceType;

        final matchesStatus =
            selectedStatus == "All statuses" ||
            insurance["status"] ==
                selectedStatus;

        return matchesSearch &&
            matchesType &&
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
      selectedInsuranceType = "All types";
      selectedStatus = "All statuses";

      filteredInsurance =
          List.from(allInsurance);
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
          "Insurance",
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

                          insuranceTypeDropdown(),

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
                          width: 280,
                          child: searchBox(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 180,
                          child:
                              insuranceTypeDropdown(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 170,
                          child:
                              statusDropdown(),
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

                          headingRowHeight:
                              48,

                          dataRowMinHeight:
                              66,

                          dataRowMaxHeight:
                              66,

                          columnSpacing:
                              30,

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
                                  Text("POLICY NO"),
                            ),

                            DataColumn(
                              label:
                                  Text("VEHICLE NO"),
                            ),

                            DataColumn(
                              label:
                                  Text("COMPANY"),
                            ),

                            DataColumn(
                              label:
                                  Text("TYPE"),
                            ),

                            DataColumn(
                              label:
                                  Text("START DATE"),
                            ),

                            DataColumn(
                              label:
                                  Text("EXPIRY DATE"),
                            ),

                            DataColumn(
                              label:
                                  Text("PREMIUM"),
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
                              filteredInsurance
                                  .map((insurance) {

                            return DataRow(
                              cells: [

                                // POLICY NO
                                DataCell(
                                  Text(
                                    insurance[
                                        "policyNo"],
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
                                    insurance[
                                        "vehicleNo"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // COMPANY
                                DataCell(
                                  Text(
                                    insurance[
                                        "company"],
                                  ),
                                ),

                                // TYPE
                                DataCell(
                                  Text(
                                    insurance[
                                        "type"],
                                  ),
                                ),

                                // START DATE
                                DataCell(
                                  Text(
                                    insurance[
                                        "startDate"],
                                  ),
                                ),

                                // EXPIRY DATE
                                DataCell(
                                  Text(
                                    insurance[
                                        "expiryDate"],
                                  ),
                                ),

                                // PREMIUM
                                DataCell(
                                  Text(
                                    insurance[
                                        "premium"],
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // STATUS
                                DataCell(
                                  statusBadge(
                                    insurance[
                                        "status"],
                                  ),
                                ),

                                // VIEW
                                DataCell(
                                  outlineButton(
                                    "View",
                                    icon:
                                        Icons.visibility,
                                    onPressed: () {
                                      viewInsurance(
                                        insurance,
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
                                      editInsurance(
                                        insurance,
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
                  "${filteredInsurance.length} insurance records found",

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
            "Search policy / vehicle no...",

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
  // INSURANCE TYPE DROPDOWN
  // ============================================================

  Widget insuranceTypeDropdown() {

    final types = [
      "All types",
      "Comprehensive",
      "Third Party",
    ];

    return DropdownButtonFormField<String>(
      value:
          selectedInsuranceType,

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
          types.map((type) {

        return DropdownMenuItem<String>(
          value: type,

          child:
              Text(type),
        );
      }).toList(),

      onChanged:
          (value) {

        setState(() {
          selectedInsuranceType =
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
      "Active",
      "Expired",
      "Expiring Soon",
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

    if (status == "Active") {

      background =
          const Color(
        0xffDCFCE7,
      );

      textColor =
          const Color(
        0xff16A34A,
      );

    } else if (status == "Expiring Soon") {

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
  // BUTTON
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
  // VIEW INSURANCE
  // ============================================================

  void viewInsurance(
    Map<String, dynamic> insurance,
  ) {

    showDialog(
      context: context,

      builder:
          (context) {

        return AlertDialog(

          title:
              Text(
            "Policy ${insurance["policyNo"]}",
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                "Vehicle: ${insurance["vehicleNo"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Company: ${insurance["company"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Type: ${insurance["type"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Start Date: ${insurance["startDate"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Expiry Date: ${insurance["expiryDate"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Premium: ${insurance["premium"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Status: ${insurance["status"]}",
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
  // EDIT INSURANCE
  // ============================================================

  void editInsurance(
    Map<String, dynamic> insurance,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          "Edit ${insurance["policyNo"]}",
        ),
      ),
    );
  }
}