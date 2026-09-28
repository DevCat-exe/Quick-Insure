import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fire_insurance_model.dart';
import '../models/calculator_registry.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/desktop_calculation_summary_card.dart';
import '../services/history_service.dart';
import '../main.dart';

class FireInsuranceCalculator extends StatefulWidget {
  final bool isEmbeddedInDesktop;
  const FireInsuranceCalculator({super.key, this.isEmbeddedInDesktop = false});

  @override
  State<FireInsuranceCalculator> createState() =>
      _FireInsuranceCalculatorState();

  static String get displayName => "Fire Insurance";
}

class _FireInsuranceCalculatorState extends State<FireInsuranceCalculator> {
  final TextEditingController _sumController = TextEditingController(text: "20000000");
  String? _selectedZone = 'Dhaka';
  final Map<String, bool> _selectedRisksMap = {
    'Fire': true,
    'Earthquake': true,
  };

  static const List<String> _zones = ['Dhaka', 'Chittagong', 'Sylhet'];
  static const List<String> _allRisks = [
    'Fire',
    'Earthquake',
    'Cyclone',
    'Flood'
  ];

  Map<String, dynamic>? _currentResult;
  double _currentInsuredSum = 20000000;

  @override
  void initState() {
    super.initState();
    _recalculateLive();
  }

  bool get _isFormValid =>
      _sumController.text.trim().isNotEmpty &&
      _selectedZone != null &&
      _selectedRisksMap.values.any((selected) => selected);

  List<String> get _selectedRisks =>
      _allRisks.where((r) => _selectedRisksMap[r] == true).toList();

  double _getRateForRisk(String risk) {
    if (_selectedZone == null) return 0.0;
    return FireInsuranceModel.ratesTable[_selectedZone]?[risk] ?? 0.0;
  }

  void _applyPreset(CalculatorPreset preset) {
    setState(() {
      _sumController.text = preset.values['sum'] ?? '';
      _selectedZone = preset.values['zone'];
      _selectedRisksMap.clear();
      final List<dynamic> risks = preset.values['risks'] ?? [];
      for (final r in _allRisks) {
        _selectedRisksMap[r] = risks.contains(r);
      }
    });
    _recalculateLive();
  }

  void _resetForm() {
    setState(() {
      _sumController.clear();
      _selectedZone = null;
      _selectedRisksMap.clear();
      _currentResult = null;
    });
  }

  void _recalculateLive() {
    if (!_isFormValid) {
      setState(() => _currentResult = null);
      return;
    }
    try {
      final cleanSum = _sumController.text.replaceAll(',', '').trim();
      double insuredSum = double.parse(cleanSum);
      final selectedRisks = _selectedRisks;

      final res = FireInsuranceModel.calculatePremium(
        insuredSum: insuredSum,
        zone: _selectedZone!,
        selectedRisks: selectedRisks,
      );

      setState(() {
        _currentInsuredSum = insuredSum;
        _currentResult = res;
      });
    } catch (_) {
      setState(() => _currentResult = null);
    }
  }

  List<ResultSection> _buildSections(List<String> selectedRisks, Map<String, double> riskPremiums, dynamic totalRate) {
    return [
      ResultSection("Property Details", {
        "Zone": _selectedZone ?? 'N/A',
      }),
      ResultSection("Selected Risks", {
        for (var risk in selectedRisks)
          risk: "${_getRateForRisk(risk)}% (BDT ${NumberFormat("#,##0", "en_US").format(riskPremiums[risk] ?? 0)})",
      }),
      ResultSection("Summary", {
        "Total Rate": "$totalRate%",
      }),
    ];
  }

