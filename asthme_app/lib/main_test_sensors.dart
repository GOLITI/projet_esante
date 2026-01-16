import 'package:flutter/material.dart';
import 'package:asthme_app/presentation/screens/test_sensors_screen.dart';

void main() {
  runApp(const TestSensorsApp());
}

class TestSensorsApp extends StatelessWidget {
  const TestSensorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Capteurs Environnementaux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TestSensorsScreen(),
    );
  }
}
