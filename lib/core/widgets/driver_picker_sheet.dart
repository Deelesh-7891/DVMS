import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Bottom sheet listing the drivers of the guard's state (GET /drivers).
/// Returns the picked driver's row, or null if the guard closed the sheet.
///
/// Picking from the list (instead of typing) is what lets the server open a
/// tracked trip on gate-out, so the driver's live location shows on the web.
Future<Map<String, dynamic>?> showDriverPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _DriverPickerSheet(),
  );
}

class _DriverPickerSheet extends StatefulWidget {
  const _DriverPickerSheet();

  @override
  State<_DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends State<_DriverPickerSheet> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AuthService().getDrivers();
      setState(() {
        _all = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load drivers';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toUpperCase();
    final list = q.isEmpty
        ? _all
        : _all.where((d) {
            final hay =
                '${d['DriverName'] ?? ''} ${d['Phone'] ?? ''} ${d['EmployeeCode'] ?? ''} ${d['LocationName'] ?? ''}'
                    .toUpperCase();
            return hay.contains(q);
          }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Driver',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search name / phone',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : list.isEmpty
                    ? const Center(child: Text('No drivers found'))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final d = list[i];
                          final hasApp = d['UserId'] != null;
                          final outWith = d['ActiveVehicle'];
                          final sub =
                              [
                                    d['LocationName'],
                                    d['Phone'],
                                    if (outWith != null) 'Out with $outWith',
                                  ]
                                  .where(
                                    (s) => s != null && s.toString().isNotEmpty,
                                  )
                                  .join(' · ');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasApp
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              child: Icon(
                                Icons.person,
                                color: hasApp ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              d['DriverName']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(sub),
                            trailing: hasApp
                                ? const Tooltip(
                                    message: 'Live tracking',
                                    child: Icon(
                                      Icons.gps_fixed,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  )
                                : const Text(
                                    'No app',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                            onTap: () => Navigator.pop(context, d),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
