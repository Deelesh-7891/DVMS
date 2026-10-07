import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../driver/driver_home_screen.dart';
import '../corporate_admin/fuel_bill_list_screen.dart';
import '../../core/services/odometer_ocr_service.dart';

class AddFuelScreen extends StatefulWidget {
  final int vehicleId;
  final String registrationNo;
  final String model;

  const AddFuelScreen({
    super.key,
    required this.vehicleId,
    required this.registrationNo,
    required this.model,
  });

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final AuthService _authService = AuthService();

  final vehicleNameController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  final odoController = TextEditingController();
  final litersController = TextEditingController();
  final rateController = TextEditingController();
  final stationController = TextEditingController();
  final notesController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  File? selectedReceipt;
  File? odoImage;

  bool isReadingOdometer = false;
  bool _saving = false;

  double total = 0;

  int gradientIndex = 0;

  final List<List<Color>> gradients = [
    [const Color(0xff4F9AFF), const Color(0xff7DB9FF)],
    [const Color(0xff9D50FF), const Color(0xffC77DFF)],
    [const Color(0xffFF9966), const Color(0xffFF5E62)],
    [const Color(0xff00C6FF), const Color(0xff0072FF)],
  ];

  @override
  void initState() {
    super.initState();

    vehicleNumberController.text = widget.registrationNo;
    vehicleNameController.text = widget.model;

    animateGradient();
  }

  @override
  void dispose() {
    vehicleNameController.dispose();
    vehicleNumberController.dispose();
    odoController.dispose();
    litersController.dispose();
    rateController.dispose();
    stationController.dispose();
    notesController.dispose();

    super.dispose();
  }

