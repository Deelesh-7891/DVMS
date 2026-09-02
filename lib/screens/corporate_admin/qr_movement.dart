import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class QrMovementScreen extends StatefulWidget {
  const QrMovementScreen({super.key});

  @override
  State<QrMovementScreen> createState() =>
      _QrMovementScreenState();
}

class _QrMovementScreenState
    extends State<QrMovementScreen> {

  // =========================================================
  // AUTH SERVICE
  // =========================================================

  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController searchController =
      TextEditingController();

  final TextEditingController driverController =
      TextEditingController();

  // =========================================================
  // API DATA
  // =========================================================

  List<dynamic> allMovements = [];

  List<dynamic> filteredMovements = [];

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

    loadMovements();

    searchController.addListener(
      applyFilters,
    );

    driverController.addListener(
      applyFilters,
    );
  }

  // =========================================================
  // LOAD API
  // =========================================================

  Future<void> loadMovements() async {
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
        allMovements = result;

        filteredMovements =
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

        allMovements = [];

        filteredMovements = [];
      });

      debugPrint(
        "Movement API Error: $e",
      );
    }
  }

  // =========================================================
  // APPLY FILTER
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        searchController.text
            .trim()
            .toLowerCase();

    final driverSearch =
        driverController.text
            .trim()
            .toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(
      allMovements,
    );

    // =======================================================
    // VEHICLE SEARCH
    // =======================================================

    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {

        final vehicle =
            item["RegistrationNo"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        return vehicle.contains(
          vehicleSearch,
        );

      }).toList();
    }

    // =======================================================
    // DRIVER SEARCH
    // =======================================================

    if (driverSearch.isNotEmpty) {
      result = result.where((item) {

        final driver =
            item["DriverName"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        return driver.contains(
          driverSearch,
        );

      }).toList();
    }

    // =======================================================
    // FROM DATE
    // =======================================================

    if (fromDate != null) {
      result = result.where((item) {

        final date =
            _parseApiDate(
          item["MovementTime"],
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

        final date =
            _parseApiDate(
          item["MovementTime"],
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
      filteredMovements = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {

    searchController.clear();

    driverController.clear();

    setState(() {

      fromDate = null;

      toDate = null;

      filteredMovements =
          List<dynamic>.from(
        allMovements,
      );

    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({
    required bool isFromDate,
  }) async {

    final picked =
        await showDatePicker(
      context: context,

      initialDate:
          isFromDate
              ? fromDate ??
                  DateTime.now()
              : toDate ??
                  DateTime.now(),

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035),
    );

    if (picked == null) {
      return;
    }

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
  // PARSE API DATE
  // =========================================================

  DateTime? _parseApiDate(
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

    } catch (e) {

      return null;
    }
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
  // FORMAT MOVEMENT TIME
  // =========================================================

  String formatMovementTime(
    dynamic value,
  ) {

    if (value == null) {
      return "-";
    }

    try {

      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final hour =
          date.hour == 0
              ? 12
              : date.hour > 12
                  ? date.hour - 12
                  : date.hour;

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final second =
          date.second
              .toString()
              .padLeft(2, '0');

      final amPm =
          date.hour >= 12
              ? "pm"
              : "am";

      return
          "${date.day}/${date.month}/${date.year}, "
          "$hour:$minute:$second $amPm";

    } catch (e) {

      return value.toString();
    }
  }

  // =========================================================
  // FROM LOCATION
  // =========================================================

  String getFromLocation(
    Map<String, dynamic> item,
  ) {

    final location =
        item["FromLocationName"];

    final city =
        item["FromCityName"];

    if (location != null &&
        location
            .toString()
            .trim()
            .isNotEmpty) {

      return location.toString();
    }

    if (city != null &&
        city
            .toString()
            .trim()
            .isNotEmpty) {

      return city.toString();
    }

    return "-";
  }

  // =========================================================
  // TO LOCATION
  // =========================================================

  String getToLocation(
    Map<String, dynamic> item,
  ) {

    final location =
        item["ToLocationName"];

    final city =
        item["ToCityName"];

    if (location != null &&
        location
            .toString()
            .trim()
            .isNotEmpty) {

      return location.toString();
    }

    if (city != null &&
        city
            .toString()
            .trim()
            .isNotEmpty) {

      return city.toString();
    }

    return "-";
  }

  // =========================================================
  // HEADER
  // RESPONSIVE
  // =========================================================

  Widget buildHeader() {

    return LayoutBuilder(
      builder:
          (
        BuildContext context,
        BoxConstraints constraints,
      ) {

        final bool isMobile =
            constraints.maxWidth < 700;

        // =====================================================
        // MOBILE
        // =====================================================

        if (isMobile) {

          return Container(
            width: double.infinity,

            padding:
                const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              12,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // =============================================
                // TITLE
                // =============================================

                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    "QR Movement",
                    maxLines: 1,
                    softWrap: false,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                // =============================================
                // SUBTITLE
                // =============================================

                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    "Gate entry / exit log via QR scan",
                    maxLines: 1,
                    softWrap: false,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xff64748b),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =============================================
                // BUTTONS
                // =============================================

                Wrap(
                  spacing: 8,
                  runSpacing: 8,

                  children: [

                    // =========================================
                    // MANUAL ENTRY
                    // =========================================

                    SizedBox(
                      height: 42,
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          // TODO:
                          // Manual Entry
                        },

                        icon:
                            const Icon(
                          Icons
                              .keyboard_alt_outlined,
                          size: 17,
                        ),

                        label:
                            const Text(
                          "Manual Entry",
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              const Color(
                            0xff334155,
                          ),

                          backgroundColor:
                              Colors.white,

                          side:
                              const BorderSide(
                            color:
                                Color(
                              0xffdbe2ea,
                            ),
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // SCAN QR
                    // =========================================

                    SizedBox(
                      height: 42,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          // TODO:
                          // QR Scanner
                        },

                        icon:
                            const Icon(
                          Icons
                              .qr_code_scanner,
                          size: 18,
                          color:
                              Colors.white,
                        ),

                        label:
                            const Text(
                          "Scan QR",
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),

                        style:
                            ElevatedButton
                                .styleFrom(
                          elevation: 0,

                          backgroundColor:
                              const Color(
                            0xff2161b5,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // DATE
                    // =========================================

                    SizedBox(
                      height: 42,

                      child:
                          Center(
                        child: Text(
                          _todayText(),

                          maxLines: 1,

                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // =====================================================
        // DESKTOP / TABLET
        // =====================================================

        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            15,
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [

              // =================================================
              // TITLE
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: const [

                    Text(
                      "QR Movement",
                      maxLines: 1,
                      softWrap: false,
                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Colors.black,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      "Gate entry / exit log via QR scan",
                      maxLines: 1,
                      softWrap: false,
                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(
                          0xff64748b,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              // =================================================
              // MANUAL ENTRY
              // =================================================

              SizedBox(
                height: 43,

                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    // TODO:
                    // Manual Entry
                  },

                  icon:
                      const Icon(
                    Icons
                        .keyboard_alt_outlined,
                    size: 18,
                  ),

                  label:
                      const Text(
                    "Manual Entry",
                  ),

                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        const Color(
                      0xff334155,
                    ),

                    backgroundColor:
                        Colors.white,

                    side:
                        const BorderSide(
                      color:
                          Color(
                        0xffdbe2ea,
                      ),
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // =================================================
              // SCAN QR
              // =================================================

              SizedBox(
                height: 43,

                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    // TODO:
                    // QR Scanner
                  },

                  icon:
                      const Icon(
                    Icons.qr_code_scanner,
                    size: 18,
                    color:
                        Colors.white,
                  ),

                  label:
                      const Text(
                    "Scan QR",
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),

                  style:
                      ElevatedButton
                          .styleFrom(
                    elevation: 0,

                    backgroundColor:
                        const Color(
                      0xff2161b5,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              // =================================================
              // DATE
              // =================================================

              Flexible(
                child: Text(
                  _todayText(),

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xff1e293b,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // TODAY TEXT
  // =========================================================

  String _todayText() {

    final now =
        DateTime.now();

    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return
        "${weekdays[now.weekday - 1]}, "
        "${now.day} "
        "${months[now.month - 1]} "
        "${now.year}";
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget buildFilterSection() {

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xfff8fafc),

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              const Color(0xffe2e8f0),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x08000000),
            blurRadius: 8,
            offset:
                Offset(0, 2),
          ),
        ],
      ),

      child: Wrap(
        spacing: 12,
        runSpacing: 12,

        crossAxisAlignment:
            WrapCrossAlignment.center,

        children: [

          // ===================================================
          // VEHICLE SEARCH
          // ===================================================

          SizedBox(
            width: 245,
            height: 40,

            child: TextField(
              controller:
                  searchController,

              decoration:
                  InputDecoration(
                hintText:
                    "Type to search...",

                filled: true,

                fillColor:
                    Colors.white,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
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
                        Color(
                      0xffdbe2ea,
                    ),
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
                        Color(
                      0xffdbe2ea,
                    ),
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
                        Color(
                      0xff2161b5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================
          // DRIVER SEARCH
          // ===================================================

          SizedBox(
            width: 245,
            height: 40,

            child: TextField(
              controller:
                  driverController,

              decoration:
                  InputDecoration(
                hintText:
                    "Search driver...",

                filled: true,

                fillColor:
                    Colors.white,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
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
                        Color(
                      0xffdbe2ea,
                    ),
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
                        Color(
                      0xffdbe2ea,
                    ),
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
                        Color(
                      0xff2161b5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================
          // FROM DATE
          // ===================================================

          buildDateBox(
            title:
                formatDate(
              fromDate,
            ),

            onTap: () =>
                selectDate(
              isFromDate: true,
            ),
          ),

          // ===================================================
          // TO DATE
          // ===================================================

          buildDateBox(
            title:
                formatDate(
              toDate,
            ),

            onTap: () =>
                selectDate(
              isFromDate: false,
            ),
          ),

          // ===================================================
          // FILTER
          // ===================================================

          SizedBox(
            height: 40,

            child:
                ElevatedButton(
              onPressed:
                  applyFilters,

              style:
                  ElevatedButton
                      .styleFrom(
                elevation: 0,

                backgroundColor:
                    const Color(
                  0xff2161b5,
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
                  color:
                      Colors.white,

                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          // ===================================================
          // RESET
          // ===================================================

          SizedBox(
            height: 40,

            child:
                OutlinedButton(
              onPressed:
                  resetFilters,

              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    const Color(
                  0xff475569,
                ),

                backgroundColor:
                    Colors.white,

                side:
                    const BorderSide(
                  color:
                      Color(
                    0xffd5dde7,
                  ),
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
              ),
            ),
          ),
        ],
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
        width: 172,
        height: 40,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(10),

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
              child: Text(
                title,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      Color(
                    0xff64748b,
                  ),

                  fontSize: 14,
                ),
              ),
            ),

            const Icon(
              Icons
                  .calendar_today_outlined,

              size: 17,

              color:
                  Color(
                0xff334155,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MOVEMENT TABLE
  // =========================================================

  Widget buildMovementTable() {

    if (isLoading) {

      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(50),

          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // =======================================================
    // ERROR
    // =======================================================

    if (errorMessage != null) {

      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
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
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ElevatedButton(
                onPressed:
                    loadMovements,

                child:
                    const Text(
                  "Retry",
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

    if (filteredMovements.isEmpty) {

      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(50),

          child: Text(
            "No movement records found",

            style:
                TextStyle(
              fontSize: 16,

              color:
                  Color(
                0xff64748b,
              ),
            ),
          ),
        ),
      );
    }

    // =======================================================
    // TABLE
    // =======================================================

    return Container(
      width: double.infinity,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              const Color(
            0xffe2e8f0,
          ),
        ),
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),

        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child:
              DataTable(
            columnSpacing: 28,

            horizontalMargin:
                18,

            headingRowHeight:
                48,

            dataRowMinHeight:
                62,

            dataRowMaxHeight:
                80,

            columns:
                const [

              DataColumn(
                label:
                    TableHeader(
                  "TIME",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "VEHICLE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "FROM",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "TO",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "DIRECTION",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "TYPE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "ODOMETER",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "DRIVER",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "PURPOSE",
                ),
              ),

              DataColumn(
                label:
                    TableHeader(
                  "CUSTOMER",
                ),
              ),
            ],

            rows:
                filteredMovements
                    .map<DataRow>(
              (item) {

                final Map<String,
                        dynamic>
                    data =
                    Map<String,
                        dynamic>.from(
                  item,
                );

                return DataRow(
                  cells: [

                    // =========================================
                    // TIME
                    // =========================================

                    DataCell(
                      Text(
                        formatMovementTime(
                          data[
                              "MovementTime"],
                        ),

                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Color(
                            0xff334155,
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // VEHICLE
                    // =========================================

                    DataCell(
                      Text(
                        data[
                                    "RegistrationNo"]
                                ?.toString() ??
                            "-",

                        style:
                            const TextStyle(
                          fontSize: 14,

                          fontWeight:
                              FontWeight.w800,

                          color:
                              Color(
                            0xff1e293b,
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // FROM
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 190,

                        child: Text(
                          getFromLocation(
                            data,
                          ),

                          maxLines: 2,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight.w700,

                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // TO
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 190,

                        child: Text(
                          getToLocation(
                            data,
                          ),

                          maxLines: 2,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            fontWeight:
                                FontWeight.w700,

                            color:
                                Color(
                              0xff1e293b,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // DIRECTION
                    // =========================================

                    DataCell(
                      directionBadge(
                        data[
                                    "Direction"]
                                ?.toString() ??
                            "-",
                      ),
                    ),

                    // =========================================
                    // TYPE
                    // =========================================

                    DataCell(
                      Text(
                        data[
                                    "MovementType"]
                                ?.toString() ??
                            "-",

                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // =========================================
                    // ODOMETER
                    // =========================================

                    DataCell(
                      Text(
                        "${data["Odometer"] ?? "-"} km",

                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // =========================================
                    // DRIVER
                    // =========================================

                    DataCell(
                      Text(
                        data[
                                    "DriverName"]
                                ?.toString() ??
                            "-",

                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // =========================================
                    // PURPOSE
                    // =========================================

                    DataCell(
                      Text(
                        data[
                                    "Purpose"]
                                ?.toString() ??
                            "-",

                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // =========================================
                    // CUSTOMER
                    // =========================================

                    DataCell(
                      Text(
                        data[
                                    "CustomerName"]
                                ?.toString() ??
                            "-",

                        style:
                            const TextStyle(
                          fontSize: 13,
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
  // DIRECTION BADGE
  // =========================================================

  Widget directionBadge(
    String direction,
  ) {

    final bool isEntry =
        direction
            .toLowerCase() ==
            "entry";

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color: isEntry
            ? const Color(
                0xffdcfce7,
              )
            : const Color(
                0xfffff1c7,
              ),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 8,
            height: 8,

            decoration:
                BoxDecoration(
              color: isEntry
                  ? const Color(
                      0xff16a34a,
                    )
                  : const Color(
                      0xfff59e0b,
                    ),

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            direction,

            style:
                TextStyle(
              fontSize: 13,

              fontWeight:
                  FontWeight.w700,

              color: isEntry
                  ? const Color(
                      0xff15803d,
                    )
                  : const Color(
                      0xffb45309,
                    ),
            ),
          ),
        ],
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
        child: Column(
          children: [

            // =================================================
            // HEADER
            // =================================================

            buildHeader(),

            // =================================================
            // MAIN CONTENT
            // =================================================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  18,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    // =========================================
                    // FILTER
                    // =========================================

                    buildFilterSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================
                    // RECORD COUNT + REFRESH
                    // =========================================

                    Row(
                      children: [

                        Expanded(
                          child: Text(
                            "Movement Records: "
                            "${filteredMovements.length}",

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 14,

                              fontWeight:
                                  FontWeight.w600,

                              color:
                                  Color(
                                0xff475569,
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          tooltip:
                              "Refresh",

                          onPressed:
                              loadMovements,

                          icon:
                              const Icon(
                            Icons.refresh,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // =========================================
                    // TABLE
                    // =========================================

                    buildMovementTable(),
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

    searchController.dispose();

    driverController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class TableHeader
    extends StatelessWidget {

  final String title;

  const TableHeader(
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

      style:
          const TextStyle(
        fontSize: 12,

        fontWeight:
            FontWeight.w700,

        color:
            Color(
          0xff94a3b8,
        ),

        letterSpacing:
            0.4,
      ),
    );
  }
}