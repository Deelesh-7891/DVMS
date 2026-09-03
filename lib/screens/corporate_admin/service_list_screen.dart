import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/photo_thumbnail.dart';
import '../../services/auth_service.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  String selectedServiceType = "All services";
  String selectedStatus = "All statuses";

  List<Map<String, dynamic>> allServices = [];
  List<Map<String, dynamic>> filteredServices = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // dvms.js has no dedicated "service" table — this reads the generic
  // vehicle-expense ledger (GET /expenses, backed by dbo.DemoExpense) and
  // shows it as the Service list, same as the app's "Upload Bill" flow
  // writes into it.
  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _authService.getExpenses();

      setState(() {
        allServices = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredServices = List.from(allServices);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = "Unable to load service records: $e";
      });
    }
  }

  String _serviceId(Map<String, dynamic> s) => "SRV-${s["ExpenseId"] ?? "-"}";
  String _vehicleNo(Map<String, dynamic> s) =>
      (s["RegistrationNo"] ?? "-").toString();
  String _date(Map<String, dynamic> s) {
    final raw = s["ExpenseDate"];
    if (raw == null) return "-";
    try {
      return DateFormat("dd-MM-yyyy").format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  String _serviceType(Map<String, dynamic> s) =>
      (s["TypeName"] ?? "-").toString();
  String _invoiceNo(Map<String, dynamic> s) =>
      (s["InvoiceNumber"] ?? "-").toString();
  String _serviceCenter(Map<String, dynamic> s) =>
      (s["Vendor"] ?? "-").toString();
  String _amount(Map<String, dynamic> s) =>
      s["Amount"] == null ? "-" : "₹${s["Amount"]}";
  String _status(Map<String, dynamic> s) =>
      (s["ApprovalStatus"] ?? "Pending").toString();
  String? _photoPath(Map<String, dynamic> s) => s["PhotoPath"]?.toString();

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredServices = allServices.where((service) {
        final matchesSearch =
            _serviceId(service).toLowerCase().contains(search) ||
            _vehicleNo(service).toLowerCase().contains(search);

        final matchesServiceType = selectedServiceType == "All services" ||
            _serviceType(service) == selectedServiceType;

        final matchesStatus = selectedStatus == "All statuses" ||
            _status(service) == selectedStatus;

        return matchesSearch && matchesServiceType && matchesStatus;
      }).toList();
    });
  }

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedServiceType = "All services";
      selectedStatus = "All statuses";
      filteredServices = List.from(allServices);
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
          "Service Records",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadServices,
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
                            onPressed: _loadServices,
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
                                    serviceTypeDropdown(),
                                    const SizedBox(height: 10),
                                    statusDropdown(),
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
                                  SizedBox(
                                      width: 180,
                                      child: serviceTypeDropdown()),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 160, child: statusDropdown()),
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
                              child: filteredServices.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text(
                                          "No service records found",
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
                                      DataColumn(label: Text("SERVICE ID")),
                                      DataColumn(label: Text("VEHICLE NO")),
                                      DataColumn(label: Text("DATE")),
                                      DataColumn(label: Text("TYPE")),
                                      DataColumn(label: Text("INVOICE NO")),
                                      DataColumn(label: Text("VENDOR")),
                                      DataColumn(label: Text("AMOUNT")),
                                      DataColumn(label: Text("STATUS")),
                                      DataColumn(label: Text("PHOTO")),
                                      DataColumn(label: Text("VIEW")),
                                    ],
                                    rows: filteredServices.map((service) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              _serviceId(service),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _vehicleNo(service),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(_date(service))),
                                          DataCell(
                                              Text(_serviceType(service))),
                                          DataCell(
                                              Text(_invoiceNo(service))),
                                          DataCell(
                                              Text(_serviceCenter(service))),
                                          DataCell(
                                            Text(
                                              _amount(service),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                              statusBadge(_status(service))),
                                          DataCell(
                                            PhotoThumbnail(
                                              photoPath: _photoPath(service),
                                            ),
                                          ),
                                          DataCell(
                                            outlineButton(
                                              "View",
                                              icon: Icons.visibility,
                                              onPressed: () =>
                                                  viewService(service),
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
                            "${filteredServices.length} service records found",
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
        hintText: "Search service / vehicle no...",
        prefixIcon: const Icon(Icons.search, size: 20),
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

  Widget serviceTypeDropdown() {
    final types = [
      "All services",
      ...allServices.map((e) => _serviceType(e)).toSet(),
    ];

    return DropdownButtonFormField<String>(
      value:
          types.contains(selectedServiceType) ? selectedServiceType : "All services",
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),
      items: types.map((type) {
        return DropdownMenuItem<String>(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) => setState(() => selectedServiceType = value!),
    );
  }

  Widget statusDropdown() {
    final statuses = [
      "All statuses",
      ...allServices.map((e) => _status(e)).toSet(),
    ];

    return DropdownButtonFormField<String>(
      value:
          statuses.contains(selectedStatus) ? selectedStatus : "All statuses",
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffDCE3EC)),
        ),
      ),
      items: statuses.map((status) {
        return DropdownMenuItem<String>(value: status, child: Text(status));
      }).toList(),
      onChanged: (value) => setState(() => selectedStatus = value!),
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
      child:
          const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold)),
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
      child:
          const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget statusBadge(String status) {
    Color background;
    Color textColor;

    if (status == "Approved" || status == "Completed") {
      background = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else if (status == "Pending") {
      background = const Color(0xffFEF3C7);
      textColor = const Color(0xffD97706);
    } else {
      background = const Color(0xffFEE2E2);
      textColor = const Color(0xffDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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

  void viewService(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_serviceId(service)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vehicle: ${_vehicleNo(service)}"),
              const SizedBox(height: 8),
              Text("Date: ${_date(service)}"),
              const SizedBox(height: 8),
              Text("Type: ${_serviceType(service)}"),
              const SizedBox(height: 8),
              Text("Invoice No: ${_invoiceNo(service)}"),
              const SizedBox(height: 8),
              Text("Vendor: ${_serviceCenter(service)}"),
              const SizedBox(height: 8),
              Text("Amount: ${_amount(service)}"),
              const SizedBox(height: 8),
              Text("Status: ${_status(service)}"),
              const SizedBox(height: 12),
              PhotoThumbnail(photoPath: _photoPath(service), size: 120),
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
