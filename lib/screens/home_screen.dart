import 'package:flutter/material.dart';
import '../services/obd_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ObdService obd = ObdService();
  String status = 'Disconnected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E60Coder Pro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $status'),
            ElevatedButton(onPressed: () async { await obd.connect(); setState(() {}); }, child: const Text('Connect OBD')),
            // Add more buttons for gauges, tune, AFS etc.
          ],
        ),
      ),
    );
  }
}