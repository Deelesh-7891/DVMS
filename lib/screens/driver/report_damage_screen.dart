import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class ReportDamageScreen extends StatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  State<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends State<ReportDamageScreen> {
final AuthService _authService = AuthService();

  final locationController = TextEditingController();

  final descriptionController = TextEditingController();
  
  String damageType = "Scratch";
  File? cameraImage;
  final ImagePicker picker = ImagePicker();
  File? selectedImage;


 Future<void> openCamera() async {
  final XFile? image = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 80,
  );

  if (image != null) {
    setState(() {
      cameraImage = File(image.path);
    });
  }
}

  Future<void> saveDamage() async {
  try {
    await _authService.reportDamageSave(
      vehicleId: 2011,
      txnDate: DateTime.now().toIso8601String(),
      damageType: damageType,
      location: locationController.text,
      description: descriptionController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Damage Report Saved Successfully"),
        backgroundColor: Colors.green,
      ),
    );

    // Clear fields
    locationController.clear();
    descriptionController.clear();

   setState(() {
  damageType = "Scratch";
});

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  final damageTypes = [
    "Scratch",
    "Dent",
    "Crack",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),

      appBar: AppBar(
        backgroundColor: const Color(0xff2457B3),
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⚠ Report Damage",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "RJ14 DM 0002 · Harrier",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "PHOTOS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                 Expanded(
  child: InkWell(
    onTap: openCamera,
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: cameraImage == null
          ? const Center(
              child: Icon(
                Icons.camera_alt,
                size: 30,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                cameraImage!,
                fit: BoxFit.cover,
              ),
            ),
    ),
  ),
),


                // Expanded(
                //   child: Container(
                //     height: 100,
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(
                //         color: Colors.grey.shade300,
                //         style: BorderStyle.solid,
                //       ),
                //     ),
                //     child: const Center(
                //       child: Icon(
                //         Icons.camera_alt,
                //         size: 30,
                //       ),
                //     ),
                //   ),
                // ),

                const SizedBox(width: 12),
Expanded(
  child: InkWell(
    onTap: openCamera,
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: selectedImage == null
          ? const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text("Add"),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
    ),
  ),
),
                // Expanded(
                //   child: InkWell(
                //     onTap: () {
                //       // Pick Image
                //     },
                //     child: Container(
                //       height: 100,
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(12),
                //         border: Border.all(
                //           color: Colors.grey.shade300,
                //         ),
                //       ),
                //       child: const Center(
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Icon(Icons.add),
                //             Text("Add"),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),





              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "DAMAGE TYPE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: damageTypes.map((e) {
                final selected = damageType == e;

                return ChoiceChip(
  label: Text(e),
  selected: selected,
  onSelected: (_) {
    setState(() {
      damageType = e;
    });
  },
);
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              "LOCATION ON VEHICLE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: locationController,
             
              decoration: InputDecoration(
                filled: true,
                hintText: "Enter damage location",
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "DESCRIPTION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                hintText: "Describe the damage",
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {

  if (locationController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter damage location")),
    );
    return;
  }

  if (descriptionController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter damage description")),
    );
    return;
  }

  await saveDamage();
},
                // onPressed: () {

                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(
                //       content: Text("Damage Report Submitted"),
                //     ),
                //   );

                // },
                child: const Text(
                  "Submit Report",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}