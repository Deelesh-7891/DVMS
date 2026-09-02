import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedReport = "All reports";

  DateTime? fromDate;
  DateTime? toDate;

  // ============================================================
  // SAMPLE REPORT DATA
  // ============================================================

  final List<Map<String, dynamic>> allReports = [
    {
      "reportId": "REP-1001",
      "date": "17-08-2026",
      "type": "Fuel",
      "vehicleNo": "RJ18SS2800",
      "description": "Fuel consumption",
      "amount": "₹3,500",
      "status": "Completed",
    },
    {
      "reportId": "REP-1002",
      "date": "16-08-2026",
      "type": "Service",
      "vehicleNo": "RJ45CH4954",
      "description": "Regular service",
      "amount": "₹4,500",
      "status": "Completed",
    },
    {
      "reportId": "REP-1003",
      "date": "15-08-2026",
      "type": "Insurance",
      "vehicleNo": "RJ45CH1505",
      "description": "Insurance renewal",
      "amount": "₹18,500",
      "status": "Pending",
    },
    {
      "reportId": "REP-1004",
      "date": "14-08-2026",
      "type": "Fuel",
      "vehicleNo": "RJ45CF8745",
      "description": "Fuel consumption",
      "amount": "₹3,000",
      "status": "Completed",
    },
    {
      "reportId": "REP-1005",
      "date": "13-08-2026",
      "type": "Service",
      "vehicleNo": "RJ60CA7012",
      "description": "Vehicle repair",
      "amount": "₹7,800",
      "status": "Pending",
    },
  ];

  List<Map<String, dynamic>> filteredReports = [];

  @override
  void initState() {
    super.initState();

    filteredReports = List.from(allReports);
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
      filteredReports =
          allReports.where((report) {

        final reportId =
            report["reportId"]
                .toString()
                .toLowerCase();

        final vehicleNo =
            report["vehicleNo"]
                .toString()
                .toLowerCase();

        final description =
            report["description"]
                .toString()
                .toLowerCase();

        final matchesSearch =
            reportId.contains(search) ||
            vehicleNo.contains(search) ||
            description.contains(search);

        final matchesType =
            selectedReport == "All reports" ||
            report["type"] == selectedReport;

        return matchesSearch && matchesType;

      }).toList();
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedReport = "All reports";

      fromDate = null;
      toDate = null;

      filteredReports =
          List.from(allReports);
    });
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectFromDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate:
          fromDate ?? DateTime.now(),

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> selectToDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate:
          toDate ?? DateTime.now(),

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
      });
    }
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

        foregroundColor:
            Colors.white,

        title: const Text(
          "Reports",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(
            tooltip: "Export",
            onPressed: exportReport,

            icon: const Icon(
              Icons.download,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(8),

          child: Column(
            children: [

              // ==================================================
              // FILTER
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(18),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffF1F4F8,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xffDCE3EC,
                    ),
                  ),

                  boxShadow: const [
                    BoxShadow(
                      color:
                          Colors.black12,
                      blurRadius: 4,
                      offset:
                          Offset(0, 2),
                    ),
                  ],
                ),

                child:
                    LayoutBuilder(
                  builder:
                      (context, constraints) {

                    final isSmall =
                        width < 700;

                    if (isSmall) {

                      return Column(
                        children: [

                          searchBox(),

                          const SizedBox(
                            height: 10,
                          ),

                          reportTypeDropdown(),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [

                              Expanded(
                                child:
                                    fromDateButton(),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    toDateButton(),
                              ),
                            ],
                          ),

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

                    return Row(
                      children: [

                        SizedBox(
                          width: 250,
                          child:
                              searchBox(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 160,
                          child:
                              reportTypeDropdown(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 150,
                          child:
                              fromDateButton(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 150,
                          child:
                              toDateButton(),
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
                height: 16,
              ),

              // ==================================================
              // SUMMARY CARDS
              // ==================================================

              SizedBox(
                height: 95,

                child:
                    ListView(
                  scrollDirection:
                      Axis.horizontal,

                  children: [

                    summaryCard(
                      "TOTAL REPORTS",
                      "${filteredReports.length}",
                      Icons.assessment,
                      Colors.blue,
                    ),

                    summaryCard(
                      "FUEL",
                      countType("Fuel").toString(),
                      Icons.local_gas_station,
                      Colors.orange,
                    ),

                    summaryCard(
                      "SERVICE",
                      countType("Service").toString(),
                      Icons.build,
                      Colors.red,
                    ),

                    summaryCard(
                      "INSURANCE",
                      countType("Insurance").toString(),
                      Icons.shield,
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // TABLE
              // ==================================================

              Expanded(
                child:
                    Container(
                  width:
                      double.infinity,

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
                        0xffDCE3EC,
                      ),
                    ),
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
                          SingleChildScrollView(
                        child:
                            DataTable(

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

                          columns:
                              const [

                            DataColumn(
                              label:
                                  Text(
                                "REPORT ID",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "DATE",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "TYPE",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "VEHICLE NO",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "DESCRIPTION",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "AMOUNT",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "STATUS",
                              ),
                            ),

                            DataColumn(
                              label:
                                  Text(
                                "VIEW",
                              ),
                            ),
                          ],

                          rows:
                              filteredReports
                                  .map(
                            (report) {

                              return DataRow(
                                cells: [

                                  DataCell(
                                    Text(
                                      report[
                                          "reportId"],
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            Color(
                                          0xff172033,
                                        ),
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      report[
                                          "date"],
                                    ),
                                  ),

                                  DataCell(
                                    typeBadge(
                                      report[
                                          "type"],
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      report[
                                          "vehicleNo"],
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      report[
                                          "description"],
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      report[
                                          "amount"],
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    statusBadge(
                                      report[
                                          "status"],
                                    ),
                                  ),

                                  DataCell(
                                    outlineButton(
                                      "View",
                                      icon:
                                          Icons.visibility,
                                      onPressed:
                                          () {
                                        viewReport(
                                          report,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  "${filteredReports.length} reports found",

                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
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
  // SEARCH
  // ============================================================

  Widget searchBox() {

    return TextField(
      controller:
          searchController,

      decoration:
          InputDecoration(
        hintText:
            "Search report / vehicle no...",

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
  // REPORT TYPE
  // ============================================================

  Widget reportTypeDropdown() {

    final types = [
      "All reports",
      "Fuel",
      "Service",
      "Insurance",
    ];

    return DropdownButtonFormField<String>(
      value:
          selectedReport,

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
          selectedReport =
              value!;
        });
      },
    );
  }

  // ============================================================
  // FROM DATE
  // ============================================================

  Widget fromDateButton() {

    return OutlinedButton.icon(
      onPressed:
          selectFromDate,

      icon:
          const Icon(
        Icons.calendar_today,
        size: 16,
      ),

      label:
          Text(
        fromDate == null
            ? "From Date"
            : formatDate(fromDate!),
      ),

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(
          0xff334155,
        ),

        backgroundColor:
            Colors.white,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
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
    );
  }

  // ============================================================
  // TO DATE
  // ============================================================

  Widget toDateButton() {

    return OutlinedButton.icon(
      onPressed:
          selectToDate,

      icon:
          const Icon(
        Icons.calendar_today,
        size: 16,
      ),

      label:
          Text(
        toDate == null
            ? "To Date"
            : formatDate(toDate!),
      ),

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(
          0xff334155,
        ),

        backgroundColor:
            Colors.white,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
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
    );
  }

  // ============================================================
  // FILTER
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
  // RESET
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
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {

    return Container(
      width: 180,

      margin:
          const EdgeInsets.only(
        right: 12,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border:
            Border.all(
          color:
              const Color(
            0xffDCE3EC,
          ),
        ),
      ),

      child:
          Row(
        children: [

          CircleAvatar(
            backgroundColor:
                color.withOpacity(.12),

            child:
                Icon(
              icon,
              color:
                  color,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget typeBadge(
    String type,
  ) {

    Color color;

    if (type == "Fuel") {
      color = Colors.orange;
    } else if (type == "Service") {
      color = Colors.red;
    } else {
      color = Colors.purple;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),

        borderRadius:
            BorderRadius.circular(15),
      ),

      child:
          Text(
        type,

        style:
            TextStyle(
          color:
              color,

          fontWeight:
              FontWeight.w600,
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

    final bool completed =
        status == "Completed";

    final Color color =
        completed
            ? const Color(
                0xff16A34A,
              )
            : const Color(
                0xffD97706,
              );

    final Color background =
        completed
            ? const Color(
                0xffDCFCE7,
              )
            : const Color(
                0xffFEF3C7,
              );

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
                  color,

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
                  color,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIEW BUTTON
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
  // COUNT REPORT TYPE
  // ============================================================

  int countType(
    String type,
  ) {

    return filteredReports
        .where(
          (report) =>
              report["type"] == type,
        )
        .length;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(
    DateTime date,
  ) {

    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  // ============================================================
  // VIEW REPORT
  // ============================================================

  void viewReport(
    Map<String, dynamic> report,
  ) {

    showDialog(
      context: context,

      builder:
          (context) {

        return AlertDialog(

          title:
              Text(
            "Report ${report["reportId"]}",
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                "Date: ${report["date"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Type: ${report["type"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Vehicle: ${report["vehicleNo"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Description: ${report["description"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Amount: ${report["amount"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Status: ${report["status"]}",
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
  // EXPORT
  // ============================================================

  void exportReport() {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          "Report export will be available here",
        ),
      ),
    );
  }
}