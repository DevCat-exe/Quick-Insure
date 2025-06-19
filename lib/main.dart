import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'constants/styles.dart';

void main() {
  runApp(MotorInsuranceApp());
}

class MotorInsuranceApp extends StatefulWidget {
  const MotorInsuranceApp({super.key});

  @override
  State<MotorInsuranceApp> createState() => _MotorInsuranceAppState();
}

class _MotorInsuranceAppState extends State<MotorInsuranceApp> {
  bool _darkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Insure',
      theme: AppStyles.getTheme(dark: _darkMode),
      home: HomeScreen(
        onToggleDarkMode: _toggleDarkMode,
        darkMode: _darkMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
