import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/photo_thumbnail.dart';
import '../../core/widgets/voice_search_button.dart';
import '../../services/auth_service.dart';

class InsuranceListScreen extends StatefulWidget {
  const InsuranceListScreen({super.key});

  @override
  State<InsuranceListScreen> createState() => _InsuranceListScreenState();
}

class _InsuranceListScreenState extends State<InsuranceListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All statuses";

  List<Map<String, dynamic>> allInsurance = [];
  List<Map<String, dynamic>> filteredInsurance = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInsurance();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInsurance() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _authService.getInsurance();

      setState(() {
        allInsurance = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredInsurance = List.from(allInsurance);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = "Unable to load insurance: $e";
      });
    }
  }

  // GET /insurance computes InsuranceState (Active/ExpiringSoon/Expired)
  // server-side from ExpiryDate, rather than relying on a stored status the
  // client could get out of sync with — used directly here.
  String _policyNo(Map<String, dynamic> i) =>
      (i["PolicyNumber"] ?? "-").toString();
  String _vehicleNo(Map<String, dynamic> i) =>
      (i["RegistrationNo"] ?? "-").toString();
  String _company(Map<String, dynamic> i) =>
      (i["InsuranceCompany"] ?? "-").toString();
  String _date(dynamic raw) {
    if (raw == null) return "-";
    try {
      return DateFormat("dd-MM-yyyy").format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  String _premium(Map<String, dynamic> i) =>
      i["Premium"] == null ? "-" : "₹${i["Premium"]}";
  String _status(Map<String, dynamic> i) =>
      (i["InsuranceState"] ?? "-").toString();
  String? _photoPath(Map<String, dynamic> i) => i["PhotoPath"]?.toString();

  void applyFilter() {
    final search = searchController.text.trim().toLowerCase();

    setState(() {
      filteredInsurance = allInsurance.where((insurance) {
        final matchesSearch =
            _policyNo(insurance).toLowerCase().contains(search) ||
            _vehicleNo(insurance).toLowerCase().contains(search);

        final matchesStatus =
            selectedStatus == "All statuses" ||
            _status(insurance) == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void resetFilter() {
    searchController.clear();

    setState(() {
      selectedStatus = "All statuses";
      filteredInsurance = List.from(allInsurance);
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
          "Insurance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadInsurance,
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
                            onPressed: _loadInsurance,
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
                                  SizedBox(width: 280, child: searchBox()),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 170, child: statusDropdown()),
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
                              child: filteredInsurance.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text(
                                          "No insurance policies found",
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
                                      DataColumn(label: Text("POLICY NO")),
                                      DataColumn(label: Text("VEHICLE NO")),
                                      DataColumn(label: Text("COMPANY")),
                                      DataColumn(label: Text("START DATE")),
                                      DataColumn(label: Text("EXPIRY DATE")),
                                      DataColumn(label: Text("PREMIUM")),
                                      DataColumn(label: Text("STATUS")),
                                      DataColumn(label: Text("PHOTO")),
                                      DataColumn(label: Text("VIEW")),
                                    ],
                                    rows: filteredInsurance.map((insurance) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              _policyNo(insurance),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _vehicleNo(insurance),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(_company(insurance))),
                                          DataCell(
                                            Text(_date(insurance["StartDate"])),
                                          ),
                                          DataCell(
                                            Text(
                                                _date(insurance["ExpiryDate"])),
                                          ),
                                          DataCell(
                                            Text(
                                              _premium(insurance),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff172033),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            statusBadge(_status(insurance)),
                                          ),
                                          DataCell(
                                            PhotoThumbnail(
                                              photoPath:
                                                  _photoPath(insurance),
                                            ),
                                          ),
                                          DataCell(
                                            outlineButton(
                                              "View",
                                              icon: Icons.visibility,
                                              onPressed: () =>
                                                  viewInsurance(insurance),
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
                            "${filteredInsurance.length} policies found",
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
        hintText: "Search policy / vehicle no...",
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

  Widget statusDropdown() {
    final statuses = [
      "All statuses",
      "Active",
      "ExpiringSoon",
      "Expired",
    ];

    return DropdownButtonFormField<String>(
      value: selectedStatus,
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
    String label = status;

    if (status == "Active") {
      background = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
    } else if (status == "ExpiringSoon") {
      background = const Color(0xffFEF3C7);
      textColor = const Color(0xffD97706);
      label = "Expiring Soon";
    } else {
      background = const Color(0xffFEE2E2);
      textColor = const Color(0xffDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration:
          BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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

  void viewInsurance(Map<String, dynamic> insurance) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Policy ${_policyNo(insurance)}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vehicle: ${_vehicleNo(insurance)}"),
              const SizedBox(height: 8),
              Text("Company: ${_company(insurance)}"),
              const SizedBox(height: 8),
              Text("Start Date: ${_date(insurance["StartDate"])}"),
              const SizedBox(height: 8),
              Text("Expiry Date: ${_date(insurance["ExpiryDate"])}"),
              const SizedBox(height: 8),
              Text("Premium: ${_premium(insurance)}"),
              const SizedBox(height: 8),
              Text("Status: ${_status(insurance)}"),
              const SizedBox(height: 12),
              PhotoThumbnail(photoPath: _photoPath(insurance), size: 120),
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
