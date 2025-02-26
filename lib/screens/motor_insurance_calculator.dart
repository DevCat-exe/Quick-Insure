import 'package:flutter/material.dart';
import '../models/motor_insurance_model.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class MotorInsuranceCalculator extends StatefulWidget {
  const MotorInsuranceCalculator({super.key});

  @override
  State<MotorInsuranceCalculator> createState() =>
      _MotorInsuranceCalculatorState();
}

class _MotorInsuranceCalculatorState extends State<MotorInsuranceCalculator> {
  final _formKey = GlobalKey<FormState>();
  final _sumController = TextEditingController();
  final _passengersController = TextEditingController();
  final _driversController = TextEditingController();
  final _engineController = TextEditingController();

  String _riskFactor = "2.65";
  String _discount = "0%";
  String _ncb = "0%";

  void _calculatePremium() {
    if (_formKey.currentState?.validate() ?? false) {
      final result = MotorInsuranceModel.calculatePremium(
        insuredSum: double.parse(_sumController.text),
        riskFactor: double.parse(_riskFactor),
        discount: double.parse(_discount.replaceAll("%", "")),
        ncb: double.parse(_ncb.replaceAll("%", "")),
        passengers: int.parse(_passengersController.text),
        drivers: int.parse(_driversController.text),
        engineCC: int.parse(_engineController.text),
      );

      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          netPremium: result['netPremium'],
          vat: result['vat'],
          totalPremium: result['totalPremium'],
          insuredSum: double.parse(_sumController.text),
          riskFactor: double.parse(_riskFactor),
          discount: double.parse(_discount.replaceAll("%", "")),
          ncb: double.parse(_ncb.replaceAll("%", "")),
          passengers: int.parse(_passengersController.text),
          drivers: int.parse(_driversController.text),
          engineCC: int.parse(_engineController.text),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sumController.dispose();
    _passengersController.dispose();
    _driversController.dispose();
    _engineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Motor Insurance Calculator"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _sumController,
                label: "Insured Sum (Tk)",
                icon: Icons.attach_money,
                validator: (value) =>
                    value?.isEmpty ?? true ? "Required field" : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _riskFactor,
                options: const ["2.65", "2.45", "2.15"],
                label: "Risk Factor",
                icon: Icons.trending_up,
                onChanged: (value) => setState(() => _riskFactor = value!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown(
                      value: _discount,
                      options: const ["0%", "10%", "20%"],
                      label: "Discount",
                      icon: Icons.discount,
                      onChanged: (value) => setState(() => _discount = value!),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomDropdown(
                      value: _ncb,
                      options: const ["0%", "30%", "40%", "50%"],
                      label: "No Claim Bonus",
                      icon: Icons.verified_user,
                      onChanged: (value) => setState(() => _ncb = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _passengersController,
                      label: "Passengers",
                      icon: Icons.people_alt,
                      validator: (value) =>
                          value?.isEmpty ?? true ? "Required field" : null,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomTextField(
                      controller: _driversController,
                      label: "Drivers",
                      icon: Icons.person,
                      validator: (value) =>
                          value?.isEmpty ?? true ? "Required field" : null,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _engineController,
                label: "Engine CC",
                icon: Icons.engineering,
                validator: (value) =>
                    value?.isEmpty ?? true ? "Required field" : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _calculatePremium,
                child: const Text("Calculate Premium"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
