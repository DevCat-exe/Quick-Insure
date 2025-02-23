import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultPopup extends StatelessWidget {
  final double netPremium;
  final double vat;
  final double totalPremium;
  final double insuredSum;
  final double riskFactor;
  final double discount;
  final double ncb;
  final int passengers;
  final int drivers;
  final int engineCC;

  const ResultPopup(
    this.netPremium,
    this.vat,
    this.totalPremium, {
    super.key,
    required this.insuredSum,
    required this.riskFactor,
    required this.discount,
    required this.ncb,
    required this.passengers,
    required this.drivers,
    required this.engineCC,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "en_US");

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Insurance Premium Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC53030),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              "Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC53030),
              ),
            ),
            SizedBox(height: 10),
            _buildResultRow(
                "Insured Sum:", "BDT ${formatter.format(insuredSum)}"),
            _buildResultRow("Risk Factor:", "$riskFactor"),
            _buildResultRow("Discount:", "$discount%"),
            _buildResultRow("NCB:", "$ncb%"),
            _buildResultRow("Passengers:", "$passengers"),
            _buildResultRow("Drivers:", "$drivers"),
            _buildResultRow("Engine CC:", "$engineCC cc"),
            SizedBox(height: 20),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 10),
            _buildResultRow(
                "Net Premium:", "BDT ${formatter.format(netPremium)}"),
            SizedBox(height: 10),
            _buildResultRow("VAT (15%):", "BDT ${formatter.format(vat)}"),
            SizedBox(height: 10),
            _buildResultRow(
                "Total Premium:", "BDT ${formatter.format(totalPremium)}"),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC53030),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC53030),
            ),
          ),
        ],
      ),
    );
  }
}