  void showSnack(String message, {bool error = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void animateGradient() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      setState(() {
        gradientIndex = (gradientIndex + 1) % gradients.length;
      });

      animateGradient();
    });
  }

  // =========================================================
  // CALCULATE TOTAL
  // =========================================================

  void updateTotal() {
    final liters = double.tryParse(litersController.text.trim()) ?? 0;

    final rate = double.tryParse(rateController.text.trim()) ?? 0;

    setState(() {
      total = liters * rate;
    });
  }

  // =========================================================
  // RECEIPT IMAGE
  // =========================================================

  Future<void> pickReceipt(ImageSource source) async {
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);

      if (picked == null) return;

      setState(() {
        selectedReceipt = File(picked.path);
      });

      showSnack("Receipt selected successfully", error: false);
    } catch (e) {
      showSnack("Receipt image error: $e");
    }
  }

  void showReceiptPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _pickerSheet(
          onCamera: () {
            Navigator.pop(context);
            pickReceipt(ImageSource.camera);
          },
          onGallery: () {
            Navigator.pop(context);
            pickReceipt(ImageSource.gallery);
          },
        );
      },
    );
  }

  // =========================================================
  // ODOMETER IMAGE + OCR
  // =========================================================

  Future<void> pickOdoImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);

      if (picked == null) return;

      setState(() {
        odoImage = File(picked.path);
        isReadingOdometer = true;
      });

      final reading = await OdometerOcrService.recognizeFromPath(picked.path);

      if (!mounted) return;

      setState(() {
        isReadingOdometer = false;

        if (reading != null) {
          odoController.text = reading;
        }
      });

      if (reading != null) {
        showSnack("Detected $reading km. Please verify.", error: false);
      } else {
        showSnack("Could not read odometer. Please enter manually.");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isReadingOdometer = false;
      });

      showSnack("Odometer image error: $e");
    }
  }

  void showOdoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _pickerSheet(
          onCamera: () {
            Navigator.pop(context);
            pickOdoImage(ImageSource.camera);
          },
          onGallery: () {
            Navigator.pop(context);
            pickOdoImage(ImageSource.gallery);
          },
        );
      },
    );
  }

  Widget _pickerSheet({
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),

          const Text(
            "Select Image",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text("Take Photo"),
            onTap: onCamera,
          ),

          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blue),
            title: const Text("Choose from Gallery"),
            onTap: onGallery,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // =========================================================
  // SAVE FUEL
  // =========================================================

  Future<void> saveFuel() async {
    if (_saving) return;

    // -------------------------
    // VEHICLE
    // -------------------------

    if (widget.vehicleId <= 0) {
      showSnack("Invalid Vehicle ID");
      return;
    }

    // -------------------------
    // FUEL STATION
    // -------------------------

    final fuelStation = stationController.text.trim();

    if (fuelStation.isEmpty) {
      showSnack("Please enter Fuel Station");
      return;
    }

    // -------------------------
    // LITERS
    // -------------------------

    final liters = double.tryParse(litersController.text.trim());

    if (liters == null || liters <= 0) {
      showSnack("Please enter valid Liters");
      return;
    }

    // -------------------------
    // RATE
    // -------------------------

    final rate = double.tryParse(rateController.text.trim());

    if (rate == null || rate <= 0) {
      showSnack("Please enter valid Rate");
      return;
    }

    // -------------------------
    // AMOUNT
    // -------------------------

    final amount = liters * rate;

    // -------------------------
    // ODOMETER
    // -------------------------

    final odometer = int.tryParse(odoController.text.trim());

    if (odometer == null || odometer < 0) {
      showSnack("Please enter valid Odometer");
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      int? attachmentId;

      // =====================================================
      // STEP 1: UPLOAD RECEIPT
      // =====================================================

      if (selectedReceipt != null) {
        debugPrint("========== FUEL RECEIPT UPLOAD ==========");

        debugPrint("File: ${selectedReceipt!.path}");

        try {
          final uploadResult = await _authService.uploadAttachment(
            bytes: await selectedReceipt!.readAsBytes(),
            fileName: selectedReceipt!.path.split(Platform.pathSeparator).last,
            entityType: 'Fuel',
          );

          attachmentId = uploadResult.attachmentId;

          debugPrint("Attachment ID: $attachmentId");
        } catch (e) {
          debugPrint("ATTACHMENT UPLOAD ERROR: $e");

          throw Exception("Receipt upload failed: $e");
        }
      }

      // =====================================================
      // STEP 2: SAVE FUEL
      // =====================================================

      debugPrint("========== SAVE FUEL ==========");

      debugPrint("VehicleId: ${widget.vehicleId}");

      debugPrint(
        "TxnDate: ${DateTime.now().toIso8601String().substring(0, 10)}",
      );

      debugPrint("FuelStation: $fuelStation");

      debugPrint("Liters: $liters");

      debugPrint("Rate: $rate");

      debugPrint("Amount: $amount");

      debugPrint("Odometer: $odometer");

      debugPrint("AttachmentId: $attachmentId");

      Future<void> save({bool confirm = false}) => _authService.saveFuel(
        vehicleId: widget.vehicleId,
        txnDate: DateTime.now().toIso8601String().substring(0, 10),
        fuelStation: fuelStation,
        amount: amount,
        odometer: odometer,
        quantity: liters,
        attachmentId: attachmentId,
        confirmDuplicate: confirm,
      );

      try {
        await save();
      } on DuplicateFuelException catch (dup) {
        if (!mounted) return;
        final ok = await confirmDuplicateFuel(context, dup.message);
        if (!ok) return;
        await save(confirm: true);
      }

      // =====================================================
      // SUCCESS
      // =====================================================

      if (!mounted) return;

      showSnack("Fuel Entry Saved Successfully", error: false);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FuelBillListScreen()),
      );
    } catch (e) {
      debugPrint("========== FUEL SAVE ERROR ==========");

      debugPrint(e.toString());

      if (!mounted) return;

      String message = e.toString();

      // Remove Exception: prefix
      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }

      showSnack(message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3fb),

      appBar: AppBar(
        title: const Text(
          "Create Fuel Request",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,

        flexibleSpace: AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradients[gradientIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 15, bottom: 30),
          child: _buildCard(
            child: Column(
              children: [
                // =================================================
                // VEHICLE
                // =================================================
                buildInput(
                  vehicleNameController,
                  "Vehicle Name",
                  Icons.drive_eta,
                  readOnly: true,
                ),

                buildInput(
                  vehicleNumberController,
                  "Vehicle Number",
                  Icons.confirmation_number,
                  readOnly: true,
                ),

                // =================================================
                // ODOMETER
                // =================================================
                TextField(
                  controller: odoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Odometer (ODO)",
                    prefixIcon: const Icon(Icons.speed, color: Colors.blue),

                    suffixIcon: isReadingOdometer
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                            ),
                            onPressed: showOdoPicker,
                          ),

                    filled: true,
                    fillColor: Colors.grey.shade100,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (odoImage != null) ...[
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      odoImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  if (!isReadingOdometer)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "Reading auto-filled from photo — please verify.",
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ),
                ],

                const SizedBox(height: 14),

                // =================================================
                // LITERS
                // =================================================
                buildInput(
                  litersController,
                  "Liters",
                  Icons.local_gas_station,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChange: updateTotal,
                ),

                // =================================================
                // RATE
                // =================================================
                buildInput(
                  rateController,
                  "Rate / Liter",
                  Icons.currency_rupee,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChange: updateTotal,
                ),

                // =================================================
                // TOTAL
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹ ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // FUEL STATION
                // =================================================
                buildInput(stationController, "Fuel Station", Icons.store),

                // =================================================
                // NOTES
                // =================================================
                buildInput(
                  notesController,
                  "Notes",
                  Icons.note_alt,
                  maxLines: 3,
                ),

                const SizedBox(height: 10),

                // =================================================
                // RECEIPT
                // =================================================
                GestureDetector(
                  onTap: _saving ? null : showReceiptPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          "Upload Receipt",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (selectedReceipt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedReceipt!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // =================================================
                // SUBMIT
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saving ? null : saveFuel,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Submit Request",
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
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: child,
    );
  }

  // =========================================================
  // INPUT
  // =========================================================

  Widget buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    Function? onChange,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,

        onChanged: (_) {
          if (onChange != null) {
            onChange();
          }
        },

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(icon, color: Colors.blue),

          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
