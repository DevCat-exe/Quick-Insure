import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fire_insurance_model.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../services/history_service.dart';
import '../main.dart';

class FireInsuranceCalculator extends StatefulWidget {
  const FireInsuranceCalculator({super.key});

  @override
  State<FireInsuranceCalculator> createState() =>
      _FireInsuranceCalculatorState();

  static String get displayName => "Fire Insurance";
}

class _FireInsuranceCalculatorState extends State<FireInsuranceCalculator> {
  final TextEditingController _sumController = TextEditingController();
  String? _selectedZone;
  String? _selectedRisk;
  final List<String> _addedRisks = [];

  static const List<String> _zones = ['Dhaka', 'Chittagong', 'Sylhet'];
  static const List<String> _allRisks = [
    'Fire',
    'Earthquake',
    'Cyclone',
    'Flood'
  ];

  bool get _isFormValid =>
      _sumController.text.isNotEmpty &&
      _selectedZone != null &&
      _addedRisks.isNotEmpty;

  List<String> get _availableRisks =>
      _allRisks.where((r) => !_addedRisks.contains(r)).toList();

  double _getRateForRisk(String risk) {
    if (_selectedZone == null) return 0.0;
    return FireInsuranceModel.ratesTable[_selectedZone]?[risk] ?? 0.0;
  }

  void _addRisk() {
    if (_selectedRisk != null && !_addedRisks.contains(_selectedRisk)) {
      setState(() {
        _addedRisks.add(_selectedRisk!);
        _selectedRisk = null;
      });
    }
  }

  void _removeRisk(String risk) {
    setState(() {
      _addedRisks.remove(risk);
      if (_addedRisks.isEmpty) {
        _selectedRisk = null;
      }
    });
  }

  void _calculatePremium() async {
    try {
      double insuredSum = double.parse(_sumController.text);

      Map<String, dynamic> result = FireInsuranceModel.calculatePremium(
        insuredSum: insuredSum,
        zone: _selectedZone!,
        selectedRisks: _addedRisks,
      );

      // Build risk breakdown string for history
      final riskBreakdown = _addedRisks
          .map((r) => "$r (${_getRateForRisk(r)}%)")
          .join(', ');

      final historyItem = CalculationHistoryItem(
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        type: 'Fire Insurance',
        totalPremium: result['totalPremium'],
        details: {
          'Insured Sum':
              "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
          'Zone': _selectedZone!,
          'Selected Risks': riskBreakdown,
          'Total Rate': "${result['totalRate']}%",
          'Net Premium':
              "BDT ${NumberFormat("#,##0", "en_US").format(result['netPremium'])}",
          'VAT (15%)':
              "BDT ${NumberFormat("#,##0", "en_US").format(result['vat'])}",
        },
      );
      await HistoryService.saveCalculation(historyItem);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          title: "Fire Insurance",
          netPremium: result['netPremium'],
          vat: result['vat'],
          totalPremium: result['totalPremium'],
          insuredSum: insuredSum,
          sections: [
            ResultSection("Property Details", {
              "Zone": _selectedZone!,
            }),
            ResultSection("Selected Risks", {
              for (var risk in _addedRisks)
                risk: "${_getRateForRisk(risk)}%",
            }),
            ResultSection("Summary", {
              "Total Rate": "${result['totalRate']}%",
            }),
          ],
          exportDetails: {
            'Insured Sum':
                "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
            'Zone': _selectedZone!,
            'Selected Risks': riskBreakdown,
            'Total Rate': "${result['totalRate']}%",
            'Net Premium':
                "BDT ${NumberFormat("#,##0", "en_US").format(result['netPremium'])}",
            'VAT (15%)':
                "BDT ${NumberFormat("#,##0", "en_US").format(result['vat'])}",
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = scaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text("Invalid input. Please check your values.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(FireInsuranceCalculator.displayName),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24.0,
          right: 24.0,
          top: 32.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, "Property Details"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _sumController,
              labelText: "Sum Insured (Tk)",
              hintText: "e.g. 10,000,000",
              prefixIcon: Icons.account_balance_wallet,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, "Zone & Risk Selection"),
            const SizedBox(height: 20),
            CustomDropdown(
              value: _selectedZone ?? '',
              items: ['', ..._zones],
              onChanged: _addedRisks.isEmpty
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedZone = value.isEmpty ? null : value;
                          _selectedRisk = null;
                        });
                      }
                    }
                  : null,
              labelText: "Zone",
              icon: Icons.location_on_outlined,
            ),
            if (_addedRisks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Zone is locked while risks are selected",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary.withAlpha(150),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_selectedZone != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _availableRisks.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            initialValue: _selectedRisk,
                            items: _availableRisks.map((risk) {
                              final rate = _getRateForRisk(risk);
                              return DropdownMenuItem(
                                value: risk,
                                child: Text("$risk — $rate%"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedRisk = value);
                            },
                            decoration: InputDecoration(
                              labelText: "Select Risk",
                              prefixIcon: Icon(Icons.warning_amber_outlined,
                                  color: theme.colorScheme.primary),
                            ),
                          )
                        : InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Select Risk",
                              prefixIcon: Icon(Icons.check_circle_outline,
                                  color: theme.colorScheme.primary),
                            ),
                            child: Text(
                              "All risks added",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(120),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: ElevatedButton(
                      onPressed:
                          _selectedRisk != null && _availableRisks.isNotEmpty
                              ? _addRisk
                              : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_addedRisks.isNotEmpty) ...[
                _buildSectionHeader(theme, "Added Risks"),
                const SizedBox(height: 12),
                ..._addedRisks.map((risk) {
                  final rate = _getRateForRisk(risk);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getRiskIcon(risk),
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                risk,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$rate%",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _removeRisk(risk),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _calculatePremium : null,
                child: const Text("Calculate Premium"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRiskIcon(String risk) {
    switch (risk) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Earthquake':
        return Icons.landscape;
      case 'Cyclone':
        return Icons.cyclone;
      case 'Flood':
        return Icons.water;
      default:
        return Icons.warning;
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}
