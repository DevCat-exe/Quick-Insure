import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/styles.dart';
import '../models/overseas_mediclaim_model.dart';
import '../widgets/result_popup.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/desktop_calculation_summary_card.dart';
import '../services/history_service.dart';
import '../main.dart';

class OverseasMediclaimCalculator extends StatefulWidget {
  final bool isEmbeddedInDesktop;
  const OverseasMediclaimCalculator({
    super.key,
    this.isEmbeddedInDesktop = false,
  });

  @override
  State<OverseasMediclaimCalculator> createState() =>
      _OverseasMediclaimCalculatorState();

  static String get displayName => "Overseas Mediclaim";
}

class _OverseasMediclaimCalculatorState
    extends State<OverseasMediclaimCalculator> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  TextEditingController? _countryAutocompleteController;
  List<String> _countries = const [];

  String? _selectedPlan;
  DateTime? _dateOfBirth;
  DateTime? _departureDate;
  DateTime? _returnDate;

  Map<String, dynamic>? _currentResult;

  String _normalizeCountry(String country) =>
      country.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  bool get _countryExcludedByPlan {
    if (_selectedPlan != OverseasMediclaimModel.planWorldwide) return false;
    return _isUnitedStatesOrCanada(_countryController.text);
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final json = await rootBundle.loadString('assets/countries.json');
      final decoded = jsonDecode(json) as List<dynamic>;
      final countries = decoded.cast<String>()..sort();
      if (mounted) setState(() => _countries = countries);
    } catch (error) {
      debugPrint('Could not load country suggestions: $error');
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _nameController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  bool get _hasTripDetails =>
      _selectedPlan != null &&
      _dateOfBirth != null &&
      _departureDate != null &&
      _returnDate != null &&
      !_returnDate!.isBefore(_departureDate!);

  bool get _isFormValid =>
      _hasTripDetails &&
      _countryController.text.trim().isNotEmpty &&
      !_countryExcludedByPlan &&
      _nameController.text.trim().isNotEmpty &&
      _passportController.text.trim().isNotEmpty;

  bool get _isNoCover =>
      _countryExcludedByPlan ||
      (_currentResult != null && _currentResult!['hasCover'] != true);

  String get _noCoverReason => _countryExcludedByPlan
      ? 'Plan A excludes the United States and Canada. Select Plan C to travel to either country.'
      : _currentResult?['noCoverReason']?.toString() ??
          'This plan and travel period combination is not covered.';

  void _resetForm() {
    setState(() {
      _countryController.clear();
      _countryAutocompleteController?.clear();
      _nameController.clear();
      _passportController.clear();
      _selectedPlan = null;
      _dateOfBirth = null;
      _departureDate = null;
      _returnDate = null;
      _currentResult = null;
    });
  }

  void _recalculateLive() {
    if (!_hasTripDetails) {
      setState(() => _currentResult = null);
      return;
    }
    try {
      final result = OverseasMediclaimModel.calculatePremium(
        plan: _selectedPlan!,
        dateOfBirth: _dateOfBirth!,
        departureDate: _departureDate!,
        returnDate: _returnDate!,
      );
      setState(() => _currentResult = result);
    } catch (_) {
      setState(() => _currentResult = null);
    }
  }

  String _formatDate(DateTime? date) =>
      date == null ? '' : DateFormat('dd MMM yyyy').format(date);

  Future<void> _pickDate({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    onPicked(picked);
    _recalculateLive();
  }

  Future<void> _showNoCoverDialog(String reason) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_outlined,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("No Cover Available")),
            ],
          ),
          content: Text(
            "$reason\n\nPlease change the plan, the date of birth or the travel dates and try again.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateAndShowModal() async {
    _recalculateLive();
    final result = _currentResult;

    if (result == null) {
      final messenger = scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text("Invalid input. Please check your values."),
        ),
      );
      return;
    }

    if (_isNoCover) {
      await _showNoCoverDialog(_noCoverReason);
      return;
    }

    try {
      final details = _buildExportDetails(result);

      final historyItem = CalculationHistoryItem(
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        type: 'Overseas Mediclaim',
        totalPremium: result['totalPremium'],
        details: details,
      );
      await HistoryService.saveCalculation(historyItem);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ResultPopup(
          title: "Overseas Mediclaim",
          netPremium: result['netPremium'],
          vat: result['vat'],
          totalPremium: result['totalPremium'],
          sections: _buildSections(result),
          exportDetails: details,
        ),
      );
    } catch (_) {}
  }

  List<ResultSection> _buildSections(Map<String, dynamic> result) {
    return [
      ResultSection("Policy Plan", {
        "Plan": _selectedPlan == null
            ? ''
            : OverseasMediclaimModel.shortPlan(_selectedPlan!),
      }),
      ResultSection("Traveller Details", {
        "Full Name": _nameController.text.trim(),
        "Passport Number": _passportController.text.trim(),
        "Date of Birth": _formatDate(_dateOfBirth),
        "Insured Age": "${result['age']} years",
      }),
      ResultSection("Trip Details", {
        "Country": _countryController.text.trim(),
        "Departure Date": _formatDate(_departureDate),
        "Return Date": _formatDate(_returnDate),
        "Travel Period": "${result['periodDays']} days",
        "Covered Period Band": "Days ${result['periodBand']}",
      }),
    ];
  }

  Map<String, dynamic> _buildExportDetails(Map<String, dynamic> result) {
    final money = NumberFormat("#,##0", "en_US");

    return {
      'Plan': _selectedPlan == null
          ? ''
          : OverseasMediclaimModel.shortPlan(_selectedPlan!),
      'Traveller Name': _nameController.text.trim(),
      'Passport Number': _passportController.text.trim(),
      'Date of Birth': _formatDate(_dateOfBirth),
      'Insured Age': "${result['age']} years",
      'Country': _countryController.text.trim(),
      'Departure Date': _formatDate(_departureDate),
      'Return Date': _formatDate(_returnDate),
      'Travel Period': "${result['periodDays']} days",
      'Net Premium': "BDT ${money.format(result['netPremium'])}",
      'VAT (15%)': "BDT ${money.format(result['vat'])}",
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isDesktop = widget.isEmbeddedInDesktop || shortestSide >= 600;

    final formContent = _buildFormContent(theme, isDesktop);

    if (widget.isEmbeddedInDesktop) {
      return _buildDesktopLayout(theme, formContent);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(OverseasMediclaimCalculator.displayName),
        actions: [
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Reset Form (Esc)",
              onPressed: _resetForm,
            ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(theme, formContent)
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
                left: 24.0,
                right: 24.0,
                top: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  formContent,
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isFormValid ? _calculateAndShowModal : null,
                      child: const Text(
                        "Calculate Premium",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Widget formContent) {
    final result = _currentResult;
    final sections =
        result != null ? _buildSections(result) : <ResultSection>[];
    final exportDetails =
        result != null ? _buildExportDetails(result) : <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.black.withAlpha(15),
                    ),
                  ),
                  child: formContent,
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 5,
                child: DesktopCalculationSummaryCard(
                  title: "Overseas Mediclaim",
                  netPremium: result?['netPremium'] ?? 0.0,
                  vat: result?['vat'] ?? 0.0,
                  totalPremium: result?['totalPremium'] ?? 0.0,
                  sections: sections,
                  exportDetails: exportDetails,
                  isValid: _isFormValid &&
                      result != null &&
                      result['hasCover'] == true,
                  onReset: _resetForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme, bool isDesktop) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final departure = _departureDate ?? today;
    final returnLast = departure.add(const Duration(days: 365));
    final returnInitial = (_returnDate != null &&
            !_returnDate!.isBefore(departure) &&
            !_returnDate!.isAfter(returnLast))
        ? _returnDate!
        : departure;
    final int? ageYears = _dateOfBirth == null
        ? null
        : OverseasMediclaimModel.calculateAge(
            dateOfBirth: _dateOfBirth!,
            departureDate: _departureDate ?? today,
          );
    final int? durationDays = (_departureDate != null &&
            _returnDate != null &&
            !_returnDate!.isBefore(_departureDate!))
        ? OverseasMediclaimModel.calculatePeriodDays(
            departureDate: _departureDate!,
            returnDate: _returnDate!,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Policy Plan"),
        const SizedBox(height: 16),
        CustomDropdown(
          value: _selectedPlan ?? '',
          items: ['', ...OverseasMediclaimModel.plans],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPlan = value.isEmpty ? null : value;
              });
              _recalculateLive();
            }
          },
          labelText: "Plan",
          icon: Icons.public,
          hintText: "Select a plan",
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Traveller Details"),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          labelText: "Full Name",
          hintText: "Enter traveller full name",
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passportController,
          labelText: "Passport Number",
          hintText: "Enter passport number",
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _buildDateField(
          label: "Date of Birth",
          icon: Icons.cake_outlined,
          value: _dateOfBirth,
          onTap: () => _pickDate(
            initialDate: _dateOfBirth ?? DateTime(now.year - 30),
            firstDate: DateTime(1900),
            lastDate: today,
            onPicked: (picked) => setState(() => _dateOfBirth = picked),
          ),
        ),
        if (ageYears != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                theme,
                Icons.cake_outlined,
                "Age: $ageYears yrs",
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _buildSectionHeader(theme, "Trip Details"),
        const SizedBox(height: 16),
        _buildCountryAutocomplete(theme),
        const SizedBox(height: 20),
        _buildDateField(
          label: "Departure Date",
          icon: Icons.flight_takeoff,
          value: _departureDate,
          onTap: () => _pickDate(
            initialDate: _departureDate ?? today,
            firstDate: DateTime(now.year - 1, now.month, now.day),
            lastDate: DateTime(now.year + 5, now.month, now.day),
            onPicked: (picked) => setState(() => _departureDate = picked),
          ),
        ),
        const SizedBox(height: 20),
        _buildDateField(
          label: "Return Date",
          icon: Icons.flight_land,
          value: _returnDate,
          onTap: () => _pickDate(
            initialDate: returnInitial,
            firstDate: departure,
            lastDate: returnLast,
            onPicked: (picked) => setState(() => _returnDate = picked),
          ),
        ),
        if (durationDays != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                theme,
                Icons.timelapse,
                "Duration: $durationDays days",
              ),
            ],
          ),
        ],
        if (_isNoCover) ...[
          const SizedBox(height: 16),
          _buildNoCoverBanner(theme),
        ],
      ],
    );
  }

  Widget _buildCountryAutocomplete(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        initialValue: TextEditingValue(text: _countryController.text),
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return const Iterable<String>.empty();
          return _countries.where((country) {
            if (!country.toLowerCase().contains(query)) return false;
            if (_selectedPlan != OverseasMediclaimModel.planWorldwide) {
              return true;
            }
            return !_isUnitedStatesOrCanada(country);
          }).take(8);
        },
        onSelected: (country) {
          _countryController.text = country;
          setState(() {});
        },
        fieldViewBuilder: (
          context,
          fieldController,
          focusNode,
          onFieldSubmitted,
        ) {
          _countryAutocompleteController = fieldController;
          return CustomTextField(
            controller: fieldController,
            focusNode: focusNode,
            labelText: 'Country',
            hintText: 'Enter the country being visited',
            prefixIcon: Icons.flag_outlined,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              _countryController.text = value;
              setState(() {});
            },
            onSubmitted: onFieldSubmitted,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final optionList = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: constraints.maxWidth,
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(90),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: optionList.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withAlpha(90),
                  ),
                  itemBuilder: (context, index) {
                    final country = optionList[index];
                    final isHighlighted =
                        AutocompleteHighlightedOption.of(context) == index;
                    return InkWell(
                      onTap: () => onSelected(country),
                      child: Container(
                        color: isHighlighted
                            ? theme.colorScheme.primary.withAlpha(18)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Text(
                          country,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isUnitedStatesOrCanada(String country) {
    final normalized = _normalizeCountry(country);
    return normalized == 'us' ||
        normalized == 'usa' ||
        normalized.contains('america') ||
        normalized.contains('unitedstates') ||
        normalized.contains('canada');
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final hasValue = value != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppStyles.primaryDark),
          suffixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: AppStyles.primaryDark,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppStyles.primaryDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppStyles.primaryDark,
              width: 2,
            ),
          ),
        ),
        child: Text(
          hasValue ? _formatDate(value) : 'Select date',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
            color: hasValue ? null : theme.hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNoCoverBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.report_problem_outlined,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _noCoverReason,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}
