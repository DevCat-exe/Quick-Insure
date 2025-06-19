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
    final theme = Theme.of(context);
    final cardColor = Theme.of(context).dialogTheme.backgroundColor ??
        theme.colorScheme.surface;
    final accent = theme.colorScheme.primary;
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        width: 440,
        child: SingleChildScrollView(
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
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10),
                _buildResultRow(
                    "Insured Sum:",
                    "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
                    theme),
                _buildResultRow("Risk Factor:", "$riskFactor", theme),
                _buildResultRow("Discount:", "$discount%", theme),
                _buildResultRow("NCB:", "$ncb%", theme),
                _buildResultRow("Passengers:", "$passengers", theme),
                _buildResultRow("Drivers:", "$drivers", theme),
                _buildResultRow("Engine CC:", "$engineCC cc", theme),
                SizedBox(height: 20),
                Divider(
                    color: theme.dividerColor.withAlpha((0.2 * 255).toInt())),
                SizedBox(height: 10),
                _buildResultRow(
                    "Net Premium:",
                    "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}",
                    theme),
                SizedBox(height: 10),
                _buildResultRow("VAT (15%):",
                    "BDT ${NumberFormat("#,##0", "en_US").format(vat)}", theme),
                SizedBox(height: 10),
                _buildResultRow(
                    "Total Premium:",
                    "BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}",
                    theme),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
