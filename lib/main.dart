import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const E60CoderPro());
}

class E60CoderPro extends StatelessWidget {
  const E60CoderPro({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E60Coder Pro',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}