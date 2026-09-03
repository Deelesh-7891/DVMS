import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import 'driver_home_screen.dart';

class UploadBillScreen extends StatefulWidget {
  final int vehicleId;
  final String registrationNo;
  final String model;

  const UploadBillScreen({
    super.key,
    required this.vehicleId,
    required this.registrationNo,
    required this.model,
  });

  @override
  State<UploadBillScreen> createState() => _UploadBillScreenState();
}

class _UploadBillScreenState extends State<UploadBillScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceController = TextEditingController();

  List<Map<String, dynamic>> _expenseTypes = [];
  int? _selectedExpenseTypeId;
  bool _loadingTypes = true;
  String? _typesError;

  DateTime _expenseDate = DateTime.now();
  File? _billPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _loadExpenseTypes() async {
    setState(() {
      _loadingTypes = true;
      _typesError = null;
    });

    try {
      final data = await _authService.getExpenseTypes();

      setState(() {
        _expenseTypes = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _loadingTypes = false;
        _typesError = "Unable to load expense types";
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (photo == null) return;

      setState(() => _billPhoto = File(photo.path));
    } catch (e) {
      _showSnack("Unable to open camera: $e", isError: true);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedExpenseTypeId == null) {
      _showSnack("Please select a bill type", isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack("Please enter a valid amount", isError: true);
      return;
    }

    if (_billPhoto == null) {
      _showSnack("Please attach a photo of the bill", isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      await _authService.saveExpense(
        vehicleId: widget.vehicleId,
        expenseTypeId: _selectedExpenseTypeId!,
        expenseDate: DateFormat("yyyy-MM-dd").format(_expenseDate),
        amount: amount,
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
        photoBytes: await _billPhoto!.readAsBytes(),
        photoFileName: _billPhoto!.path.split(Platform.pathSeparator).last,
      );

      if (!mounted) return;

      _showSnack("Bill uploaded successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff2458A6)),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3fb),
      appBar: AppBar(
        title: const Text(
          "Upload Bill",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xff2458A6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Color(0xff2458A6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.registrationNo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.model,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // BILL TYPE
              // ==========================================================
              const Text(
                "Bill Type",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff4B5B73),
                ),
              ),
              const SizedBox(height: 8),

              if (_loadingTypes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_typesError != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typesError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadExpenseTypes,
                      child: const Text("Retry"),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedExpenseTypeId,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    label: "Select bill type",
                    icon: Icons.receipt_long,
                  ),
                  items: _expenseTypes
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: t["ExpenseTypeId"] is int
                              ? t["ExpenseTypeId"] as int
                              : int.tryParse(
                                  t["ExpenseTypeId"]?.toString() ?? '',
                                ),
                          child: Text(t["TypeName"]?.toString() ?? "-"),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedExpenseTypeId = value),
                ),

              const SizedBox(height: 16),

              // ==========================================================
              // DATE
              // ==========================================================
              const Text(
                "Bill Date",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff4B5B73),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    label: "Date",
                    icon: Icons.calendar_today,
                  ),
                  child: Text(
                    DateFormat("dd MMM yyyy").format(_expenseDate),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDecoration(
                  label: "Amount",
                  icon: Icons.currency_rupee,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _vendorController,
                decoration: _fieldDecoration(
                  label: "Vendor / Shop (optional)",
                  icon: Icons.store,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _invoiceController,
                decoration: _fieldDecoration(
                  label: "Invoice number (optional)",
                  icon: Icons.confirmation_number,
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // PHOTO
              // ==========================================================
              const Text(
                "Bill Photo",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff4B5B73),
                ),
              ),
              const SizedBox(height: 8),

              if (_billPhoto != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _billPhoto!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showPhotoPicker,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Retake Photo"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: "Remove Photo",
                      onPressed: () => setState(() => _billPhoto = null),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showPhotoPicker,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Attach Bill Photo"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2458A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit Bill",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
