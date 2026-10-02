import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/motor_insurance_model.dart';
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
  final TextEditingController _sumController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController();
  final TextEditingController _driversController = TextEditingController();
  final TextEditingController _engineCapacityController =
      TextEditingController();
  final TextEditingController _registrationSuffixController =
      TextEditingController();

  static const List<String> _registrationZones = [
    'DHAKA-METRO',
    'CHATTA-METRO',
  ];
  static final RegExp _registrationSuffixPattern = RegExp(
    r'^[A-Z]{2,3}-\d{2}-\d{4}$',
  );

  String _riskFactor = "";
  String _discount = "";
  String _ncb = "";
  String _registrationZone = 'DHAKA-METRO';
  bool _isFormValid = false;

  Map<String, dynamic>? _currentResult;
  double _currentInsuredSum = 0;

  String get _registrationNumber =>
      '$_registrationZone-${_registrationSuffixController.text.trim()}';

  bool get _registrationIsValid =>
      _registrationSuffixController.text.isEmpty ||
      _registrationSuffixPattern.hasMatch(_registrationSuffixController.text);

  @override
  void dispose() {
    _sumController.dispose();
    _passengersController.dispose();
    _driversController.dispose();
    _engineCapacityController.dispose();
    _registrationSuffixController.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    final valid =
        _sumController.text.trim().isNotEmpty &&
        _passengersController.text.trim().isNotEmpty &&
        _driversController.text.trim().isNotEmpty &&
        _engineCapacityController.text.trim().isNotEmpty &&
        _riskFactor.isNotEmpty &&
        _discount.isNotEmpty &&
        _ncb.isNotEmpty &&
        _registrationIsValid;

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

  void _resetForm() {
    setState(() {
      _sumController.clear();
      _passengersController.clear();
      _driversController.clear();
      _engineCapacityController.clear();
      _registrationSuffixController.clear();
      _registrationZone = 'DHAKA-METRO';
      _riskFactor = "";
      _discount = "";
      _ncb = "";
      _currentInsuredSum = 0;
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

  List<ResultSection> _buildSections(
    int engineCC,
    int passengers,
    int drivers,
    double riskFactor,
    double discount,
    double ncb,
    String registrationNumber,
  ) {
    return [
      ResultSection("Vehicle Information", {
        "Engine Capacity": "$engineCC cc",
        "Passengers": "$passengers",
        "Drivers": "$drivers",
        "Seating Capacity": "${passengers + drivers}",
        "Registration Number": registrationNumber,
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
    String registrationNumber,
  ) {
    return {
      'Insured Sum': "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
      'Registration Number': registrationNumber,
      'Engine CC': "$engineCC cc",
      'Seating Capacity': "${passengers + drivers}",
      'Risk Factor': "$riskFactor",
      'Discount': "$discount%",
      'NCB': "$ncb%",
      'Net Premium':
          "BDT ${NumberFormat("#,##0", "en_US").format(result['netPremium'])}",
      'VAT (15%)':
          "BDT ${NumberFormat("#,##0", "en_US").format(result['vat'])}",
    };
  }

  void _calculateAndShowModal() async {
    _recalculateLive();
    if (_currentResult == null) {
      final messenger = scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text("Invalid input. Please check your values."),
        ),
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

      final details = _buildExportDetails(
        insuredSum,
        engineCC,
        passengers,
        drivers,
        riskFactor,
        discount,
        ncb,
        _currentResult!,
        _registrationNumber,
      );

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
          sections: _buildSections(
            engineCC,
            passengers,
            drivers,
            riskFactor,
            discount,
            ncb,
            _registrationNumber,
          ),
          exportDetails: details,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isDesktop = widget.isEmbeddedInDesktop || shortestSide >= 600;

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
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
                left: 24.0,
                right: 24.0,
                top: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  formContent,
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isFormValid ? _calculateAndShowModal : null,
                      child: const Text(
                        "Calculate Premium",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

    final sections = _buildSections(
      engineCC,
      passengers,
      drivers,
      riskFactor,
      discount,
      ncb,
      _registrationNumber,
    );
    final exportDetails = _currentResult != null
        ? _buildExportDetails(
            _currentInsuredSum,
            engineCC,
            passengers,
            drivers,
            riskFactor,
            discount,
            ncb,
            _currentResult!,
            _registrationNumber,
          )
        : <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

  Widget _buildFormContent(ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Vehicle Details"),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _sumController,
          labelText: "Insured Sum (Tk)",
          hintText: "Enter insured sum",
          prefixIcon: Icons.account_balance_wallet,
          onChanged: (_) => _checkFormValidity(),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _engineCapacityController,
          labelText: "Engine Capacity (cc)",
          hintText: "Enter engine capacity",
          prefixIcon: Icons.settings_input_component,
          onChanged: (_) => _checkFormValidity(),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildResponsivePair(
          first: CustomDropdown(
            value: _registrationZone,
            items: _registrationZones,
            onChanged: (value) {
              if (value != null) {
                setState(() => _registrationZone = value);
                _checkFormValidity();
              }
            },
            labelText: "Registration Zone",
            icon: Icons.location_city_outlined,
          ),
          second: CustomTextField(
            controller: _registrationSuffixController,
            labelText: "Registration Number (optional)",
            hintText: "KHA-12-0705",
            prefixIcon: Icons.directions_car_outlined,
            inputFormatters: const [_RegistrationSuffixFormatter()],
            textInputAction: TextInputAction.done,
            onChanged: (_) => _checkFormValidity(),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Passengers & Drivers"),
        const SizedBox(height: 16),
        _buildResponsivePair(
          first: CustomTextField(
            controller: _passengersController,
            labelText: "Passengers",
            hintText: "Enter passenger count",
            prefixIcon: Icons.people_outline,
            onChanged: (_) => _checkFormValidity(),
            keyboardType: TextInputType.number,
          ),
          second: CustomTextField(
            controller: _driversController,
            labelText: "Drivers",
            hintText: "Enter driver count",
            prefixIcon: Icons.person_outline,
            onChanged: (_) => _checkFormValidity(),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Risk & Discounts"),
        const SizedBox(height: 16),
        CustomDropdown(
          value: _riskFactor,
          items: const ["", "2.65", "2.40", "2.15"],
          onChanged: (value) {
            if (value != null) {
              setState(() => _riskFactor = value);
              _checkFormValidity();
            }
          },
          labelText: "Risk Factor (%)",
          icon: Icons.analytics_outlined,
          hintText: "Select a risk factor",
        ),
        const SizedBox(height: 16),
        _buildResponsivePair(
          first: CustomDropdown(
            value: _discount,
            items: const ["", "0%", "10%", "20%", "30%"],
            onChanged: (value) {
              if (value != null) {
                setState(() => _discount = value);
                _checkFormValidity();
              }
            },
            labelText: "Special Discount",
            icon: Icons.percent,
            hintText: "Select discount",
          ),
          second: CustomDropdown(
            value: _ncb,
            items: const ["", "0%", "30%", "40%", "50%"],
            onChanged: (value) {
              if (value != null) {
                setState(() => _ncb = value);
                _checkFormValidity();
              }
            },
            labelText: "NCB (No Claim Bonus)",
            icon: Icons.stars_outlined,
            hintText: "Select NCB",
          ),
        ),
      ],
    );
  }

  Widget _buildResponsivePair({required Widget first, required Widget second}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 520 * textScale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
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

class _RegistrationSuffixFormatter extends TextInputFormatter {
  const _RegistrationSuffixFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formattedText = _format(_normalize(newValue.text));
    final cursorOffset = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length).toInt()
        : newValue.text.length;
    final formattedCursor = _format(
      _normalize(newValue.text.substring(0, cursorOffset)),
    ).length.clamp(0, formattedText.length).toInt();

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedCursor),
      composing: TextRange.empty,
    );
  }

  String _normalize(String value) {
    final output = StringBuffer();
    var letterCount = 0;
    var digitCount = 0;
    var digitsStarted = false;

    for (final codeUnit in value.toUpperCase().codeUnits) {
      if (!digitsStarted &&
          letterCount < 3 &&
          codeUnit >= 65 &&
          codeUnit <= 90) {
        output.writeCharCode(codeUnit);
        letterCount++;
      } else if (letterCount >= 2 &&
          digitCount < 6 &&
          codeUnit >= 48 &&
          codeUnit <= 57) {
        digitsStarted = true;
        output.writeCharCode(codeUnit);
        digitCount++;
      }
    }

    return output.toString();
  }

  String _format(String compactValue) {
    var classLength = 0;
    while (classLength < compactValue.length) {
      final codeUnit = compactValue.codeUnitAt(classLength);
      if (codeUnit < 65 || codeUnit > 90) break;
      classLength++;
    }
    if (classLength < 2) return compactValue;

    final output = StringBuffer();
    for (var index = 0; index < compactValue.length; index++) {
      if (index == classLength || index == classLength + 2) {
        output.write('-');
      }
      output.write(compactValue[index]);
    }
    return output.toString();
  }
}
