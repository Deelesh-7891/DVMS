import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../driver/driver_home_screen.dart';

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
// class AddFuelScreen extends StatefulWidget {
//   const AddFuelScreen({super.key});
  
//   @override
//   State<AddFuelScreen> createState() => _AddFuelScreenState();
// }

class _AddFuelScreenState extends State<AddFuelScreen> {
  final vehicleName = TextEditingController();
  final vehicleNumber = TextEditingController();
  final odoController = TextEditingController();
  final litersController = TextEditingController();
  final rateController = TextEditingController();
  final stationController = TextEditingController();
  final notesController = TextEditingController();
  final AuthService _authService = AuthService();

  //  final int vehicleId;
  // final String registrationNo;
  // final String model;
 void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  double total = 0;
  int? userId;
  int? Manager_id;
  File? selectedReceipt;
  File? odoImage;
  int gradientIndex = 0;
  final picker = ImagePicker();

  final List<List<Color>> gradients = [
    [Color(0xff4F9AFF), Color(0xff7DB9FF)],
    [Color(0xff9D50FF), Color(0xffC77DFF)],
    [Color(0xffFF9966), Color(0xffFF5E62)],
    [Color(0xff00C6FF), Color(0xff0072FF)],
  ];



  @override
  void initState() {
    super.initState();
    // loadUserID();
    vehicleNumber.text = widget.registrationNo;
    vehicleName.text = widget.model;
    animateGradient();
  }

  // Future<void> loadUserID() async {
  //   userId = await Storage.getUserID();
  //   Manager_id = await Storage.getManagerId();
  //   setState(() {});
  // }

  void animateGradient() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        gradientIndex = (gradientIndex + 1) % gradients.length;
      });
      animateGradient();
    });
  }

  void updateTotal() {
    setState(() {
      total =
          (double.tryParse(litersController.text) ?? 0) *
              (double.tryParse(rateController.text) ?? 0);
    });
  }

  // ================= IMAGE PICKERS =================

  Future<void> pickReceipt(ImageSource source) async {
    final picked =
    await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => selectedReceipt = File(picked.path));
    }
  }

  Future<void> pickOdoImage(ImageSource source) async {
    final picked =
    await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => odoImage = File(picked.path));
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
          onCamera: () => pickOdoImage(ImageSource.camera),
          onGallery: () => pickOdoImage(ImageSource.gallery),
        );
      },
    );
  }

  void showReceiptPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _pickerSheet(
          onCamera: () => pickReceipt(ImageSource.camera),
          onGallery: () => pickReceipt(ImageSource.gallery),
        );
      },
    );
  }

  Widget _pickerSheet({
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text("Take Photo"),
          onTap: () {
            Navigator.pop(context);
            onCamera();
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text("Choose from Gallery"),
          onTap: () {
            Navigator.pop(context);
            onGallery();
          },
        ),
      ],
    );
  }

  // ================= SUBMIT (FIXED) =================

  Future<void> saveFuel() async {
  if (stationController.text.trim().isEmpty) {
    showSnack("Please enter Fuel Station");
    return;
  }

  final amount = double.tryParse(rateController.text);

  if (amount == null) {
    showSnack("Please enter valid Amount");
    return;
  }

  final odometer = int.tryParse(odoController.text);

  if (odometer == null) {
    showSnack("Please enter valid Odometer");
    return;
  }

  try {
    await _authService.saveFuel(
      vehicleId: widget.vehicleId,
      txnDate: DateTime.now().toIso8601String().substring(0, 10),
      fuelStation: stationController.text.trim(),
      amount: amount,
      odometer: odometer,
    );

    showSnack("Fuel Entry Saved Successfully");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverHomeScreen(),
      ),
    );
  } catch (e) {
    showSnack(e.toString());
  }
}

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3fb),
      appBar: AppBar(
        title: const Text("Create Fuel Request"),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildCard(
              child: Column(
                children: [
                  buildInput(vehicleName, "Vehicle Name", Icons.drive_eta),
                  // buildInput(vehicleNumber, "Vehicle Number", Icons.confirmation_number),
                  buildInput(
  vehicleNumber,
  "Vehicle Number",
  Icons.confirmation_number,
  readOnly: true,
),
                  TextField(
                    controller: odoController,
                    decoration: InputDecoration(
                      labelText: "Odometer (ODO)",
                      prefixIcon: const Icon(Icons.speed),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: showOdoPicker,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (odoImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(odoImage!, height: 120),
                      ),
                    ),

                  const SizedBox(height: 14),

                  buildInput(litersController, "Liters", Icons.local_gas_station,
                      onChange: updateTotal),
                  buildInput(rateController, "Rate", Icons.currency_rupee,
                      onChange: updateTotal),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Total Amount: ₹ $total",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  buildInput(stationController, "Fuel Station", Icons.store),
                  buildInput(notesController, "Notes", Icons.note_alt),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: showReceiptPicker,
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
                          Text("Upload Receipt"),
                        ],
                      ),
                    ),
                  ),

                  if (selectedReceipt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(selectedReceipt!, height: 150),
                      ),
                    ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      
                     onPressed: () async {
  try {
    await _authService.saveFuel(
      vehicleId: widget.vehicleId,
      txnDate: DateTime.now().toIso8601String().substring(0, 10),
      fuelStation: stationController.text.trim(),
      amount: double.parse(rateController.text),
      odometer: int.parse(odoController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fuel Entry Saved Successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverHomeScreen(),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
},
                      // onPressed: saveFuel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      
                      child: const Text(
                        
                        "Submit Request",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),



                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget buildInput(
  TextEditingController controller,
  String label,
  IconData icon, {
  Function? onChange,
  bool readOnly = false,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      readOnly: readOnly,
      onChanged: (_) => onChange != null ? onChange() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
}
