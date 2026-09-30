import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../widgets/result_popup.dart';
import '../widgets/desktop_history_view.dart';

class HistoryScreen extends StatefulWidget {
  final bool isEmbeddedInDesktop;

  const HistoryScreen({
    super.key,
    this.isEmbeddedInDesktop = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<CalculationHistoryItem>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  double _parseBDT(String value) {
    return double.tryParse(
            value.replaceAll('BDT', '').replaceAll(',', '').trim()) ??
        0;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          if (details['Registration Number'] != null)
            "Registration Number": details['Registration Number'].toString(),
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
      final totalRate = details['Total Rate']?.toString() ?? '';
      final risksStr = details['Selected Risks']?.toString() ?? '';
      final riskEntries = <String, String>{};
      for (final part in risksStr.split(', ')) {
        final trimmed = part.trim();
        if (trimmed.contains(' - BDT ')) {
          final rateMatch = RegExp(r'^(.+?)\s*\(([\d.]+%)\)\s*-\s*BDT\s*(.+)$')
              .firstMatch(trimmed);
          if (rateMatch != null) {
            final riskName = rateMatch.group(1)!.trim();
            final rate = rateMatch.group(2)!;
            final premium = rateMatch.group(3)!;
            riskEntries[riskName] = '$rate (BDT $premium)';
          }
        }
      }
      sections = [
        ResultSection("Property Details", {
          "Zone": zone,
        }),
        if (riskEntries.isNotEmpty)
          ResultSection("Selected Risks", riskEntries),
        if (totalRate.isNotEmpty)
          ResultSection("Summary", {
            "Total Rate": totalRate,
          }),
      ];
    } else {
      sections = [
        ResultSection(
            "Details", details.map((k, v) => MapEntry(k, v.toString()))),
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

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All History"),
        content: const Text(
          "Are you sure you want to delete all calculation history? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await HistoryService.clearHistory();
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              _refreshHistory();
              messenger.showSnackBar(
                const SnackBar(content: Text("History cleared.")),
              );
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isDesktop = widget.isEmbeddedInDesktop || shortestSide >= 600;

    if (isDesktop) {
      if (widget.isEmbeddedInDesktop) {
        return const DesktopHistoryView();
      }
      return Scaffold(
        appBar: AppBar(title: const Text("Calculation History")),
        body: const DesktopHistoryView(),
      );
    }

    // Classic Mobile list layout
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

          final allHistory = snapshot.data ?? [];
          final query = _searchQuery.trim().toLowerCase();
          final history = allHistory.where((item) {
            if (_selectedFilter == 'Motor' && item.type != 'Motor Insurance') {
              return false;
            }
            if (_selectedFilter == 'Fire' && item.type != 'Fire Insurance') {
              return false;
            }
            if (query.isEmpty) return true;
            return item.matchesSearch(query);
          }).toList();

          if (allHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 72,
                    color: theme.colorScheme.primary.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Calculations Yet",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your calculated premiums will appear here.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: history.isEmpty ? 2 : history.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search history',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            children: [
                              for (final filter in ['All', 'Motor', 'Fire'])
                                ChoiceChip(
                                  label: Text(filter),
                                  selected: _selectedFilter == filter,
                                  onSelected: (_) => setState(
                                    () => _selectedFilter = filter,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (history.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        'No matching calculations found.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                final item = history[index - 1];
                final isMotor = item.type == 'Motor Insurance';

                return Dismissible(
                  key: Key('${item.date}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await HistoryService.deleteCalculation(item);
                    _refreshHistory();
                  },
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(25)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showHistoryItemPopup(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale =
                                MediaQuery.textScalerOf(context).scale(1);
                            final compact =
                                constraints.maxWidth < 460 * textScale;
                            final icon = Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isMotor ? Colors.blue : Colors.orange)
                                    .withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isMotor
                                    ? Icons.directions_car
                                    : Icons.local_fire_department,
                                color: isMotor ? Colors.blue : Colors.orange,
                                size: 24,
                              ),
                            );
                            final details = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (item.details['Insured Sum'] != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    "Insured: ${item.details['Insured Sum']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                                if (item.details['Registration Number'] !=
                                    null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    "Reg: ${item.details['Registration Number']}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            );
                            final amount = Text(
                              "BDT ${NumberFormat("#,##0", "en_US").format(item.totalPremium)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: theme.colorScheme.primary,
                              ),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      icon,
                                      const SizedBox(width: 14),
                                      Expanded(child: details),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 62,
                                      top: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: amount,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                icon,
                                const SizedBox(width: 14),
                                Expanded(child: details),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    amount,
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
