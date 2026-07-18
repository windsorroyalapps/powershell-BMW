import 'package:flutter/material.dart';
import '../services/rust_can_bridge.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class LiveCanDashboard extends StatefulWidget {
  const LiveCanDashboard({super.key});
  @override State<LiveCanDashboard> createState() => _LiveCanDashboardState();
}

class _LiveCanDashboardState extends State<LiveCanDashboard> {
  List<String> canLogs = [];
  bool isSniffing = false;

  void startSniffing() {
    setState(() => isSniffing = true);
    RustCanBridge.startLiveSniff((frame) {
      setState(() {
        canLogs.add(frame);
        if (canLogs.length > 50) canLogs.removeAt(0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔴 LIVE CAN SNIFFER - E60 N52")),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("CAN Bus Sniffing"),
            value: isSniffing,
            onChanged: (_) => startSniffing(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: canLogs.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(canLogs[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
