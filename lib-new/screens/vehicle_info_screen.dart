import 'package:flutter/material.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() {
    return _VehicleInfoScreenState();
  }
}

class _VehicleInfoScreenState
    extends State<VehicleInfoScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Info'),
      ),
      body: const Center(
        child: Text(
          'Vehicle Info',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}