  Map<String, dynamic> _buildExportDetails(
    double insuredSum,
    List<String> selectedRisks,
    Map<String, double> riskPremiums,
    Map<String, dynamic> result,
  ) {
    final riskBreakdown = selectedRisks
        .map((r) => "$r (${_getRateForRisk(r)}%) - BDT ${NumberFormat("#,##0", "en_US").format(riskPremiums[r] ?? 0)}")
        .join(', ');

    return {
      'Insured Sum': "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
      'Zone': _selectedZone ?? '',
      'Selected Risks': riskBreakdown,
      'Total Rate': "${result['totalRate']}%",
      'Net Premium': "BDT ${NumberFormat("#,##0", "en_US").format(result['netPremium'])}",
      'VAT (15%)': "BDT ${NumberFormat("#,##0", "en_US").format(result['vat'])}",
    };
  }

  void _calculateAndShowModal() async {
    _recalculateLive();
    if (_currentResult == null) {
      final messenger = scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        const SnackBar(content: Text("Invalid input. Please check your values.")),
      );
      return;
    }

    try {
      final cleanSum = _sumController.text.replaceAll(',', '').trim();
      double insuredSum = double.parse(cleanSum);
      final selectedRisks = _selectedRisks;
      final riskPremiums = (_currentResult!['riskPremiums'] as Map<String, double>?) ?? {};

      final details = _buildExportDetails(insuredSum, selectedRisks, riskPremiums, _currentResult!);

      final historyItem = CalculationHistoryItem(
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        type: 'Fire Insurance',
        totalPremium: _currentResult!['totalPremium'],
        details: details,
      );
      await HistoryService.saveCalculation(historyItem);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          title: "Fire Insurance",
          netPremium: _currentResult!['netPremium'],
          vat: _currentResult!['vat'],
          totalPremium: _currentResult!['totalPremium'],
          insuredSum: insuredSum,
          sections: _buildSections(selectedRisks, riskPremiums, _currentResult!['totalRate']),
          exportDetails: details,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = widget.isEmbeddedInDesktop || screenWidth >= 850;

    final formContent = _buildFormContent(theme, isDesktop);

    if (widget.isEmbeddedInDesktop) {
      return _buildDesktopLayout(theme, formContent);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(FireInsuranceCalculator.displayName),
        actions: [
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Reset Form (Esc)",
              onPressed: _resetForm,
            ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(theme, formContent)
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24.0,
                right: 24.0,
                top: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetsBar(theme),
                  const SizedBox(height: 24),
                  formContent,
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _calculateAndShowModal : null,
                      child: const Text("Calculate Premium"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Widget formContent) {
    final selectedRisks = _selectedRisks;
    final riskPremiums = (_currentResult?['riskPremiums'] as Map<String, double>?) ?? {};
    final totalRate = _currentResult?['totalRate'] ?? 0.0;

    final sections = _buildSections(selectedRisks, riskPremiums, totalRate);
    final exportDetails = _currentResult != null
        ? _buildExportDetails(_currentInsuredSum, selectedRisks, riskPremiums, _currentResult!)
        : <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPresetsBar(theme),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Column
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.black.withAlpha(15),
                        ),
                      ),
                      child: formContent,
                    ),
                  ),
                  const SizedBox(width: 28),
                  // Summary Column
                  Expanded(
                    flex: 5,
                    child: DesktopCalculationSummaryCard(
                      title: "Fire Insurance",
                      netPremium: _currentResult?['netPremium'] ?? 0.0,
                      vat: _currentResult?['vat'] ?? 0.0,
                      totalPremium: _currentResult?['totalPremium'] ?? 0.0,
                      insuredSum: _currentInsuredSum,
                      sections: sections,
                      exportDetails: exportDetails,
                      isValid: _isFormValid && _currentResult != null,
                      onReset: _resetForm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsBar(ThemeData theme) {
    final presets = CalculatorRegistry.firePresets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              "QUICK PRESETS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  avatar: Icon(p.icon, size: 16, color: theme.colorScheme.primary),
                  label: Text(p.label),
                  tooltip: p.description,
                  onPressed: () => _applyPreset(p),
                  backgroundColor: theme.colorScheme.primary.withAlpha(15),
                  side: BorderSide(color: theme.colorScheme.primary.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Property Details"),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _sumController,
          labelText: "Sum Insured (Tk)",
          hintText: "e.g. 20,000,000",
          prefixIcon: Icons.account_balance_wallet,
          onChanged: (_) {
            setState(() {});
            _recalculateLive();
          },
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Zone & Coverage"),
        const SizedBox(height: 16),
        CustomDropdown(
          value: _selectedZone ?? '',
          items: ['', ..._zones],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedZone = value.isEmpty ? null : value;
              });
              _recalculateLive();
            }
          },
          labelText: "Territory / Zone",
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        if (_selectedZone != null) ...[
          _buildCheckboxesList(theme),
        ],
      ],
    );
  }

  Widget _buildCheckboxesList(ThemeData theme) {
    return Column(
      children: _allRisks.map((risk) {
        final rate = _getRateForRisk(risk);
        final isChecked = _selectedRisksMap[risk] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isChecked
                ? theme.colorScheme.primary.withAlpha(12)
                : theme.colorScheme.primary.withAlpha(5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isChecked
                  ? theme.colorScheme.primary.withAlpha(60)
                  : theme.colorScheme.primary.withAlpha(20),
            ),
          ),
          child: CheckboxListTile(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                _selectedRisksMap[risk] = value ?? false;
              });
              _recalculateLive();
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
                color: theme.colorScheme.primary.withAlpha(170),
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
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}