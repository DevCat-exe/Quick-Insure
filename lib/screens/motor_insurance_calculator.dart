import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/motor_insurance_model.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../services/history_service.dart';

class MotorInsuranceCalculator extends StatefulWidget {
  const MotorInsuranceCalculator({super.key});

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

  String _riskFactor = "2.65";
  String _discount = "0%";
  String _ncb = "0%";
  bool _isFormValid = false;

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _sumController.text.isNotEmpty &&
          _passengersController.text.isNotEmpty &&
          _driversController.text.isNotEmpty &&
          _engineCapacityController.text.isNotEmpty;
    });
  }

  void calculatePremium(BuildContext context) async {
    try {
      double insuredSum = double.parse(_sumController.text);
      double riskFactor = double.parse(_riskFactor);
      double discount = double.parse(_discount.replaceAll("%", ""));
      double ncb = double.parse(_ncb.replaceAll("%", ""));
      int passengers = int.parse(_passengersController.text);
      int drivers = int.parse(_driversController.text);
      int engineCC = int.parse(_engineCapacityController.text);

      Map<String, dynamic> result = MotorInsuranceModel.calculatePremium(
        insuredSum: insuredSum,
        riskFactor: riskFactor,
        discount: discount,
        ncb: ncb,
        passengers: passengers,
        drivers: drivers,
        engineCC: engineCC,
      );

      final historyItem = CalculationHistoryItem(
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        type: 'Motor Insurance',
        totalPremium: result['totalPremium'],
        details: {
          'Insured Sum': insuredSum,
          'Risk Factor': riskFactor,
          'Discount': discount,
          'NCB': ncb,
          'Engine CC': engineCC,
        },
      );
      await HistoryService.saveCalculation(historyItem);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          result['netPremium'],
          result['vat'],
          result['totalPremium'],
          insuredSum: insuredSum,
          riskFactor: riskFactor,
          discount: discount,
          ncb: ncb,
          passengers: passengers,
          drivers: drivers,
          engineCC: engineCC,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid input. Please check your values.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(MotorInsuranceCalculator.displayName),
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
            _buildSectionHeader(theme, "Vehicle Details"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _engineCapacityController,
              labelText: "Engine Capacity (cc)",
              hintText: "e.g. 1500",
              prefixIcon: Icons.settings_input_component,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _sumController,
              labelText: "Insured Sum (Tk)",
              hintText: "e.g. 1,000,000",
              prefixIcon: Icons.account_balance_wallet,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, "Passengers & Drivers"),
            const SizedBox(height: 20),
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
            const SizedBox(height: 32),
            _buildSectionHeader(theme, "Risk & Discounts"),
            const SizedBox(height: 20),
            CustomDropdown(
              value: _riskFactor,
              items: ["2.65", "2.45", "2.15"],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _riskFactor = value);
                }
              },
              labelText: "Risk Factor",
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    value: _discount,
                    items: ["0%", "10%", "20%"],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _discount = value);
                      }
                    },
                    labelText: "Discount",
                    icon: Icons.percent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown(
                    value: _ncb,
                    items: ["0%", "30%", "40%", "50%"],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _ncb = value);
                      }
                    },
                    labelText: "NCB",
                    icon: Icons.stars_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isFormValid ? () => calculatePremium(context) : null,
                child: const Text("Calculate Premium"),
              ),
            ),
          ],
        ),
      ),
    );
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
