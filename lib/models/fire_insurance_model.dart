class FireInsuranceModel {
  static const Map<String, Map<String, double>> ratesTable = {
    'Dhaka': {
      'Fire': 0.06,
      'Earthquake': 0.16,
      'Cyclone': 0.13,
      'Flood': 0.17,
    },
    'Chittagong': {
      'Fire': 0.08,
      'Earthquake': 0.16,
      'Cyclone': 0.25,
      'Flood': 0.08,
    },
    'Sylhet': {
      'Fire': 0.08,
      'Earthquake': 0.03,
      'Cyclone': 0.06,
      'Flood': 0.13,
    },
  };

  static Map<String, dynamic> calculatePremium({
    required double insuredSum,
    required String zone,
    required List<String> selectedRisks,
  }) {
    double totalRate = 0.0;
    double totalPremium = 0.0;
    double vat = 0.0;
    double netPremium = 0.0;

    final zoneRates = ratesTable[zone];
    final Map<String, double> riskPremiums = {};

    if (zoneRates != null) {
      for (var risk in selectedRisks) {
        final rate = zoneRates[risk] ?? 0.0;
        totalRate += rate;
        final premium = insuredSum * (rate / 100);
        riskPremiums[risk] = premium;
      }
    }

    netPremium = insuredSum * (totalRate / 100);
    vat = netPremium * 0.15;
    totalPremium = netPremium + vat;

    return {
      'totalRate': totalRate,
      'netPremium': netPremium,
      'vat': vat,
      'totalPremium': totalPremium,
      'riskPremiums': riskPremiums,
    };
  }
}
