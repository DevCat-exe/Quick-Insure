/// Tariff tables for the Overseas Mediclaim travel insurance calculator.
///
/// The base premium is decided by the plan, the insured age band and the trip
/// length band only. A `null` cell in the tariff means "No Cover".
class OverseasMediclaimModel {
  OverseasMediclaimModel._();

  static const String planWorldwide =
      'Plan A - Worldwide Excluding USA & Canada';
  static const String planWorldwideUsa =
      'Plan C - Worldwide Including USA & Canada';

  static const List<String> plans = [planWorldwide, planWorldwideUsa];

  /// Short display name for a plan, e.g. `Plan A` for
  /// `Plan A - Worldwide Excluding USA & Canada`.
  static String shortPlan(String plan) {
    final index = plan.indexOf(' - ');
    return index == -1 ? plan : plan.substring(0, index);
  }

  /// Age bands (years) shared by both plans.
  static const List<String> ageBands = [
    '0.5-40',
    '41-50',
    '51-55',
    '56-59',
    '60-65',
    '66-70',
    '71-75',
    '76-79',
  ];

  static const List<int> _ageBandMin = [0, 41, 51, 56, 60, 66, 71, 76];
  static const List<int> _ageBandMax = [40, 50, 55, 59, 65, 70, 75, 79];

  /// Trip length bands, counted as inclusive travel days.
  static const List<String> periodBands = [
    '01-14',
    '15-21',
    '22-28',
    '29-35',
    '36-47',
    '48-60',
    '61-75',
    '76-90',
    '91-120',
    '121-147',
    '148-180',
  ];

  static const List<int> _periodBandMin = [
    1,
    15,
    22,
    29,
    36,
    48,
    61,
    76,
    91,
    121,
    148,
  ];
  static const List<int> _periodBandMax = [
    14,
    21,
    28,
    35,
    47,
    60,
    75,
    90,
    120,
    147,
    180,
  ];

  static const int maxAge = 79;
  static const int maxPeriodDays = 180;
  static const double vatRate = 0.15;

  /// Tariff in BDT, indexed as `_rates[plan][periodBandIndex][ageBandIndex]`.
  static const Map<String, List<List<int?>>> _rates = {
    planWorldwide: [
      [1250, 1880, 2530, 2530, 2530, 8230, 14400, 28810],
      [1300, 2000, 2690, 2690, 2690, 8770, 15350, 30710],
      [1460, 2240, 3000, 3000, 3000, 9790, 17140, 34290],
      [1800, 2700, 3630, 3630, 3630, 11840, 20710, 41430],
      [2060, 3100, 4170, 4170, 4170, 13570, 23740, 47490],
      [2430, 3670, 4940, 4940, 4940, 16070, 28120, 56250],
      [3000, 4530, 6090, 6090, 6090, 19840, 34720, 69450],
      [3590, 5370, 7230, 7230, 7230, 23520, 41160, 82320],
      [6070, 9170, 12330, 12330, null, null, null, null],
      [7320, 11000, 14790, 14790, null, null, null, null],
      [10170, 15180, 20570, 20570, null, null, null, null],
    ],
    planWorldwideUsa: [
      [2290, 4250, 5400, 5400, 5400, 17560, 30740, 61480],
      [2440, 4550, 5780, 5780, 5780, 18820, 32930, 65870],
      [2760, 5280, 6700, 6700, 6700, 21800, 38150, 76300],
      [3310, 6220, 7900, 7900, 7900, 25720, 45000, 90020],
      [3950, 7580, 9640, 9640, 9640, 31370, 54880, 109780],
      [3360, 12330, 15660, 15660, 15660, 50970, 89200, 178390],
      [9150, 17840, 22650, 22650, 22650, 73700, 128990, 257970],
      [11010, 21440, 27230, 27230, 27230, 88600, 155060, 310120],
      [15510, 30360, 38550, 38550, null, null, null, null],
      [20600, 44250, 51240, 51240, null, null, null, null],
      [27270, 53670, 68150, 68150, null, null, null, null],
    ],
  };

