import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import '../services/history_service.dart';
import '../widgets/result_popup.dart';

class DesktopCalculationSummaryCard extends StatelessWidget {
  final String title;
  final double netPremium;
  final double vat;
  final double totalPremium;
  final double insuredSum;
  final List<ResultSection> sections;
  final Map<String, dynamic> exportDetails;
  final bool isValid;
  final VoidCallback? onReset;
  final VoidCallback? onSaveSuccess;

  const DesktopCalculationSummaryCard({
    super.key,
    required this.title,
    required this.netPremium,
    required this.vat,
    required this.totalPremium,
    required this.insuredSum,
    required this.sections,
    required this.exportDetails,
    required this.isValid,
    this.onReset,
    this.onSaveSuccess,
  });

  Future<void> _saveToHistory(BuildContext context) async {
    if (!isValid || totalPremium <= 0) return;
    final historyItem = CalculationHistoryItem(
      date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      type: title,
      totalPremium: totalPremium,
      details: exportDetails,
    );
    await HistoryService.saveCalculation(historyItem);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text("Calculation saved to history!"),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    onSaveSuccess?.call();
  }

  void _copySummary(BuildContext context) {
    if (!isValid) return;
    final buffer = StringBuffer();
    buffer.writeln("=== QUICK INSURE: $title ===");
    buffer.writeln("Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}");
    buffer.writeln("Sum Insured: BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}");
    buffer.writeln("Net Premium: BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}");
    buffer.writeln("VAT (15%): BDT ${NumberFormat("#,##0", "en_US").format(vat)}");
    buffer.writeln("TOTAL PREMIUM: BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}");
    for (final sec in sections) {
      buffer.writeln("\n[${sec.title}]");
      sec.items.forEach((k, v) => buffer.writeln("$k: $v"));
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Summary copied to clipboard!"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    if (!isValid) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calculate_outlined, size: 48, color: primary),
              ),
              const SizedBox(height: 20),
              Text(
                "Live Summary",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fill in the required parameters on the left to see the instant calculation breakdown here.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withAlpha(220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Colors.amberAccent, size: 14),
                                  SizedBox(width: 2),
                                  Text(
                                    "LIVE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Official Premium Estimate",
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                    tooltip: "Copy Summary",
                    onPressed: () => _copySummary(context),
                  ),
                ],
              ),
            ),

            // Content body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Grand Total Block
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withAlpha(45)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOTAL PAYABLE",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Incl. 15% Govt. VAT",
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "BDT ${NumberFormat("#,##0", "en_US").format(totalPremium)}",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Core figures row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          theme,
                          "Insured Sum",
                          "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}",
                          Icons.shield_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          theme,
                          "Net Premium",
                          "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}",
                          Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          theme,
                          "VAT (15%)",
                          "BDT ${NumberFormat("#,##0", "en_US").format(vat)}",
                          Icons.account_balance_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Breakdown Sections
                  for (final section in sections) ...[
                    Text(
                      section.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: primary.withAlpha(200),
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        children: section.items.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                                  ),
                                ),
                                Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text("Export PDF"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => ExportService.exportToPdf(
                            title: title,
                            totalPremium: totalPremium,
                            details: exportDetails,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          label: const Text("Save"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _saveToHistory(context),
                        ),
                      ),
                      if (onReset != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: "Reset Form (Esc)",
                          icon: const Icon(Icons.refresh),
                          onPressed: onReset,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.dividerColor.withAlpha(50)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(ThemeData theme, String label, String value, IconData icon) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
