import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../security/report_accident_screen.dart';

class AccidentsScreen extends StatefulWidget {
  const AccidentsScreen({super.key});

  @override
  State<AccidentsScreen> createState() => _AccidentsScreenState();
}

class _AccidentsScreenState extends State<AccidentsScreen> {
  final AuthService _authService = AuthService();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController vehicleController =
      TextEditingController();

  final TextEditingController reportedByController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // =========================================================
  // DATA
  // =========================================================

  List<dynamic> allAccidents = [];
  List<dynamic> filteredAccidents = [];

  bool isLoading = false;
  String? errorMessage;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadAccidents();

    vehicleController.addListener(applyFilters);
    reportedByController.addListener(applyFilters);
    descriptionController.addListener(applyFilters);
  }

  // =========================================================
  // LOAD ACCIDENTS
  // =========================================================

  Future<void> loadAccidents() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authService.getaccidents();

      if (!mounted) return;

      setState(() {
        allAccidents = List<dynamic>.from(result);
        filteredAccidents = List<dynamic>.from(result);
        isLoading = false;
      });

      debugPrint("ACCIDENTS API RESPONSE: $result");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        allAccidents = [];
        filteredAccidents = [];
      });

      debugPrint("Accidents API Error: $e");
    }
  }

  // =========================================================
  // OPEN ADD ACCIDENT SCREEN
  // =========================================================

  Future<void> openAddAccident() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportAccidentScreen(),
      ),
    );

    // Add Accident screen se true return hua
    // to accident list refresh hogi.
    if (result == true && mounted) {
      await loadAccidents();
    }
  }

  // =========================================================
  // GET VALUE
  // =========================================================

  String getValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

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

  String getVehicle(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "RegistrationNo",
        "registrationNo",
        "VehicleNo",
        "vehicleNo",
        "VehicleNumber",
        "vehicleNumber",
        "RegistrationNumber",
        "registrationNumber",
        "Vehicle",
        "vehicle",
      ],
    );
  }

  // =========================================================
  // MODEL
  // =========================================================

  String getModel(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "Model",
        "model",
        "VehicleModel",
        "vehicleModel",
        "ModelName",
        "modelName",
      ],
    );
  }

  // =========================================================
  // LOCATION
  // =========================================================

  String getLocation(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "Location",
        "location",
        "LocationName",
        "locationName",
        "AccidentLocation",
        "accidentLocation",
        "City",
        "city",
      ],
    );
  }

  // =========================================================
  // REPORTED BY
  // =========================================================

  String getReportedBy(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "ReportedBy",
        "reportedBy",
        "ReportedByName",
        "reportedByName",
        "CreatedByName",
        "createdByName",
        "UserName",
        "username",
        "CreatedBy",
        "createdBy",
      ],
    );
  }

  // =========================================================
  // DESCRIPTION
  // =========================================================

  String getDescription(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "Description",
        "description",
        "AccidentDescription",
        "accidentDescription",
        "Remarks",
        "remarks",
        "Details",
        "details",
      ],
    );
  }

  // =========================================================
  // PHOTO
  // =========================================================

  String getPhoto(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "Photo",
        "photo",
        "PhotoUrl",
        "photoUrl",
        "Image",
        "image",
        "ImageUrl",
        "imageUrl",
        "PhotoPath",
        "photoPath",
      ],
    );
  }

  // =========================================================
  // CAPTURED DATE
  // =========================================================

  String getCaptured(Map<String, dynamic> item) {
    return getValue(
      item,
      [
        "Captured",
        "captured",
        "CapturedAt",
        "capturedAt",
        "CapturedDate",
        "capturedDate",
        "AccidentDate",
        "accidentDate",
        "CreatedAt",
        "createdAt",
        "Date",
        "date",
      ],
    );
  }

  // =========================================================
  // FORMAT CAPTURED DATE
  // =========================================================

  String formatCaptured(dynamic value) {
    if (value == null) {
      return "-";
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") {
      return "-";
    }

    try {
      final date = DateTime.parse(text).toLocal();

      int hour = date.hour;

      final minute =
          date.minute.toString().padLeft(2, '0');

      final second =
          date.second.toString().padLeft(2, '0');

      final amPm = hour >= 12 ? "pm" : "am";

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return "${date.day}/${date.month}/${date.year}, "
          "$hour:$minute:$second $amPm";
    } catch (_) {
      return text;
    }
  }

  // =========================================================
  // FILTER
  // =========================================================

  void applyFilters() {
    final vehicleSearch =
        vehicleController.text.trim().toLowerCase();

    final reportedBySearch =
        reportedByController.text.trim().toLowerCase();

    final descriptionSearch =
        descriptionController.text.trim().toLowerCase();

    List<dynamic> result =
        List<dynamic>.from(allAccidents);

    // VEHICLE
    if (vehicleSearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        return getVehicle(data)
            .toLowerCase()
            .contains(vehicleSearch);
      }).toList();
    }

    // REPORTED BY
    if (reportedBySearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        return getReportedBy(data)
            .toLowerCase()
            .contains(reportedBySearch);
      }).toList();
    }

    // DESCRIPTION
    if (descriptionSearch.isNotEmpty) {
      result = result.where((item) {
        if (item is! Map) return false;

        final data =
            Map<String, dynamic>.from(item);

        return getDescription(data)
            .toLowerCase()
            .contains(descriptionSearch);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredAccidents = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetFilters() {
    vehicleController.clear();
    reportedByController.clear();
    descriptionController.clear();

    setState(() {
      filteredAccidents =
          List<dynamic>.from(allAccidents);
    });
  }

  // =========================================================
  // TODAY TEXT
  // =========================================================

  String todayText() {
    final now = DateTime.now();

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

    return "${weekdays[now.weekday - 1]}, "
        "${now.day} "
        "${months[now.month - 1]} "
        "${now.year}";
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Small mobile: stack title, button and date/profile.
        if (width < 400) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Accidents",
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openAddAccident,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Add Accidents",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2161b5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todayText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1e293b),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xff2161b5),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "SY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Mobile / tablet.
        if (width < 700) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Accidents",
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: openAddAccident,
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text(
                          "Add Accidents",
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2161b5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Accident records and incident monitoring",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xff64748b),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        todayText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1e293b),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xff2161b5),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "SY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Desktop.
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Accidents",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Accident records and incident monitoring",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xff64748b),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: openAddAccident,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  "Add Accidents",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2161b5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  todayText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1e293b),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xff2161b5),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  "SY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = width < 600;
        final fieldWidth = mobile
            ? (width - 24).clamp(0.0, 1000.0)
            : 270.0;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 22,
          ),
          padding: EdgeInsets.all(mobile ? 12 : 20),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffe2e8f0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: vehicleController,
                        decoration: inputDecoration(
                          "Search Vehicle...",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: reportedByController,
                        decoration: inputDecoration(
                          "Search Reported By...",
                          suffixIcon: const Icon(
                            Icons.mic,
                            size: 21,
                            color: Color(0xff111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: descriptionController,
                        decoration: inputDecoration(
                          "Search Description...",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: resetFilters,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xff475569),
                            side: const BorderSide(
                              color: Color(0xffdbe2ea),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      height: 44,
                      child: TextField(
                        controller: vehicleController,
                        decoration: inputDecoration(
                          "Type to search...",
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      height: 44,
                      child: TextField(
                        controller: reportedByController,
                        decoration: inputDecoration(
                          "Type to search...",
                          suffixIcon: const Icon(
                            Icons.mic,
                            size: 21,
                            color: Color(0xff111827),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      height: 44,
                      child: TextField(
                        controller: descriptionController,
                        decoration: inputDecoration(
                          "Type to search...",
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: resetFilters,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff475569),
                          side: const BorderSide(
                            color: Color(0xffdbe2ea),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Reset",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
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

  InputDecoration inputDecoration(
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color: Color(0xff8b8f96),
        fontSize: 14,
      ),

      suffixIcon:
          suffixIcon,

      filled: true,

      fillColor:
          Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
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
        ),
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget buildAccidentTable() {

    // =======================================================
    // LOADING
    // =======================================================

    if (isLoading) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(60),

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
              const EdgeInsets.all(40),

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
                height: 12,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ElevatedButton(
                onPressed:
                    loadAccidents,

                child:
                    const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // EMPTY
    // =======================================================

    if (filteredAccidents.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(60),

          child: Text(
            "No accident records found",

            style: TextStyle(
              fontSize: 16,
              color:
                  Color(0xff64748b),
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

      margin:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(
                  0xffe2e8f0),
        ),
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),

        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child: DataTable(
            horizontalMargin: 18,

            columnSpacing: 55,

            headingRowHeight: 48,

            dataRowMinHeight: 58,

            dataRowMaxHeight: 82,

            dividerThickness: 0.7,

            columns: const [

              DataColumn(
                label:
                    AccidentHeader(
                  "CAPTURED",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "VEHICLE",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "MODEL",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "LOCATION",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "REPORTED BY",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "DESCRIPTION",
                ),
              ),

              DataColumn(
                label:
                    AccidentHeader(
                  "PHOTO",
                ),
              ),
            ],

            rows:
                filteredAccidents
                    .map<DataRow>(
              (item) {

                final data =
                    Map<String, dynamic>
                        .from(item);

                final captured =
                    getCaptured(data);

                final vehicle =
                    getVehicle(data);

                final model =
                    getModel(data);

                final location =
                    getLocation(data);

                final reportedBy =
                    getReportedBy(data);

                final description =
                    getDescription(data);

                final photo =
                    getPhoto(data);

                return DataRow(
                  cells: [

                    // =========================================
                    // CAPTURED
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 175,

                        child: Text(
                          formatCaptured(
                            captured,
                          ),

                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // VEHICLE
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 110,

                        child: Text(
                          vehicle,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // MODEL
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 120,

                        child: Text(
                          model,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // LOCATION
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 130,

                        child: Text(
                          location,

                          maxLines: 2,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // REPORTED BY
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 165,

                        child: Text(
                          reportedBy,

                          maxLines: 2,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // DESCRIPTION
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 390,

                        child: Text(
                          description,

                          maxLines: 2,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                Color(
                                    0xff111827),
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // PHOTO
                    // =========================================

                    DataCell(
                      buildPhoto(photo),
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
  // PHOTO
  // =========================================================

  Widget buildPhoto(String photo) {

    if (photo == "-" ||
        photo.trim().isEmpty) {
      return const Text(
        "—",

        style: TextStyle(
          color:
              Color(0xff94a3b8),
          fontSize: 16,
        ),
      );
    }

    return InkWell(
      onTap: () {

        showDialog(
          context: context,

          builder: (_) {

            return Dialog(
              child:
                  InteractiveViewer(
                child:
                    Image.network(
                  photo,

                  fit:
                      BoxFit.contain,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {

                    return const SizedBox(
                      width: 350,
                      height: 250,

                      child: Center(
                        child: Text(
                          "Unable to load image",
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(6),

        child: Image.network(
          photo,

          width: 45,
          height: 45,

          fit:
              BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {

            return const Text(
              "—",

              style: TextStyle(
                color:
                    Color(0xff94a3b8),
              ),
            );
          },
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
          const Color(0xfff1f5f9),

      body: SafeArea(
        child: Column(
          children: [

            // =================================================
            // HEADER
            // =================================================

            buildHeader(),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child:
                  SingleChildScrollView(

                padding:
                    const EdgeInsets.only(
                  top: 8,
                  bottom: 30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // =================================================
                    // FILTER
                    // =================================================

                    buildFilterSection(),

                    const SizedBox(
                      height: 20,
                    ),

                    // =================================================
                    // RECORD COUNT
                    // =================================================

                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 22,
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child: Text(
                              "Accident Records: "
                              "${filteredAccidents.length}",

                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(
                                        0xff64748b),
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip:
                                "Refresh",

                            onPressed:
                                loadAccidents,

                            icon:
                                const Icon(
                              Icons.refresh,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    // =================================================
                    // TABLE
                    // =================================================

                    buildAccidentTable(),
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

    vehicleController.dispose();

    reportedByController.dispose();

    descriptionController.dispose();

    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class AccidentHeader
    extends StatelessWidget {

  final String title;

  const AccidentHeader(
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
            Color(0xff94a3b8),
        letterSpacing: 0.4,
      ),
    );
  }
}