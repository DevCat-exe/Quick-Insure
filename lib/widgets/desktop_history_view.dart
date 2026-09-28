import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../services/export_service.dart';
import '../widgets/result_popup.dart';

class DesktopHistoryView extends StatefulWidget {
  final VoidCallback? onBackToCalculator;

  const DesktopHistoryView({
    super.key,
    this.onBackToCalculator,
  });

  @override
  State<DesktopHistoryView> createState() => _DesktopHistoryViewState();
}

class _DesktopHistoryViewState extends State<DesktopHistoryView> {
  late Future<List<CalculationHistoryItem>> _historyFuture;
  CalculationHistoryItem? _selectedItem;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _historyFuture = HistoryService.getHistory();
    });
  }

  double _parseBDT(String value) {
    return double.tryParse(value.replaceAll('BDT', '').replaceAll(',', '').trim()) ?? 0;
  }

  List<ResultSection> _buildSections(CalculationHistoryItem item) {
    final details = item.details;
    if (item.type == 'Motor Insurance') {
      return [
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
      final totalRate = details['Total Rate']?.toString() ?? '';
      final risksStr = details['Selected Risks']?.toString() ?? '';
      final riskEntries = <String, String>{};
      for (final part in risksStr.split(', ')) {
        final trimmed = part.trim();
        if (trimmed.contains(' - BDT ')) {
          final rateMatch = RegExp(r'^(.+?)\s*\(([\d.]+%)\)\s*-\s*BDT\s*(.+)$').firstMatch(trimmed);
          if (rateMatch != null) {
            final riskName = rateMatch.group(1)!.trim();
            final rate = rateMatch.group(2)!;
            final premium = rateMatch.group(3)!;
            riskEntries[riskName] = '$rate (BDT $premium)';
          }
        }
      }
      return [
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
      return [
        ResultSection("Details", details.map((k, v) => MapEntry(k, v.toString()))),
      ];
    }
  }

  Future<void> _deleteItem(CalculationHistoryItem item) async {
    await HistoryService.deleteCalculation(item);
    if (_selectedItem == item) {
      _selectedItem = null;
    }
    _refresh();
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All History"),
        content: const Text("Are you sure you want to permanently delete all calculation records?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HistoryService.clearHistory();
      setState(() {
        _selectedItem = null;
      });
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return FutureBuilder<List<CalculationHistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data ?? [];
        final filteredItems = allItems.where((item) {
          if (_selectedFilter != 'All' && item.type != _selectedFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesType = item.type.toLowerCase().contains(query);
            final matchesDate = item.date.toLowerCase().contains(query);
            final matchesTotal = item.totalPremium.toString().contains(query);
            final matchesDetails = item.details.values.any((v) => v.toString().toLowerCase().contains(query));
            return matchesType || matchesDate || matchesTotal || matchesDetails;
          }
          return true;
        }).toList();

        // Auto select first item if none selected
        if (_selectedItem == null && filteredItems.isNotEmpty) {
          _selectedItem = filteredItems.first;
        } else if (_selectedItem != null && !filteredItems.contains(_selectedItem)) {
          _selectedItem = filteredItems.isNotEmpty ? filteredItems.first : null;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Master List Column
            SizedBox(
              width: 400,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withAlpha(50) : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black.withAlpha(15),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Search & Filter Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Records (${filteredItems.length})",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (allItems.isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_sweep, size: 18),
                                  label: const Text("Clear All"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primary,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: _confirmClearAll,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search field
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: "Search records, date, or sum...",
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip("All"),
                                const SizedBox(width: 8),
                                _buildFilterChip("Motor Insurance"),
                                const SizedBox(width: 8),
                                _buildFilterChip("Fire Insurance"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Items List
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    allItems.isEmpty ? "No calculation history yet" : "No matching records found",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = item == _selectedItem;
                                final isMotor = item.type == 'Motor Insurance';
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setState(() => _selectedItem = item),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primary.withAlpha(isDark ? 50 : 25)
                                            : isDark
                                                ? Colors.white.withAlpha(5)
                                                : Colors.grey.withAlpha(12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? primary
                                              : isDark
                                                  ? Colors.white10
                                                  : Colors.black.withAlpha(10),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (isMotor ? Colors.blue : Colors.orange).withAlpha(30),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isMotor ? Icons.directions_car : Icons.local_fire_department,
                                              color: isMotor ? Colors.blue : Colors.orange,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      item.type,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: isSelected ? primary : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      "BDT ${NumberFormat("#,##0", "en_US").format(item.totalPremium)}",
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 14,
                                                        color: primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.date,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                if (item.details['Insured Sum'] != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Insured: ${item.details['Insured Sum']}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            tooltip: "Delete",
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _deleteItem(item),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Detail Inspector Column
            Expanded(
              child: _selectedItem == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "Select a calculation to inspect details",
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: _buildDetailCard(_selectedItem!),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primary.withAlpha(30),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primary : null,
      ),
      side: BorderSide(
        color: isSelected ? primary : Colors.grey.withAlpha(60),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = label);
      },
    );
  }

  Widget _buildDetailCard(CalculationHistoryItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final details = item.details;
    final insuredSum = _parseBDT(details['Insured Sum']?.toString() ?? '0');
    final netPremium = _parseBDT(details['Net Premium']?.toString() ?? '0');
    final vat = _parseBDT(details['VAT (15%)']?.toString() ?? '0');
    final sections = _buildSections(item);

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
            // Top Bar
            Container(
              padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.type == 'Motor Insurance' ? Icons.directions_car : Icons.local_fire_department,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Calculated on ${item.date}",
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: "Delete Record",
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Total Banner
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
                              "TOTAL PREMIUM",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Includes 15% VAT",
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "BDT ${NumberFormat("#,##0", "en_US").format(item.totalPremium)}",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(theme, "Insured Sum", insuredSum > 0 ? "BDT ${NumberFormat("#,##0", "en_US").format(insuredSum)}" : (details['Insured Sum']?.toString() ?? 'N/A')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(theme, "Net Premium", "BDT ${NumberFormat("#,##0", "en_US").format(netPremium)}"),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(theme, "VAT (15%)", "BDT ${NumberFormat("#,##0", "en_US").format(vat)}"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sections
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: section.items.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
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

                  const SizedBox(height: 12),
                  // Export Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text("Export Official PDF Receipt"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () => ExportService.exportToPdf(
                        title: item.type,
                        totalPremium: item.totalPremium,
                        details: details,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(ThemeData theme, String label, String value) {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
            ),
          ),
          const SizedBox(height: 4),
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
