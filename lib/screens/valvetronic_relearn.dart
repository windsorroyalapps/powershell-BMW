import 'package:flutter/material.dart';
import '../services/rust_can_bridge.dart';
import '../services/powershell_bridge.dart';

class ValvetronicRelearnScreen extends StatefulWidget {
  const ValvetronicRelearnScreen({super.key});
  @override State<ValvetronicRelearnScreen> createState() => _ValvetronicRelearnScreenState();
}

class _ValvetronicRelearnScreenState extends State<ValvetronicRelearnScreen> {
  String status = 'Ready';
  bool isRunning = false;

  Future<void> startRelearn() async {
    setState(() { isRunning = true; status = 'Running ISTA-style relearn...'; });
    
    await PsBridge.runCommand('valvetronic', 'learn');
    await RustCanBridge.valvetronicLearnLimitPositions();
    
    setState(() { 
      status = '✅ Valvetronic Limit Positions Learned Successfully';
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N52 Valvetronic Relearn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRunning ? null : startRelearn,
              child: const Text('Start Valvetronic Relearn'),
            ),
            const Text('Prerequisites: Engine OFF, Ignition ON, Battery charger connected'),
          ],
        ),
      ),
    );
  }
}