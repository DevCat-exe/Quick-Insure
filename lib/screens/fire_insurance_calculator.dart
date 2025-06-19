import 'package:flutter/material.dart';

class FireInsuranceCalculator extends StatelessWidget {
  const FireInsuranceCalculator({super.key});

  static String get displayName => "Fire Insurance";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FireInsuranceCalculator.displayName),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC53030), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "Fire Insurance Calculator",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC53030),
              ),
            ),
            SizedBox(height: 20),
            // Add fire-specific fields here
          ],
        ),
      ),
    );
  }
}
