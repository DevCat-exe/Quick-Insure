import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculationHistoryItem {
  final String date;
  final String type;
  final double totalPremium;
  final Map<String, dynamic> details;

  CalculationHistoryItem({
    required this.date,
    required this.type,
    required this.totalPremium,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'type': type,
    'totalPremium': totalPremium,
    'details': details,
  };

  factory CalculationHistoryItem.fromJson(Map<String, dynamic> json) =>
      CalculationHistoryItem(
        date: json['date'],
        type: json['type'],
        totalPremium: json['totalPremium'],
        details: json['details'],
      );
}

class HistoryService {
  static const String _key = 'calculation_history';

  static Future<void> saveCalculation(CalculationHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    history.insert(0, jsonEncode(item.toJson()));
    if (history.length > 50) history.removeLast(); // Keep last 50
    await prefs.setStringList(_key, history);
  }

  static Future<List<CalculationHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    return history
        .map((item) => CalculationHistoryItem.fromJson(jsonDecode(item)))
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
