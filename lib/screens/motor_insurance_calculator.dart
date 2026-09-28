import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/motor_insurance_model.dart';
import '../models/calculator_registry.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/desktop_calculation_summary_card.dart';
import '../services/history_service.dart';
import '../main.dart';

class MotorInsuranceCalculator extends StatefulWidget {
  final bool isEmbeddedInDesktop;
  const MotorInsuranceCalculator({super.key, this.isEmbeddedInDesktop = false});

  @override
  State<MotorInsuranceCalculator> createState() =>
      _MotorInsuranceCalculatorState();

  static String get displayName => "Motor Insurance";
}

class _MotorInsuranceCalculatorState extends State<MotorInsuranceCalculator> {
  final TextEditingController _sumController = TextEditingController(text: "1500000");
  final TextEditingController _passengersController = TextEditingController(text: "4");
  final TextEditingController _driversController = TextEditingController(text: "1");
  final TextEditingController _engineCapacityController = TextEditingController(text: "1500");

  String _riskFactor = "2.65";
  String _discount = "0%";
  String _ncb = "0%";
  bool _isFormValid = true;

  // Live calculation results
  Map<String, dynamic>? _currentResult;
  double _currentInsuredSum = 1500000;

  @override
  void initState() {
    super.initState();
    _recalculateLive();
  }

  void _checkFormValidity() {
    final valid = _sumController.text.trim().isNotEmpty &&
        _passengersController.text.trim().isNotEmpty &&
        _driversController.text.trim().isNotEmpty &&
        _engineCapacityController.text.trim().isNotEmpty;

    if (valid != _isFormValid) {
      setState(() {
        _isFormValid = valid;
      });
    }
    if (valid) {
      _recalculateLive();
    } else {
      setState(() {
        _currentResult = null;
      });
    }
  }

  void _applyPreset(CalculatorPreset preset) {
    setState(() {
      _sumController.text = preset.values['sum'] ?? '';
      _engineCapacityController.text = preset.values['cc'] ?? '';
      _passengersController.text = preset.values['passengers'] ?? '';
      _driversController.text = preset.values['drivers'] ?? '';
      _riskFactor = preset.values['risk'] ?? _riskFactor;
      _discount = preset.values['discount'] ?? _discount;
      _ncb = preset.values['ncb'] ?? _ncb;
    });
    _checkFormValidity();
  }

  void _resetForm() {
    setState(() {
      _sumController.clear();
      _passengersController.text = "0";
      _driversController.text = "1";
      _engineCapacityController.clear();
      _riskFactor = "2.65";
      _discount = "0%";
      _ncb = "0%";
      _isFormValid = false;
      _currentResult = null;
    });
  }

  void _recalculateLive() {
    try {
      final cleanSum = _sumController.text.replaceAll(',', '').trim();
      double insuredSum = double.parse(cleanSum);
      double riskFactor = double.parse(_riskFactor);
      double discount = double.parse(_discount.replaceAll("%", ""));
      double ncb = double.parse(_ncb.replaceAll("%", ""));
      int passengers = int.parse(_passengersController.text.trim());
      int drivers = int.parse(_driversController.text.trim());
      int engineCC = int.parse(_engineCapacityController.text.trim());

      final res = MotorInsuranceModel.calculatePremium(
        insuredSum: insuredSum,
        riskFactor: riskFactor,
        discount: discount,
        ncb: ncb,
        passengers: passengers,
        drivers: drivers,
        engineCC: engineCC,
      );

      setState(() {
        _currentInsuredSum = insuredSum;
        _currentResult = res;
      });
    } catch (_) {
      setState(() {
        _currentResult = null;
      });
    }
  }

  List<ResultSection> _buildSections(int engineCC, int passengers, int drivers, double riskFactor, double discount, double ncb) {
    return [
      ResultSection("Vehicle Information", {
        "Engine Capacity": "$engineCC cc",
        "Passengers": "$passengers",
        "Drivers": "$drivers",
        "Seating Capacity": "${passengers + drivers}",
      }),
      ResultSection("Risk & Discounts", {
        "Risk Factor": "$riskFactor",
        "Discount": "$discount%",
        "NCB": "$ncb%",
      }),
    ];
  }