  /// Age in completed years on the departure date.
  static int calculateAge({
    required DateTime dateOfBirth,
    required DateTime departureDate,
  }) {
    var age = departureDate.year - dateOfBirth.year;
    final hadBirthday = departureDate.month > dateOfBirth.month ||
        (departureDate.month == dateOfBirth.month &&
            departureDate.day >= dateOfBirth.day);
    if (!hadBirthday) age--;
    return age < 0 ? 0 : age;
  }

  /// Trip length in days, counting both the departure and the return date.
  static int calculatePeriodDays({
    required DateTime departureDate,
    required DateTime returnDate,
  }) {
    final start = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
    );
    final end = DateTime(returnDate.year, returnDate.month, returnDate.day);
    return end.difference(start).inDays + 1;
  }

  static int? ageBandIndex(int age) {
    for (var i = 0; i < _ageBandMin.length; i++) {
      if (age >= _ageBandMin[i] && age <= _ageBandMax[i]) return i;
    }
    return null;
  }

  static int? periodBandIndex(int periodDays) {
    for (var i = 0; i < _periodBandMin.length; i++) {
      if (periodDays >= _periodBandMin[i] && periodDays <= _periodBandMax[i]) {
        return i;
      }
    }
    return null;
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final monthIndex = date.year * 12 + date.month - 1 + months;
    final year = monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    return DateTime(year, month, day);
  }

  static Map<String, dynamic> _noCoverResult({
    required int age,
    required int periodDays,
    required String reason,
  }) {
    final ageIndex = ageBandIndex(age);
    final periodIndex = periodBandIndex(periodDays);
    return {
      'hasCover': false,
      'basePremium': null,
      'netPremium': 0.0,
      'vat': 0.0,
      'totalPremium': 0.0,
      'age': age,
      'periodDays': periodDays,
      'ageBand': ageIndex == null ? null : ageBands[ageIndex],
      'periodBand': periodIndex == null ? null : periodBands[periodIndex],
      'noCoverReason': reason,
    };
  }

  static Map<String, dynamic> calculatePremium({
    required String plan,
    required DateTime dateOfBirth,
    required DateTime departureDate,
    required DateTime returnDate,
  }) {
    final age = calculateAge(
      dateOfBirth: dateOfBirth,
      departureDate: departureDate,
    );
    final periodDays = calculatePeriodDays(
      departureDate: departureDate,
      returnDate: returnDate,
    );
    final departureDay =
        DateTime(departureDate.year, departureDate.month, departureDate.day);
    final birthDay =
        DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);

    if (birthDay.isAfter(departureDay)) {
      return _noCoverResult(
        age: age,
        periodDays: periodDays,
        reason: 'Date of birth must be on or before the departure date.',
      );
    }

    if (_addMonthsClamped(birthDay, 6).isAfter(departureDay)) {
      return _noCoverResult(
        age: age,
        periodDays: periodDays,
        reason: 'The minimum insured age is six months on the departure date.',
      );
    }

    return calculatePremiumFor(
      plan: plan,
      age: age,
      periodDays: periodDays,
    );
  }

  static Map<String, dynamic> calculatePremiumFor({
    required String plan,
    required int age,
    required int periodDays,
  }) {
    final ageIndex = ageBandIndex(age);
    final periodIndex = periodBandIndex(periodDays);

    if (ageIndex == null) {
      return _noCoverResult(
        age: age,
        periodDays: periodDays,
        reason:
            'Insured age $age years is outside the covered range (6 months to $maxAge years).',
      );
    }
    if (periodIndex == null) {
      return _noCoverResult(
        age: age,
        periodDays: periodDays,
        reason:
            'A trip of $periodDays days is outside the covered range (up to $maxPeriodDays days).',
      );
    }

    final rate = _rates[plan]?[periodIndex][ageIndex];
    if (rate == null) {
      return _noCoverResult(
        age: age,
        periodDays: periodDays,
        reason:
            'Ages ${ageBands[ageIndex]} are not covered for trips of ${periodBands[periodIndex]} days.',
      );
    }

    final netPremium = rate.toDouble();
    final vat = netPremium * vatRate;

    return {
      'hasCover': true,
      'basePremium': rate,
      'netPremium': netPremium,
      'vat': vat,
      'totalPremium': netPremium + vat,
      'age': age,
      'periodDays': periodDays,
      'ageBand': ageBands[ageIndex],
      'periodBand': periodBands[periodIndex],
      'noCoverReason': null,
    };
  }
}
