import 'package:flutter/material.dart';
import '../models/motor_insurance_model.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class MotorInsuranceCalculator extends StatefulWidget {
  const MotorInsuranceCalculator({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MotorInsuranceCalculatorState createState() =>
      _MotorInsuranceCalculatorState();
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

  void calculatePremium(BuildContext context) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid input. Please check your values.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Motor Insurance Calculator"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC53030), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            CustomTextField(
              controller: _sumController,
              labelText: "Insured Sum (Tk)",
              hintText: "Enter insured amount",
              prefixIcon: Icons.attach_money,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),
            CustomDropdown(
              value: _riskFactor,
              items: ["2.65", "2.45", "2.15"],
              onChanged: (value) => setState(() => _riskFactor = value!),
              labelText: "Risk Factor",
              icon: Icons.trending_up,
            ),
            SizedBox(height: 15),
            CustomDropdown(
              value: _discount,
              items: ["0%", "10%", "20%"],
              onChanged: (value) => setState(() => _discount = value!),
              labelText: "Discount",
              icon: Icons.discount,
            ),
            SizedBox(height: 15),
            CustomDropdown(
              value: _ncb,
              items: ["0%", "30%", "40%", "50%"],
              onChanged: (value) => setState(() => _ncb = value!),
              labelText: "No Claim Bonus (NCB)",
              icon: Icons.money_off,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: _passengersController,
              labelText: "Number of Passengers",
              hintText: "Enter number of passengers",
              prefixIcon: Icons.people,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: _driversController,
              labelText: "Number of Drivers",
              hintText: "Enter number of drivers",
              prefixIcon: Icons.person,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: _engineCapacityController,
              labelText: "Engine Capacity (cc)",
              hintText: "Enter engine capacity",
              prefixIcon: Icons.settings,
              onChanged: (_) => _checkFormValidity(),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 25),
            Center(
              child: ElevatedButton(
                onPressed:
                    _isFormValid ? () => calculatePremium(context) : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Color(0xFFC53030),
                  elevation: 5,
                ),
                child: Text(
                  "Calculate Premium",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
