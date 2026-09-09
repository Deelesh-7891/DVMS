import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MileageScreen extends StatefulWidget {
  const MileageScreen({super.key});

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController searchController =
      TextEditingController();

  List<dynamic> allMileage = [];
  List<dynamic> filteredMileage = [];

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadMileage();

    searchController.addListener(
      applySearch,
    );
  }

  // =========================================================
  // LOAD API
  // =========================================================

  Future<void> loadMileage() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await _authService.getmileagevariance();

      if (!mounted) return;

      setState(() {
        allMileage =
            List<dynamic>.from(result);

        filteredMileage =
            List<dynamic>.from(result);

        isLoading = false;
      });

      debugPrint(
        "MILEAGE RESPONSE: $result",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();

        allMileage = [];
        filteredMileage = [];
      });

      debugPrint(
        "Mileage API Error: $e",
      );
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
          value.toString().toLowerCase() !=
              "null") {
        return value.toString();
      }
    }

    return "-";
  }

  // =========================================================
  // MODEL
  // =========================================================

  String getModel(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Model",
        "model",
        "ModelName",
        "modelName",
        "VehicleModel",
        "vehicleModel",
        "VehicleModelName",
        "vehicleModelName",
      ],
    );
  }

  // =========================================================
  // FUEL
  // =========================================================

  String getFuel(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Fuel",
        "fuel",
        "FuelType",
        "fuelType",
        "FuelName",
        "fuelName",
      ],
    );
  }

  // =========================================================
  // BENCHMARK
  // =========================================================

  String getBenchmark(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Benchmark",
        "benchmark",
        "BenchmarkKmL",
        "benchmarkKmL",
        "BenchmarkKmpl",
        "benchmarkKmpl",
        "ExpectedMileage",
        "expectedMileage",
        "ExpectedKmL",
        "expectedKmL",
        "MileageBenchmark",
        "mileageBenchmark",
      ],
    );
  }

  // =========================================================
  // TOLERANCE
  // =========================================================

  String getTolerance(
    Map<String, dynamic> item,
  ) {
    return getValue(
      item,
      [
        "Tolerance",
        "tolerance",
        "TolerancePercent",
        "tolerancePercent",
        "TolerancePercentage",
        "tolerancePercentage",
      ],
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void applySearch() {
    final search =
        searchController.text
            .trim()
            .toLowerCase();

    if (search.isEmpty) {
      setState(() {
        filteredMileage =
            List<dynamic>.from(
          allMileage,
        );
      });

      return;
    }

    final result =
        allMileage.where((item) {
      if (item is! Map) {
        return false;
      }

      final data =
          Map<String, dynamic>.from(
        item,
      );

      final model =
          getModel(data).toLowerCase();

      final fuel =
          getFuel(data).toLowerCase();

      return model.contains(search) ||
          fuel.contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredMileage = result;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void resetSearch() {
    searchController.clear();

    setState(() {
      filteredMileage =
          List<dynamic>.from(
        allMileage,
      );
    });
  }

  // =========================================================
  // SET BENCHMARK DIALOG
  // =========================================================

  void showBenchmarkDialog(
    Map<String, dynamic> item,
  ) {
    final model =
        getModel(item);

    final fuel =
        getFuel(item);

    final benchmarkController =
        TextEditingController(
      text:
          getBenchmark(item) == "-"
              ? ""
              : getBenchmark(item),
    );

    final toleranceController =
        TextEditingController(
      text:
          getTolerance(item) == "-"
              ? ""
              : getTolerance(item),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: const Text(
            "Set Mileage Benchmark",
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  fuel,
                  style:
                      const TextStyle(
                    color:
                        Color(0xff64748b),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                TextField(
                  controller:
                      benchmarkController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        "Benchmark (KM/L)",
                    hintText:
                        "e.g. 22.3",
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      toleranceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        "Tolerance %",
                    hintText:
                        "e.g. 10",
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                final benchmark =
                    benchmarkController
                        .text
                        .trim();

                final tolerance =
                    toleranceController
                        .text
                        .trim();

                if (benchmark.isEmpty ||
                    tolerance.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter benchmark and tolerance",
                      ),
                    ),
                  );

                  return;
                }

                // ------------------------------------------------
                // IMPORTANT:
                // Yaha actual API call add karni hogi.
                // Abhi UI/local update kiya ja raha hai.
                // ------------------------------------------------

                setState(() {
                  final index =
                      allMileage.indexOf(
                    item,
                  );

                  if (index >= 0) {
                    final updated =
                        Map<String, dynamic>.from(
                      allMileage[index],
                    );

                    updated["Benchmark"] =
                        benchmark;

                    updated["Tolerance"] =
                        tolerance;

                    allMileage[index] =
                        updated;

                    applySearch();
                  }
                });

                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Benchmark updated",
                    ),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xff2161b5,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
              ),
              child:
                  const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        12,
      ),
      child: LayoutBuilder(
        builder:
            (
          context,
          constraints,
        ) {
          final isMobile =
              constraints.maxWidth < 700;

          if (isMobile) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mileage",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xff111827),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  "Model benchmarks & fuel-efficiency variance",
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        Color(0xff64748b),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                buildHeaderButtons(),
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mileage",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Model benchmarks & fuel-efficiency variance",
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            Color(0xff64748b),
                      ),
                    ),
                  ],
                ),
              ),

              buildHeaderButtons(),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER BUTTONS
  // =========================================================

  Widget buildHeaderButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment:
          WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  "Excel export can be connected here",
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.download_outlined,
            size: 18,
          ),
          label:
              const Text("Excel"),
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(
              0xff475569,
            ),
            backgroundColor:
                Colors.white,
            side: const BorderSide(
              color:
                  Color(0xffdbe2ea),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
          ),
        ),

        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  "PDF export can be connected here",
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.download_outlined,
            size: 18,
          ),
          label:
              const Text("PDF"),
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(
              0xff475569,
            ),
            backgroundColor:
                Colors.white,
            side: const BorderSide(
              color:
                  Color(0xffdbe2ea),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
          ),
        ),

        Text(
          _todayText(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xff1e293b),
          ),
        ),

        Container(
          width: 46,
          height: 46,
          alignment:
              Alignment.center,
          decoration:
              const BoxDecoration(
            color:
                Color(0xff2161b5),
            shape:
                BoxShape.circle,
          ),
          child: const Text(
            "SY",
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TODAY
  // =========================================================

  String _todayText() {
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
  // SEARCH SECTION
  // =========================================================

  Widget buildSearchSection() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xfff8fafc,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xffe2e8f0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 280,
            height: 42,
            child: TextField(
              controller:
                  searchController,
              decoration:
                  InputDecoration(
                hintText:
                    "Search model or fuel...",
                prefixIcon:
                    const Icon(
                  Icons.search,
                  size: 19,
                ),
                filled: true,
                fillColor:
                    Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
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
                  ),
                ),
              ),
            ),
          ),

          OutlinedButton(
            onPressed: resetSearch,
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(
                0xff475569,
              ),
              backgroundColor:
                  Colors.white,
              side: const BorderSide(
                color:
                    Color(0xffdbe2ea),
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
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
                const Text("Reset"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BENCHMARK CARD
  // =========================================================

  Widget buildBenchmarkCard() {
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
                  color: Colors.red,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ElevatedButton(
                onPressed:
                    loadMileage,
                child:
                    const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredMileage.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(50),
          child: Text(
            "No mileage records found",
            style: TextStyle(
              fontSize: 16,
              color:
                  Color(0xff64748b),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xffe2e8f0),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          8,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Model Benchmarks",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xff111827),
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            const Text(
              "Expected km/L per model with tolerance — vehicles below benchmark − tolerance are flagged in the variance report",
              style: TextStyle(
                fontSize: 14,
                color:
                    Color(0xff94a3b8),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child: DataTable(
                columnSpacing: 55,
                horizontalMargin: 0,
                headingRowHeight: 45,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 76,
                dividerThickness: 0.7,

                columns: const [
                  DataColumn(
                    label: MileageHeader(
                      "MODEL",
                    ),
                  ),
                  DataColumn(
                    label: MileageHeader(
                      "FUEL",
                    ),
                  ),
                  DataColumn(
                    label: MileageHeader(
                      "BENCHMARK (KM/L)",
                    ),
                  ),
                  DataColumn(
                    label: MileageHeader(
                      "TOLERANCE %",
                    ),
                  ),
                  DataColumn(
                    label: MileageHeader(
                      "ACTION",
                    ),
                  ),
                ],

                rows:
                    filteredMileage
                        .map<DataRow>(
                  (item) {
                    final data =
                        Map<String,
                            dynamic>.from(
                      item,
                    );

                    final model =
                        getModel(data);

                    final fuel =
                        getFuel(data);

                    final benchmark =
                        getBenchmark(data);

                    final tolerance =
                        getTolerance(data);

                    final benchmarkSet =
                        benchmark != "-" &&
                            benchmark
                                .trim()
                                .isNotEmpty;

                    return DataRow(
                      cells: [
                        // MODEL
                        DataCell(
                          SizedBox(
                            width: 300,
                            child: Text(
                              model,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xff111827),
                              ),
                            ),
                          ),
                        ),

                        // FUEL
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Text(
                              fuel,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                color:
                                    Color(0xff111827),
                              ),
                            ),
                          ),
                        ),

                        // BENCHMARK
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Align(
                              alignment:
                                  Alignment.centerRight,
                              child: Text(
                                benchmarkSet
                                    ? benchmark
                                    : "not set",
                                style:
                                    TextStyle(
                                  fontSize: 14,
                                  color: benchmarkSet
                                      ? const Color(
                                          0xff111827,
                                        )
                                      : const Color(
                                          0xff94a3b8,
                                        ),
                                  fontWeight:
                                      benchmarkSet
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // TOLERANCE
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Align(
                              alignment:
                                  Alignment.centerRight,
                              child: Text(
                                tolerance == "-"
                                    ? "—"
                                    : "$tolerance%",
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  color:
                                      Color(0xff111827),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ACTION
                        DataCell(
                          OutlinedButton(
                            onPressed: () {
                              showBenchmarkDialog(
                                data,
                              );
                            },
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
                                    Color(0xffdbe2ea),
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 17,
                                vertical: 10,
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
                              "Set",
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w600,
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
          ],
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
            buildHeader(),

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  25,
                ),
                child: Column(
                  children: [
                    buildSearchSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Mileage Records: "
                            "${filteredMileage.length}",
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xff64748b),
                            ),
                          ),
                        ),

                        IconButton(
                          tooltip:
                              "Refresh",
                          onPressed:
                              loadMileage,
                          icon:
                              const Icon(
                            Icons.refresh,
                          ),
                        ),
                      ],
                    ),

                    buildBenchmarkCard(),
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
    super.dispose();
  }
}

// =============================================================
// TABLE HEADER
// =============================================================

class MileageHeader
    extends StatelessWidget {
  final String title;

  const MileageHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
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