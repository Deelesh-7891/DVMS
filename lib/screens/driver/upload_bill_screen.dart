import 'package:flutter/material.dart';

class UploadBillScreen extends StatelessWidget {
  const UploadBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Bill"),
      ),
      body: const Center(
        child: Text("Upload Bill Screen"),
      ),
    );
  }
}