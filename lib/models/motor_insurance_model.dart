class MotorInsuranceModel {
  static Map<String, dynamic> calculatePremium({
    required double insuredSum,
    required double riskFactor,
    required double discount,
    required double ncb,
    required int passengers,
    required int drivers,
    required int engineCC,
  }) {
    try {
      final basePremium = insuredSum * (riskFactor / 100);
      final insuranceFee = _getInsuranceFee(engineCC);
      final premiumWithFee = basePremium + insuranceFee;
      final discountedPremium =
          premiumWithFee - (premiumWithFee * (discount / 100));
      final finalPremium =
          discountedPremium - (discountedPremium * (ncb / 100));
      final extraCost = (passengers * 45) + (drivers * 30);
      final totalBeforeVat = finalPremium + extraCost;
      final vat = totalBeforeVat * 0.15;

      return {
        'netPremium': totalBeforeVat,
        'vat': vat,
        'totalPremium': totalBeforeVat + vat,
      };
    } catch (e) {
      throw Exception('Premium calculation failed: $e');
    }
  }

  static double _getInsuranceFee(int engineCC) {
    if (engineCC <= 1300) return 2795;
    if (engineCC <= 1800) return 2873;
    if (engineCC <= 3000) return 2925;
    return 2990;
  }
}
