import 'package:flutter/material.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedServiceType = "All services";
  String selectedStatus = "All statuses";

  // ============================================================
  // SAMPLE SERVICE DATA
  // ============================================================

  final List<Map<String, dynamic>> allServices = [
    {
      "serviceId": "SRV-1001",
      "vehicleNo": "RJ18SS2800",
      "date": "17-08-2026",
      "serviceType": "Regular Service",
      "odometer": "5,000 km",
      "serviceCenter": "Prem Motors",
      "amount": "₹4,500",
      "status": "Completed",
    },
    {
      "serviceId": "SRV-1002",
      "vehicleNo": "RJ45CH4954",
      "date": "16-08-2026",
      "serviceType": "Oil Change",
      "odometer": "8,200 km",
      "serviceCenter": "Maruti Service",
      "amount": "₹2,500",
      "status": "Completed",
    },
    {
      "serviceId": "SRV-1003",
      "vehicleNo": "RJ45CH1505",
      "date": "15-08-2026",
      "serviceType": "Repair",
      "odometer": "12,500 km",
      "serviceCenter": "Prem Motors",
      "amount": "₹8,500",
      "status": "Pending",
    },
    {
      "serviceId": "SRV-1004",
      "vehicleNo": "RJ45CF8745",
      "date": "14-08-2026",
      "serviceType": "Regular Service",
      "odometer": "20,000 km",
      "serviceCenter": "WagonR Service",
      "amount": "₹5,200",
      "status": "Completed",
    },
    {
      "serviceId": "SRV-1005",
      "vehicleNo": "RJ60CA7012",
      "date": "13-08-2026",
      "serviceType": "Repair",
      "odometer": "15,800 km",
      "serviceCenter": "Prem Motors",
      "amount": "₹7,800",
      "status": "Pending",
    },
  ];

  List<Map<String, dynamic>> filteredServices = [];

  @override
  void initState() {
    super.initState();

    filteredServices = List.from(allServices);
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
      filteredServices = allServices.where((service) {

        final serviceId =
            service["serviceId"]
                .toString()
                .toLowerCase();

        final vehicleNo =
            service["vehicleNo"]
                .toString()
                .toLowerCase();

        final matchesSearch =
            serviceId.contains(search) ||
            vehicleNo.contains(search);

        final matchesServiceType =
            selectedServiceType == "All services" ||
            service["serviceType"] ==
                selectedServiceType;

        final matchesStatus =
            selectedStatus == "All statuses" ||
            service["status"] ==
                selectedStatus;

        return matchesSearch &&
            matchesServiceType &&
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
      selectedServiceType = "All services";
      selectedStatus = "All statuses";

      filteredServices =
          List.from(allServices);
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
          "Service List",
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

                          serviceTypeDropdown(),

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
                              serviceTypeDropdown(),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        SizedBox(
                          width: 160,
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
                                  Text("SERVICE ID"),
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
                                  Text("SERVICE TYPE"),
                            ),

                            DataColumn(
                              label:
                                  Text("ODOMETER"),
                            ),

                            DataColumn(
                              label:
                                  Text("SERVICE CENTER"),
                            ),

                            DataColumn(
                              label:
                                  Text("AMOUNT"),
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
                              filteredServices
                                  .map((service) {

                            return DataRow(
                              cells: [

                                // SERVICE ID
                                DataCell(
                                  Text(
                                    service[
                                        "serviceId"],
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
                                    service[
                                        "vehicleNo"],
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
                                    service[
                                        "date"],
                                  ),
                                ),

                                // SERVICE TYPE
                                DataCell(
                                  Text(
                                    service[
                                        "serviceType"],
                                  ),
                                ),

                                // ODOMETER
                                DataCell(
                                  Text(
                                    service[
                                        "odometer"],
                                  ),
                                ),

                                // SERVICE CENTER
                                DataCell(
                                  Text(
                                    service[
                                        "serviceCenter"],
                                  ),
                                ),

                                // AMOUNT
                                DataCell(
                                  Text(
                                    service[
                                        "amount"],
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
                                    service[
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
                                      viewService(
                                        service,
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
                                      editService(
                                        service,
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
                  "${filteredServices.length} services found",

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
            "Search service / vehicle no...",

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
  // SERVICE TYPE DROPDOWN
  // ============================================================

  Widget serviceTypeDropdown() {

    final serviceTypes = [
      "All services",
      "Regular Service",
      "Oil Change",
      "Repair",
    ];

    return DropdownButtonFormField<String>(
      value:
          selectedServiceType,

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
          serviceTypes.map((type) {

        return DropdownMenuItem<String>(
          value: type,

          child:
              Text(type),
        );
      }).toList(),

      onChanged:
          (value) {

        setState(() {
          selectedServiceType =
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
      "Completed",
      "Pending",
      "Cancelled",
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

    if (status == "Completed") {

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
  // VIEW SERVICE
  // ============================================================

  void viewService(
    Map<String, dynamic> service,
  ) {

    showDialog(
      context: context,

      builder:
          (context) {

        return AlertDialog(

          title:
              Text(
            "Service ${service["serviceId"]}",
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                "Vehicle: ${service["vehicleNo"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Date: ${service["date"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Service Type: ${service["serviceType"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Odometer: ${service["odometer"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Service Center: ${service["serviceCenter"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Amount: ${service["amount"]}",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "Status: ${service["status"]}",
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
  // EDIT SERVICE
  // ============================================================

  void editService(
    Map<String, dynamic> service,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          "Edit ${service["serviceId"]}",
        ),
      ),
    );
  }
}