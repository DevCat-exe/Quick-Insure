import 'dart:convert';
import 'package:intl/intl.dart';
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

  bool matchesSearch(String query) {
    final rawQuery = query.trim().toLowerCase();
    if (rawQuery.isEmpty) return true;

    final normalizedQuery = _normalizeSearchText(rawQuery);
    final formattedPremium =
        NumberFormat('#,##0', 'en_US').format(totalPremium);
    final values = [
      type,
      date,
      ..._dateSearchAliases(),
      totalPremium.toString(),
      formattedPremium,
      'BDT $formattedPremium',
      ...details.entries.expand((entry) => [entry.key, entry.value.toString()]),
    ];

    return values.any((value) {
      final lowerValue = value.toLowerCase();
      if (lowerValue.contains(rawQuery)) return true;
      return normalizedQuery.isNotEmpty &&
          _normalizeSearchText(lowerValue).contains(normalizedQuery);
    });
  }

  List<String> _dateSearchAliases() {
    try {
      final parsedDate =
          DateFormat('dd MMM yyyy, hh:mm a', 'en_US').parseStrict(date);
      return [
        DateFormat('d/M/yy').format(parsedDate),
        DateFormat('dd/MM/yy').format(parsedDate),
        DateFormat('d/M/yyyy').format(parsedDate),
        DateFormat('dd/MM/yyyy').format(parsedDate),
        DateFormat('d MMM yyyy', 'en_US').format(parsedDate),
        DateFormat('d MMMM yyyy', 'en_US').format(parsedDate),
        DateFormat('yyyy-MM-dd').format(parsedDate),
      ];
    } on FormatException {
      return const [];
    }
  }

  static String _normalizeSearchText(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized.replaceAll('september', 'sep').replaceAll('sept', 'sep');
  }

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

  static Future<void> deleteCalculation(CalculationHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    final targetJson = jsonEncode(item.toJson());
    history.removeWhere((str) => str == targetJson);
    await prefs.setStringList(_key, history);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
