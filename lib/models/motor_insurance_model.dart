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
    double basePremium = insuredSum * (riskFactor / 100);

    double insuranceFee;
    if (engineCC <= 1300) {
      insuranceFee = 2795;
    } else if (engineCC <= 1800) {
      insuranceFee = 2873;
    } else if (engineCC <= 3000) {
      insuranceFee = 2925;
    } else {
      insuranceFee = 2990;
    }

    double premiumWithInsuranceFee = basePremium + insuranceFee;
    double discountedPremium =
        premiumWithInsuranceFee - (premiumWithInsuranceFee * (discount / 100));

    double finalPremium = discountedPremium - (discountedPremium * (ncb / 100));

    double extraCost = (passengers * 45) + (drivers * 30);
    finalPremium += extraCost;

    double vat = finalPremium * 0.15;
    double totalPremium = finalPremium + vat;

    return {
      'netPremium': finalPremium,
      'vat': vat,
      'totalPremium': totalPremium,
    };
  }
}
