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

  const ResultPopup({
    super.key,
    required this.netPremium,
    required this.vat,
    required this.totalPremium,
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
    final theme = Theme.of(context);
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Calculation Results", style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            _buildResultRow("Insured Sum:", formatter.format(insuredSum)),
            _buildResultRow("Risk Factor:", "$riskFactor%"),
            _buildResultRow("Discount:", "$discount%"),
            _buildResultRow("NCB:", "$ncb%"),
            _buildResultRow("Passengers:", passengers.toString()),
            _buildResultRow("Drivers:", drivers.toString()),
            _buildResultRow("Engine CC:", "$engineCC cc"),
            const Divider(height: 40),
            _buildResultRow("Net Premium:", formatter.format(netPremium)),
            _buildResultRow("VAT (15%):", formatter.format(vat)),
            _buildResultRow("Total Premium:", formatter.format(totalPremium)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _copyToClipboard(context, totalPremium),
              child: const Text("Copy Total Premium"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, double value) {
    final formattedValue = NumberFormat("#,##0.00", "en_US").format(value);
    Clipboard.setData(ClipboardData(text: "BDT $formattedValue")).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Copied to clipboard"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }
}
