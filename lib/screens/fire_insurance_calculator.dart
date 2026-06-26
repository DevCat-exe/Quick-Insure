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
  final Map<String, bool> _selectedRisksMap = {};

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
      _selectedRisksMap.values.any((selected) => selected);

  List<String> get _selectedRisks =>
      _allRisks.where((r) => _selectedRisksMap[r] == true).toList();

  double _getRateForRisk(String risk) {
    if (_selectedZone == null) return 0.0;
    return FireInsuranceModel.ratesTable[_selectedZone]?[risk] ?? 0.0;
  }

  void _calculatePremium() async {
    try {
      double insuredSum = double.parse(_sumController.text);
      final selectedRisks = _selectedRisks;

      Map<String, dynamic> result = FireInsuranceModel.calculatePremium(
        insuredSum: insuredSum,
        zone: _selectedZone!,
        selectedRisks: selectedRisks,
      );

      final riskPremiums = result['riskPremiums'] as Map<String, double>;

      final riskBreakdown = selectedRisks
          .map((r) => "$r (${_getRateForRisk(r)}%) - BDT ${NumberFormat("#,##0", "en_US").format(riskPremiums[r])}")
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
              for (var risk in selectedRisks)
                risk: "${_getRateForRisk(risk)}% (BDT ${NumberFormat("#,##0", "en_US").format(riskPremiums[risk])})",
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
          const SnackBar(content: Text("Invalid input. Please check your values.")),
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
              onChanged: !_selectedRisksMap.values.any((v) => v)
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedZone = value.isEmpty ? null : value;
                        });
                      }
                    }
                  : null,
              labelText: "Zone",
              icon: Icons.location_on_outlined,
            ),
            if (_selectedRisksMap.values.any((v) => v))
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
              _buildCheckboxesList(theme),
              const SizedBox(height: 16),
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

  Widget _buildCheckboxesList(ThemeData theme) {
    return Column(
      children: _allRisks.map((risk) {
        final rate = _getRateForRisk(risk);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(20),
            ),
          ),
          child: CheckboxListTile(
            value: _selectedRisksMap[risk] ?? false,
            onChanged: (value) {
              setState(() {
                _selectedRisksMap[risk] = value ?? false;
              });
            },
            secondary: Icon(
              _getRiskIcon(risk),
              color: theme.colorScheme.primary,
            ),
            title: Text(
              risk,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Rate: $rate%",
              style: TextStyle(
                color: theme.colorScheme.primary.withAlpha(150),
                fontSize: 12,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: theme.colorScheme.primary,
          ),
        );
      }).toList(),
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