import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // =========================================================
  // AUTH SERVICE
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController vehicleController =
      TextEditingController();

  final TextEditingController typeController =
      TextEditingController();

  final TextEditingController vendorController =
      TextEditingController();

  // =========================================================
  // API DATA
  // =========================================================

  List<dynamic> allExpenses = [];

  List<dynamic> filteredExpenses = [];

  bool isLoading = false;

  String? errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadExpenses();
  }

  // =========================================================
  // LOAD EXPENSES
  // =========================================================

  Future<void> loadExpenses() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getexpenses();

      if (!mounted) return;

      setState(() {
        allExpenses = List<dynamic>.from(result);

        filteredExpenses =
            List<dynamic>.from(result);

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e.toString();

        allExpenses = [];

        filteredExpenses = [];
      });

      debugPrint(
        "Expense API Error: $e",
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
          value.toString().toLowerCase() != "null") {
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
        "VehicleNo",
        "VehicleNumber",
        "Vehicle",
        "VehicleName",
      ],
    );
  }

  // =========================================================
  // TYPE
  // =========================================================

  String getExpenseType(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "Type",
        "ExpenseType",
        "ExpenseCategory",
        "Category",
        "MovementType",
      ],
    );
  }

  // =========================================================
  // VENDOR
  // =========================================================

  String getVendor(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "VendorName",
        "Vendor",
        "Vendor_Name",
        "SupplierName",
        "Supplier",
      ],
    );
  }

  // =========================================================
  // AMOUNT
  // =========================================================

  dynamic getAmount(
    Map<String, dynamic> data,
  ) {
    for (final key in [
      "Amount",
      "ExpenseAmount",
      "TotalAmount",
      "amount",
    ]) {
      if (data[key] != null) {
        return data[key];
      }
    }

    return 0;
  }

  // =========================================================
  // INVOICE
  // =========================================================

  String getInvoice(
    Map<String, dynamic> data,
  ) {
    return getValue(
      data,
      [
        "InvoiceNo",
        "InvoiceNumber",
        "Invoice",
        "Invoice_No",
        "BillNo",
        "BillNumber",
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
        "ExpenseStatus",
        "ApprovalStatus",
      ],
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  String getExpenseDate(
    Map<String, dynamic> data,
  ) {
    final value = getValue(
      data,
      [
        "ExpenseDate",
        "Date",
        "CreatedDate",
        "CreatedAt",
        "MovementTime",
      ],
    );

    if (value == "-") {
      return "-";
    }

    return formatExpenseDate(value);
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatExpenseDate(
    dynamic value,
  ) {
    if (value == null) {
      return "-";
    }

    try {
      final date = DateTime
          .parse(
            value.toString(),
          )
          .toLocal();

      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return value.toString();
    }
  }

  // =========================================================
  // FORMAT AMOUNT
  // =========================================================

  String formatAmount(
    dynamic value,
  ) {
    if (value == null) {
      return "₹0";
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return "₹0";
    }

    try {
      final number = double.parse(text);

      if (number == 0) {
        return "₹0";
      }

      return "₹${number.toStringAsFixed(2)}";
    } catch (_) {
      return "₹$text";
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

    final typeSearch =
        typeController.text
            .trim()
            .toLowerCase();

    final vendorSearch =
        vendorController.text
            .trim()
            .toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(
      allExpenses,
    );

    // =======================================================
    // VEHICLE FILTER
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
    // TYPE FILTER
    // =======================================================

    if (typeSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        return getExpenseType(data)
            .toLowerCase()
            .contains(
              typeSearch,
            );
      }).toList();
    }

    // =======================================================
    // VENDOR FILTER
    // =======================================================

    if (vendorSearch.isNotEmpty) {
      result = result.where((item) {
        final data =
            Map<String, dynamic>.from(
          item,
        );

        return getVendor(data)
            .toLowerCase()
            .contains(
              vendorSearch,
            );
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredExpenses = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    vehicleController.clear();

    typeController.clear();

    vendorController.clear();

    if (!mounted) return;

    setState(() {
      filteredExpenses =
          List<dynamic>.from(
        allExpenses,
      );
    });
  }

  // =========================================================
  // SEARCH FIELD
  // =========================================================

  Widget buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return SizedBox(
      width: 270,
      height: 44,
      child: TextField(
        controller: controller,
        textInputAction:
            TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,

          hintStyle:
              const TextStyle(
            color:
                Color(0xff64748b),
            fontSize: 16,
          ),

          filled: true,

          fillColor:
              Colors.white,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(0xffdbe2ea),
            ),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(0xffdbe2ea),
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(0xff2161b5),
              width: 1.2,
            ),
          ),
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
        20,
        20,
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xfff1f4f8),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xffdfe6ee,
          ),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x05000000),
            blurRadius: 5,
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
                  1100;

          if (isSmall) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [

                buildSearchField(
                  controller:
                      vehicleController,
                  hint:
                      "Type to search...",
                ),

                buildSearchField(
                  controller:
                      typeController,
                  hint:
                      "Type to search...",
                ),

                buildSearchField(
                  controller:
                      vendorController,
                  hint:
                      "Search vendor...",
                ),

                buildFilterButton(),

                buildResetButton(),

                buildRecordCount(),
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [

              // =================================================
              // SEARCH 1
              // =================================================

              buildSearchField(
                controller:
                    vehicleController,
                hint:
                    "Type to search...",
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // SEARCH 2
              // =================================================

              buildSearchField(
                controller:
                    typeController,
                hint:
                    "Type to search...",
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // VENDOR
              // =================================================

              buildSearchField(
                controller:
                    vendorController,
                hint:
                    "Search vendor...",
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // FILTER
              // =================================================

              buildFilterButton(),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // RESET
              // =================================================

              buildResetButton(),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // COUNT
              // =================================================

              buildRecordCount(),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // FILTER BUTTON
  // =========================================================

  Widget buildFilterButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed:
            applyFilters,

        style:
            ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor:
              const Color(
            0xff2161b5,
          ),

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
        ),

        child:
            const Text(
          "Filter",

          style:
              TextStyle(
            fontSize: 14,

            fontWeight:
                FontWeight.w700,

            color:
                Colors.white,
          ),
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
            0xff475569,
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

        child:
            const Text(
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
  // RECORD COUNT
  // =========================================================

  Widget buildRecordCount() {
    return Text(
      "${filteredExpenses.length} records",

      style:
          const TextStyle(
        fontSize: 15,

        color:
            Color(0xff8da0b9),

        fontWeight:
            FontWeight.w500,
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget tableHeader(
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
            Color(0xff94a3b8),
      ),
    );
  }

  // =========================================================
  // EXPENSE STATUS
  // =========================================================

  Widget expenseStatusBadge(
    String status,
  ) {
    final normalized =
        status
            .trim()
            .toLowerCase();

    final isApproved =
        normalized == "approved";

    final isRejected =
        normalized == "rejected" ||
        normalized == "cancelled";

    Color backgroundColor;
    Color dotColor;
    Color textColor;

    if (isApproved) {
      backgroundColor =
          const Color(0xffdcfce7);

      dotColor =
          const Color(0xff16a34a);

      textColor =
          const Color(0xff15803d);
    } else if (isRejected) {
      backgroundColor =
          const Color(0xffffe4e6);

      dotColor =
          const Color(0xffe11d48);

      textColor =
          const Color(0xffbe123c);
    } else {
      backgroundColor =
          const Color(0xfffff1c7);

      dotColor =
          const Color(0xfff59e0b);

      textColor =
          const Color(0xffb45309);
    }

    final displayStatus =
        status == "-"
            ? "Approved"
            : status;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            backgroundColor,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 9,
            height: 9,

            decoration:
                BoxDecoration(
              color:
                  dotColor,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            displayStatus,

            style:
                TextStyle(
              fontSize: 13,

              fontWeight:
                  FontWeight.w700,

              color:
                  textColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY TABLE
  // =========================================================

  Widget buildEmptyTable() {
    return Container(
      width: double.infinity,

      height: 300,

      decoration:
          BoxDecoration(
        color:
            const Color(0xfff1f4f8),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xffdfe6ee,
          ),
        ),
      ),

      child:
          Column(
        children: [

          // HEADER
          Container(
            height: 50,

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
                    0xffdfe6ee,
                  ),
                ),
              ),
            ),

            child:
                Row(
              children: [

                _emptyHeader(
                  "DATE",
                  130,
                ),

                _emptyHeader(
                  "VEHICLE",
                  160,
                ),

                _emptyHeader(
                  "TYPE",
                  110,
                ),

                _emptyHeader(
                  "VENDOR",
                  500,
                ),

                _emptyHeader(
                  "AMOUNT",
                  120,
                ),

                _emptyHeader(
                  "INVOICE",
                  250,
                ),

                _emptyHeader(
                  "STATUS",
                  150,
                ),
              ],
            ),
          ),

          // EMPTY TEXT
          const Expanded(
            child:
                Center(
              child:
                  Text(
                "No expense records found",

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

  // =========================================================
  // EMPTY HEADER
  // =========================================================

  Widget _emptyHeader(
    String title,
    double width,
  ) {
    return SizedBox(
      width: width,

      child:
          tableHeader(
        title,
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget buildExpenseTable() {
    // =======================================================
    // LOADING
    // =======================================================

    if (isLoading) {
      return Container(
        width: double.infinity,

        height: 300,

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
              0xffdfe6ee,
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

        height: 300,

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
              0xffdfe6ee,
            ),
          ),
        ),

        child:
            Center(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              const Icon(
                Icons
                    .error_outline,
                size: 48,
                color:
                    Colors.red,
              ),

              const SizedBox(
                height: 12,
              ),

              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 30,
                ),

                child:
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
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed:
                    loadExpenses,

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xff2161b5,
                  ),
                ),

                child:
                    const Text(
                  "Retry",
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // EMPTY
    // =======================================================

    if (filteredExpenses.isEmpty) {
      return buildEmptyTable();
    }

    // =======================================================
    // DATA TABLE
    // =======================================================

    return Container(
      width: double.infinity,

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xfff1f4f8,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xffdfe6ee,
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
              DataTable(
            horizontalMargin:
                18,

            columnSpacing:
                28,

            headingRowHeight:
                50,

            dataRowMinHeight:
                58,

            dataRowMaxHeight:
                72,

            dividerThickness:
                0.7,

            columns: [

              DataColumn(
                label:
                    tableHeader(
                  "DATE",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "VEHICLE",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "TYPE",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "VENDOR",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "AMOUNT",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "INVOICE",
                ),
              ),

              DataColumn(
                label:
                    tableHeader(
                  "STATUS",
                ),
              ),
            ],

            rows:
                filteredExpenses
                    .map<DataRow>(
              (item) {
                final data =
                    Map<String,
                            dynamic>.from(
                  item,
                );

                final date =
                    getExpenseDate(
                  data,
                );

                final vehicle =
                    getVehicle(
                  data,
                );

                final type =
                    getExpenseType(
                  data,
                );

                final vendor =
                    getVendor(
                  data,
                );

                final amount =
                    getAmount(
                  data,
                );

                final invoice =
                    getInvoice(
                  data,
                );

                final status =
                    getStatus(
                  data,
                );

                return DataRow(
                  cells: [

                    // =========================================
                    // DATE
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 120,

                        child:
                            Text(
                          date,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // VEHICLE
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 150,

                        child:
                            Text(
                          vehicle,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight
                                    .w800,

                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // TYPE
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 90,

                        child:
                            Text(
                          type,

                          maxLines: 1,

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
                              0xff475569,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // VENDOR
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 500,

                        child:
                            Text(
                          vendor,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // AMOUNT
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 110,

                        child:
                            Align(
                          alignment:
                              Alignment
                                  .centerRight,

                          child:
                              Text(
                            formatAmount(
                              amount,
                            ),

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 14,

                              fontWeight:
                                  FontWeight
                                      .w500,

                              color:
                                  Color(
                                0xff1e293b,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // INVOICE
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 250,

                        child:
                            Text(
                          invoice,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight
                                    .w500,

                            color:
                                Color(
                              0xff8da0b9,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // STATUS
                    // =========================================

                    DataCell(
                      expenseStatusBadge(
                        status,
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
            20,
            18,
            20,
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              // ===============================================
              // FILTER
              // ===============================================

              buildFilterSection(),

              const SizedBox(
                height: 18,
              ),

              // ===============================================
              // TABLE
              // ===============================================

              buildExpenseTable(),
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

    typeController.dispose();

    vendorController.dispose();

    super.dispose();
  }
}