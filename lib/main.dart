import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'constants/styles.dart';

void main() {
  runApp(MotorInsuranceApp());
}

class MotorInsuranceApp extends StatelessWidget {
  const MotorInsuranceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Insure',
      theme: AppStyles.getTheme(),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
