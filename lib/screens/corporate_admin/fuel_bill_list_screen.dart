import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/photo_thumbnail.dart';
import '../../core/widgets/voice_search_button.dart';
import '../../services/auth_service.dart';

class FuelBillListScreen extends StatefulWidget {
  const FuelBillListScreen({super.key});

  @override
  State<FuelBillListScreen> createState() => _FuelBillListScreenState();
}

class _FuelBillListScreenState extends State<FuelBillListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  String selectedFuel = "All fuels";

  List<Map<String, dynamic>> allFuelBills = [];
  List<Map<String, dynamic>> filteredFuelBills = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFuelBills();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFuelBills() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _authService.getFuelBills();

      setState(() {
        allFuelBills = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredFuelBills = List.from(allFuelBills);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = "Unable to load fuel bills: $e";
      });
    }
  }

  // Field mapping — GET /fuel returns FuelTransaction.* plus RegistrationNo,
  // FuelType (joined from the vehicle) and PhotoPath (joined from the
  // AttachmentMaster row the bill photo was uploaded as).
  String _billNo(Map<String, dynamic> b) => "FB-${b["FuelId"] ?? "-"}";
  String _vehicleNo(Map<String, dynamic> b) =>
      (b["RegistrationNo"] ?? "-").toString();
  String _date(Map<String, dynamic> b) {
    final raw = b["TxnDate"];
    if (raw == null) return "-";
    try {
      return DateFormat("dd-MM-yyyy").format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  String _fuel(Map<String, dynamic> b) => (b["FuelType"] ?? "-").toString();
  String _litres(Map<String, dynamic> b) =>
      b["Quantity"] == null ? "-" : "${b["Quantity"]} L";
  String _amount(Map<String, dynamic> b) =>
      b["Amount"] == null ? "-" : "₹${b["Amount"]}";
  String _vendor(Map<String, dynamic> b) =>
      (b["FuelStation"] ?? "-").toString();
  String? _photoPath(Map<String, dynamic> b) => b["PhotoPath"]?.toString();

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredFuelBills = allFuelBills.where((bill) {
        final matchesSearch =
            _billNo(bill).toLowerCase().contains(search) ||
            _vehicleNo(bill).toLowerCase().contains(search);

        final matchesFuel =
            selectedFuel == "All fuels" || _fuel(bill) == selectedFuel;

        return matchesSearch && matchesFuel;
      }).toList();
    });
  }

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedFuel = "All fuels";
      filteredFuelBills = List.from(allFuelBills);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        title: const Text(
          "Fuel Bills",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadFuelBills,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadFuelBills,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F4F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffDCE3EC)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = width < 700;

                              if (isSmall) {
                                return Column(
                                  children: [
                                    searchBox(),
                                    const SizedBox(height: 10),
                                    fuelDropdown(),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: filterButton()),
                                        const SizedBox(width: 10),
                                        Expanded(child: resetButton()),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  SizedBox(width: 260, child: searchBox()),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 160, child: fuelDropdown()),
                                  const SizedBox(width: 12),
                                  filterButton(),
                                  const SizedBox(width: 12),
                                  resetButton(),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xffDCE3EC)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: filteredFuelBills.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text(
                                          "No fuel bills found",
                                          style:
                                              TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowHeight: 48,
                                    dataRowMinHeight: 66,
                                    dataRowMaxHeight: 66,
                                    columnSpacing: 30,
                                    headingRowColor: WidgetStateProperty.all(
                                      const Color(0xffF8FAFD),
                                    ),
                                    columns: const [
                                      DataColumn(label: Text("BILL NO")),
                                      DataColumn(label: Text("VEHICLE NO")),
                                      DataColumn(label: Text("DATE")),
                                      DataColumn(label: Text("FUEL")),
                                      DataColumn(label: Text("LITRES")),
                                      DataColumn(label: Text("AMOUNT")),
                                      DataColumn(label: Text("VENDOR")),
                                      DataColumn(label: Text("PHOTO")),
                                      DataColumn(label: Text("VIEW")),
                                    ],
                                    rows: filteredFuelBills.map((bill) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              _billNo(bill),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _vehicleNo(bill),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(_date(bill))),
                                          DataCell(Text(_fuel(bill))),
                                          DataCell(Text(_litres(bill))),
                                          DataCell(
                                            Text(
                                              _amount(bill),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(_vendor(bill))),
                                          DataCell(
                                            PhotoThumbnail(
                                              photoPath: _photoPath(bill),
                                            ),
                                          ),
                                          DataCell(
                                            outlineButton(
                                              "View",
                                              icon: Icons.visibility,
                                              onPressed: () => viewBill(bill),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${filteredFuelBills.length} fuel bills found",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget searchBox() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search bill / vehicle no...",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: VoiceSearchButton(
          onResult: (digits) {
            searchController.text = digits;
            applyFilter();
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),
    );
  }

  Widget fuelDropdown() {
    final fuels = [
      "All fuels",
      ...allFuelBills.map((e) => _fuel(e)).toSet(),
    ];

    return DropdownButtonFormField<String>(
      value: fuels.contains(selectedFuel) ? selectedFuel : "All fuels",
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),
      items: fuels.map((fuel) {
        return DropdownMenuItem<String>(value: fuel, child: Text(fuel));
      }).toList(),
      onChanged: (value) => setState(() => selectedFuel = value!),
    );
  }

  Widget filterButton() {
    return ElevatedButton(
      onPressed: applyFilter,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget resetButton() {
    return OutlinedButton(
      onPressed: resetFilter,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff475569),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: const BorderSide(color: Color(0xffDCE3EC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget outlineButton(
    String text, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff334155),
        side: const BorderSide(color: Color(0xffDCE3EC)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void viewBill(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Fuel Bill ${_billNo(bill)}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vehicle: ${_vehicleNo(bill)}"),
              const SizedBox(height: 8),
              Text("Date: ${_date(bill)}"),
              const SizedBox(height: 8),
              Text("Fuel: ${_fuel(bill)}"),
              const SizedBox(height: 8),
              Text("Litres: ${_litres(bill)}"),
              const SizedBox(height: 8),
              Text("Amount: ${_amount(bill)}"),
              const SizedBox(height: 8),
              Text("Vendor: ${_vendor(bill)}"),
              const SizedBox(height: 12),
              PhotoThumbnail(photoPath: _photoPath(bill), size: 120),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