  Map<String, dynamic> _buildExportDetails(
    double insuredSum,
    int engineCC,
    int passengers,
    int drivers,
    double riskFactor,
    double discount,
    double ncb,
    Map<String, dynamic> result,
  ) {
    return {
      'Insured Sum': "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
      'Engine CC': "$engineCC cc",
      'Seating Capacity': "${passengers + drivers}",
      'Risk Factor': "$riskFactor",
      'Discount': "$discount%",
      'NCB': "$ncb%",
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
      double riskFactor = double.parse(_riskFactor);
      double discount = double.parse(_discount.replaceAll("%", ""));
      double ncb = double.parse(_ncb.replaceAll("%", ""));
      int passengers = int.parse(_passengersController.text.trim());
      int drivers = int.parse(_driversController.text.trim());
      int engineCC = int.parse(_engineCapacityController.text.trim());

      final details = _buildExportDetails(insuredSum, engineCC, passengers, drivers, riskFactor, discount, ncb, _currentResult!);

      final historyItem = CalculationHistoryItem(
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        type: 'Motor Insurance',
        totalPremium: _currentResult!['totalPremium'],
        details: details,
      );
      await HistoryService.saveCalculation(historyItem);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          title: "Motor Insurance",
          netPremium: _currentResult!['netPremium'],
          vat: _currentResult!['vat'],
          totalPremium: _currentResult!['totalPremium'],
          insuredSum: insuredSum,
          sections: _buildSections(engineCC, passengers, drivers, riskFactor, discount, ncb),
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
        title: Text(MotorInsuranceCalculator.displayName),
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
    int engineCC = int.tryParse(_engineCapacityController.text.trim()) ?? 1500;
    int passengers = int.tryParse(_passengersController.text.trim()) ?? 4;
    int drivers = int.tryParse(_driversController.text.trim()) ?? 1;
    double riskFactor = double.tryParse(_riskFactor) ?? 2.65;
    double discount = double.tryParse(_discount.replaceAll('%', '')) ?? 0;
    double ncb = double.tryParse(_ncb.replaceAll('%', '')) ?? 0;

    final sections = _buildSections(engineCC, passengers, drivers, riskFactor, discount, ncb);
    final exportDetails = _currentResult != null
        ? _buildExportDetails(_currentInsuredSum, engineCC, passengers, drivers, riskFactor, discount, ncb, _currentResult!)
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
                  // Summary & Receipt Column
                  Expanded(
                    flex: 5,
                    child: DesktopCalculationSummaryCard(
                      title: "Motor Insurance",
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
    final presets = CalculatorRegistry.motorPresets;
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
        _buildSectionHeader(theme, "Vehicle Details"),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _sumController,
          labelText: "Insured Sum (Tk)",
          hintText: "e.g. 1,500,000",
          prefixIcon: Icons.account_balance_wallet,
          onChanged: (_) => _checkFormValidity(),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _engineCapacityController,
          labelText: "Engine Capacity (cc)",
          hintText: "e.g. 1500",
          prefixIcon: Icons.settings_input_component,
          onChanged: (_) => _checkFormValidity(),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Passengers & Drivers"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _passengersController,
                labelText: "Passengers",
                hintText: "0",
                prefixIcon: Icons.people_outline,
                onChanged: (_) => _checkFormValidity(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _driversController,
                labelText: "Drivers",
                hintText: "1",
                prefixIcon: Icons.person_outline,
                onChanged: (_) => _checkFormValidity(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Risk & Discounts"),
        const SizedBox(height: 16),
        CustomDropdown(
          value: _riskFactor,
          items: const ["2.65", "2.40", "2.15"],
          onChanged: (value) {
            if (value != null) {
              setState(() => _riskFactor = value);
              _checkFormValidity();
            }
          },
          labelText: "Risk Factor (%)",
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                value: _discount,
                items: const ["0%", "10%", "20%", "30%"],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _discount = value);
                    _checkFormValidity();
                  }
                },
                labelText: "Special Discount",
                icon: Icons.percent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown(
                value: _ncb,
                items: const ["0%", "30%", "40%", "50%"],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _ncb = value);
                    _checkFormValidity();
                  }
                },
                labelText: "NCB (No Claim Bonus)",
                icon: Icons.stars_outlined,
              ),
            ),
          ],
        ),
      ],
    );
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
