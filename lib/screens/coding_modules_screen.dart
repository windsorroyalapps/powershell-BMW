import 'package:flutter/material.dart';
import '../services/powershell_bridge.dart';

class CodingModulesScreen extends StatelessWidget {
  const CodingModulesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final ps = PsBridge();
    return Scaffold(
      appBar: AppBar(title: const Text("🛠️ E60 Coding Modules")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text("FRM - Lights & Chimes"), onTap: () => ps.runCommand("frm", "chime-delete")),
          ListTile(title: const Text("DME - N52 Tuning"), onTap: () => ps.runCommand("dme", "valvetronic")),
          ListTile(title: const Text("CAS - Key & Immobilizer"), onTap: () => ps.runCommand("cas", "read")),
          ListTile(title: const Text("JBE - Body Electronics"), onTap: () => ps.runCommand("jbe", "mirrors")),
        ],
      ),
    );
  }
}
