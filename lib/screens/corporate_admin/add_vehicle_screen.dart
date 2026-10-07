import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final registrationController = TextEditingController();
  final modelController = TextEditingController();
  final variantController = TextEditingController();
  final chassisController = TextEditingController();
  final engineController = TextEditingController();

  @override
  void dispose() {
    registrationController.dispose();
    modelController.dispose();
    variantController.dispose();
    chassisController.dispose();
    engineController.dispose();
    super.dispose();
  }

  void saveVehicle() {
    if (registrationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Registration No")),
      );
      return;
    }

    final vehicleData = {
      "RegistrationNo": registrationController.text.trim(),
      "Model": modelController.text.trim(),
      "Variant": variantController.text.trim(),
      "ChassisNo": chassisController.text.trim(),
      "EngineNo": engineController.text.trim(),
    };

    debugPrint("ADD VEHICLE: $vehicleData");

    // Actual API connect hone ke baad:
    // Navigator.pop(context, true);

    Navigator.pop(context, true);
  }

  Widget field({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff475569),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        title: const Text(
          "Add Vehicle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffdce3ec)),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vehicle Information",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff172033),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Enter vehicle details",
                    style: TextStyle(color: Color(0xff64748b)),
                  ),

                  const SizedBox(height: 25),

                  field(
                    label: "Registration No",
                    controller: registrationController,
                    hint: "Enter registration number",
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: "Model",
                          controller: modelController,
                          hint: "Enter model",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: field(
                          label: "Variant",
                          controller: variantController,
                          hint: "Enter variant",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: "Chassis No",
                          controller: chassisController,
                          hint: "Enter chassis number",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: field(
                          label: "Engine No",
                          controller: engineController,
                          hint: "Enter engine number",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        onPressed: saveVehicle,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Vehicle"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2458A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
