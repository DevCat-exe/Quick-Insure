import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent, // Background handled by Container
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: screenWidth > 600 ? 500 : screenWidth * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.dialogTheme.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 100 : 30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "Calculation Details",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(theme, "Vehicle Information"),
                      const SizedBox(height: 12),
                      _buildResultRow("Engine CC:", "$engineCC cc", theme),
                      _buildResultRow("Passengers:", "$passengers", theme),
                      _buildResultRow("Drivers:", "$drivers", theme),
                      const SizedBox(height: 24),
                      _buildSectionHeader(theme, "Risk & Discounts"),
                      const SizedBox(height: 12),
                      _buildResultRow("Risk Factor:", "$riskFactor", theme),
                      _buildResultRow("Discount:", "$discount%", theme),
                      _buildResultRow("NCB:", "$ncb%", theme),
                      const SizedBox(height: 24),
                      Divider(color: theme.dividerColor.withAlpha(40)),
                      const SizedBox(height: 24),
                      _buildPremiumRow(
                          "Insured Sum",
                          "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
                          theme,
                          isBold: false),
                      _buildPremiumRow(
                          "Net Premium",
                          "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}",
                          theme,
                          isBold: false),
                      _buildPremiumRow(
                          "VAT (15%)",
                          "BDT ${NumberFormat("#,##0", "en_US").format(vat)}",
                          theme,
                          isBold: false),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accent.withAlpha(40)),
                        ),
                        child: _buildPremiumRow(
                          "Total Premium",
                          "BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}",
                          theme,
                          isBold: true,
                          highlight: true,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ExportService.exportToPdf(
                                title: "Motor Insurance",
                                totalPremium: totalPremium,
                                details: {
                                  "Insured Sum": insuredSum,
                                  "Net Premium": netPremium,
                                  "VAT (15%)": vat,
                                  "Engine CC": engineCC,
                                  "Passengers": passengers,
                                  "Drivers": drivers,
                                  "Risk Factor": riskFactor,
                                  "Discount": "$discount%",
                                  "NCB": "$ncb%",
                                },
                              ),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("Export PDF"),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                side: BorderSide(
                                    color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Done"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary.withAlpha(180),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildResultRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRow(String label, String value, ThemeData theme,
      {required bool isBold, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: highlight ? 18 : 16,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 20 : 16,
              fontWeight: FontWeight.w900,
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
