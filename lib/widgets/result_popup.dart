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
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 480;
    
    final double headerFontSize = isSmallScreen ? 20 : 24;

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
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 20 : 28, 
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
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
                      Icon(Icons.receipt_long,
                          color: Colors.white, size: isSmallScreen ? 40 : 48),
                      SizedBox(height: isSmallScreen ? 10 : 16),
                      Text(
                        "Calculation Details",
                        style: TextStyle(
                          fontSize: headerFontSize,
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
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _buildSectionHeader(theme, "Vehicle Information"),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildResultRow("Engine CC:", "$engineCC cc", theme, isSmallScreen: isSmallScreen),
                      _buildResultRow("Passengers:", "$passengers", theme, isSmallScreen: isSmallScreen),
                      _buildResultRow("Drivers:", "$drivers", theme, isSmallScreen: isSmallScreen),
                      _buildResultRow("Seating Capacity:", "${passengers + drivers}", theme, isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildSectionHeader(theme, "Risk & Discounts"),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                       _buildResultRow("Risk Factor:", "$riskFactor", theme, isSmallScreen: isSmallScreen),
                       _buildResultRow("Discount:", "$discount%", theme, isSmallScreen: isSmallScreen),
                       _buildResultRow("NCB:", "$ncb%", theme, isSmallScreen: isSmallScreen),
                       SizedBox(height: isSmallScreen ? 16 : 24),
                        Divider(color: theme.dividerColor.withAlpha(40)),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        _buildPremiumRow(
                            "Insured Sum",
                            "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
                            theme,
                            isBold: false,
                            isSmallScreen: isSmallScreen),
                        _buildPremiumRow(
                            "Net Premium",
                            "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}",
                            theme,
                            isBold: false,
                            isSmallScreen: isSmallScreen),
                        _buildPremiumRow(
                            "VAT (15%)",
                            "BDT ${NumberFormat("#,##0", "en_US").format(vat)}",
                            theme,
                            isBold: false,
                            isSmallScreen: isSmallScreen),
                       const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16, 
                              horizontal: isSmallScreen ? 14 : 20),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accent.withAlpha(40)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Total Premium",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}",
                                style: TextStyle(
                                  fontSize: isMediumScreen ? 18 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: isSmallScreen ? 20 : 32),
                      Row(
                         children: [
                           Expanded(
                             child: OutlinedButton.icon(
                               label: const Text("Export PDF"),
                               icon: const Icon(Icons.picture_as_pdf, size: 18),
                               style: OutlinedButton.styleFrom(
                                 padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 20),
                                 side: BorderSide(
                                     color: theme.colorScheme.primary),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(16),
                                 ),
                               ),
                               onPressed: () => ExportService.exportToPdf(
                                 title: "Motor Insurance",
                                 totalPremium: totalPremium,
                                 details: {
                                   "Insured Sum": "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
                                   "Engine CC": "$engineCC cc",
                                   "Seating Capacity": "${passengers + drivers}",
                                   "Risk Factor": "$riskFactor",
                                   "Discount": "$discount%",
                                   "NCB": "$ncb%",
                                   "Net Premium": "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}",
                                   "VAT (15%)": "BDT ${NumberFormat("#,##0", "en_US").format(vat)}",
                                 },
                               ),
                             ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: ElevatedButton(
                               style: ElevatedButton.styleFrom(
                                 padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 20),
                               ),
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

  Widget _buildResultRow(String label, String value, ThemeData theme, {required bool isSmallScreen}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: isSmallScreen ? 13 : null)),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.secondary,
                fontSize: isSmallScreen ? 13 : null,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRow(String label, String value, ThemeData theme,
      {required bool isBold, bool highlight = false, required bool isSmallScreen}) {
    final double labelFontSize = highlight 
        ? (isSmallScreen ? 16 : 18) 
        : (isSmallScreen ? 14 : 16);
    final double valueFontSize = highlight 
        ? (isSmallScreen ? 18 : 20) 
        : (isSmallScreen ? 14 : 16);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: labelFontSize,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
                color: highlight ? theme.colorScheme.primary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w900,
                color: highlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
