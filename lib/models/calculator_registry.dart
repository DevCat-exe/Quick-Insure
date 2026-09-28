import 'package:flutter/material.dart';

class CalculatorPreset {
  final String label;
  final String description;
  final IconData icon;
  final Map<String, dynamic> values;

  const CalculatorPreset({
    required this.label,
    required this.description,
    required this.icon,
    required this.values,
  });
}

class CalculatorRegistry {
  static const List<CalculatorPreset> motorPresets = [
    CalculatorPreset(
      label: 'Sedan (1500cc)',
      description: 'Standard private vehicle',
      icon: Icons.directions_car,
      values: {
        'sum': '1500000',
        'cc': '1500',
        'passengers': '4',
        'drivers': '1',
        'risk': '2.65',
        'discount': '0%',
        'ncb': '0%',
      },
    ),
    CalculatorPreset(
      label: 'SUV (2000cc)',
      description: 'Premium family vehicle',
      icon: Icons.car_rental,
      values: {
        'sum': '3500000',
        'cc': '2000',
        'passengers': '6',
        'drivers': '1',
        'risk': '2.65',
        'discount': '10%',
        'ncb': '30%',
      },
    ),
    CalculatorPreset(
      label: 'Microbus (2500cc)',
      description: 'Commercial passenger transit',
      icon: Icons.airport_shuttle,
      values: {
        'sum': '2400000',
        'cc': '2500',
        'passengers': '11',
        'drivers': '1',
        'risk': '2.65',
        'discount': '10%',
        'ncb': '0%',
      },
    ),
    CalculatorPreset(
      label: 'Motorcycle (150cc)',
      description: 'Two-wheeler coverage',
      icon: Icons.two_wheeler,
      values: {
        'sum': '200000',
        'cc': '150',
        'passengers': '1',
        'drivers': '1',
        'risk': '2.15',
        'discount': '0%',
        'ncb': '0%',
      },
    ),
  ];

  static const List<CalculatorPreset> firePresets = [
    CalculatorPreset(
      label: 'Dhaka Commercial',
      description: 'Commercial building (Fire + EQ)',
      icon: Icons.business,
      values: {
        'sum': '20000000',
        'zone': 'Dhaka',
        'risks': ['Fire', 'Earthquake'],
      },
    ),
    CalculatorPreset(
      label: 'Chittagong Industrial',
      description: 'Industrial facility (All Risks)',
      icon: Icons.factory,
      values: {
        'sum': '50000000',
        'zone': 'Chittagong',
        'risks': ['Fire', 'Earthquake', 'Cyclone', 'Flood'],
      },
    ),
    CalculatorPreset(
      label: 'Sylhet Residential',
      description: 'Residential property (Fire + EQ + Flood)',
      icon: Icons.home,
      values: {
        'sum': '10000000',
        'zone': 'Sylhet',
        'risks': ['Fire', 'Earthquake', 'Flood'],
      },
    ),
  ];
}
