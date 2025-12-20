import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../services/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<CalculationHistoryItem>> _historyFuture;

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
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.picture_as_pdf_outlined,
                                    size: 18, color: theme.colorScheme.primary),
                                tooltip: "Export PDF",
                                onPressed: () => ExportService.exportToPdf(
                                  title: item.type,
                                  totalPremium: item.totalPremium,
                                  details: item.details,
                                ),
                              ),
                              Text(
                                item.date,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(120),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Premium",
                              style: theme.textTheme.bodyMedium),
                          Text(
                            "BDT ${NumberFormat("#,##0", "en_US").format(item.totalPremium)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: item.details.entries.map((e) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${e.key}: ",
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${e.value}${e.key == 'Discount' || e.key == 'NCB' ? '%' : ''}",
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
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
