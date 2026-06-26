import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../services/export_service.dart';
import '../widgets/result_popup.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<CalculationHistoryItem>> _historyFuture;

  double _parseBDT(String value) {
    return double.tryParse(value.replaceAll('BDT', '').replaceAll(',', '').trim()) ?? 0;
  }


  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = HistoryService.getHistory();
    });
  }

  void _showHistoryItemPopup(CalculationHistoryItem item) {
    final details = item.details;
    final insuredSum = _parseBDT(details['Insured Sum']?.toString() ?? '0');
    final netPremium = _parseBDT(details['Net Premium']?.toString() ?? '0');
    final vat = _parseBDT(details['VAT (15%)']?.toString() ?? '0');
    
    List<ResultSection> sections = [];
    
    if (item.type == 'Motor Insurance') {
      sections = [
        ResultSection("Vehicle Details", {
          "Engine CC": details['Engine CC']?.toString() ?? '',
          "Seating Capacity": details['Seating Capacity']?.toString() ?? '',
        }),
        ResultSection("Risk & Discounts", {
          "Risk Factor": details['Risk Factor']?.toString() ?? '',
          "Discount": details['Discount']?.toString() ?? '',
          "NCB": details['NCB']?.toString() ?? '',
        }),
      ];
} else if (item.type == 'Fire Insurance') {
       final zone = details['Zone']?.toString() ?? '';
       final risksStr = details['Selected Risks']?.toString() ?? '';
       final riskEntries = <String, String>{};
       for (final part in risksStr.split(', ')) {
         final match = RegExp(r'^(.+?) \((\d+\.?\d*)% - BDT (.+?\d)\)$').firstMatch(part);
         if (match != null) {
           riskEntries[match.group(1)!] = "${match.group(2)}% (BDT ${match.group(3)})";
         }
       }
       sections = [
         ResultSection("Property Details", {
           "Zone": zone,
         }),
         if (riskEntries.isNotEmpty)
           ResultSection("Selected Risks", riskEntries),
       ];
    } else {
      sections = [
        ResultSection("Details", details.map((k, v) => MapEntry(k, v.toString()))),
      ];
    }

    showDialog(
      context: context,
      builder: (context) => ResultPopup(
        title: item.type,
        netPremium: netPremium,
        vat: vat,
        totalPremium: item.totalPremium,
        insuredSum: insuredSum,
        sections: sections,
        exportDetails: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculation History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear All",
            onPressed: () => _confirmClearHistory(),
          ),
        ],
      ),
      body: FutureBuilder<List<CalculationHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu,
                      size: 80, color: theme.colorScheme.primary.withAlpha(50)),
                  const SizedBox(height: 16),
                  Text(
                    "No history found",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _showHistoryItemPopup(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      item.date,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(120),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Total Premium",
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "BDT ${NumberFormat("#,##0", "en_US").format(item.totalPremium)}",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            color: theme.colorScheme.primary,
                            iconSize: 24,
                            tooltip: "Export PDF",
                            onPressed: () => ExportService.exportToPdf(
                              title: item.type,
                              totalPremium: item.totalPremium,
                              details: item.details,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text(
            "Are you sure you want to clear all calculation history? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await HistoryService.clearHistory();
              if (mounted) {
                nav.pop();
                _refreshHistory();
              }
            },
            child: Text("Clear All",
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
