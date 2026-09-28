import 'package:flutter/material.dart';

class QrPrintScreen extends StatefulWidget {
  const QrPrintScreen({super.key});

  @override
  State<QrPrintScreen> createState() {
    return _QrPrintScreenState();
  }
}

class _QrPrintScreenState
    extends State<QrPrintScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Print'),
      ),
      body: const Center(
        child: Text(
          'QR Print',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}