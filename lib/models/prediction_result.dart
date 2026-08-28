class PredictionResult {
  final String store;
  final String product;

  final int expectedDemand;
  final int currentInventory;
  final int safetyStock;
  final int recommendedInventory;
  final int restockQuantity;
  final int surplusQuantity;

  final String stockStatus;
  final String riskLevel;

  final int demandChange;
  final double demandChangePercentage;

  final String businessAdvice;
  final List<String> demandFactors;

  final double confidenceScore;
  final DateTime generatedAt;

  const PredictionResult({
    required this.store,
    required this.product,
    required this.expectedDemand,
    required this.currentInventory,
    required this.safetyStock,
    required this.recommendedInventory,
    required this.restockQuantity,
    required this.surplusQuantity,
    required this.stockStatus,
    required this.riskLevel,
    required this.demandChange,
    required this.demandChangePercentage,
    required this.businessAdvice,
    required this.demandFactors,
    required this.confidenceScore,
    required this.generatedAt,
  });

  factory PredictionResult.fromJson({
    required Map<String, dynamic> json,
    required String store,
    required String product,
  }) {
    return PredictionResult(
      store: store,
      product: product,
      expectedDemand: (json['expected_demand'] as num).round(),
      currentInventory: (json['current_inventory'] as num).round(),
      safetyStock: (json['safety_stock'] as num).round(),
      recommendedInventory:
      (json['recommended_inventory'] as num).round(),
      restockQuantity: (json['restock_quantity'] as num).round(),
      surplusQuantity: (json['surplus_quantity'] as num).round(),
      stockStatus: json['stock_status']?.toString() ?? 'Unknown',
      riskLevel: json['risk_level']?.toString() ?? 'Unknown',
      demandChange: (json['demand_change'] as num).round(),
      demandChangePercentage:
      (json['demand_change_percentage'] as num).toDouble(),
      businessAdvice:
      json['business_advice']?.toString() ??
          'No recommendation available.',
      demandFactors:
      (json['demand_factors'] as List<dynamic>? ?? const [])
          .map((factor) => factor.toString())
          .toList(),
      confidenceScore: (json['confidence'] as num).toDouble(),
      generatedAt: DateTime.now(),
    );
  }

  bool get requiresRestock => restockQuantity > 0;

  bool get hasSurplus => surplusQuantity > 0;

  bool get demandIsIncreasing => demandChange > 0;

  bool get demandIsDecreasing => demandChange < 0;

  String get demandChangeLabel {
    if (demandChange > 0) {
      return '+$demandChange units';
    }

    if (demandChange < 0) {
      return '$demandChange units';
    }

    return 'No change';
  }

  String get confidenceLabel {
    return '${(confidenceScore * 100).toStringAsFixed(1)}%';
  }
}