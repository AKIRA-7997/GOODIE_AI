import 'package:flutter/material.dart';

import '../models/chart_point.dart';
import '../models/prediction_result.dart';

class DashboardProvider extends ChangeNotifier {
  double todaysSales = 48250.75;
  int currentInventoryUnits = 12840;
  int lowStockAlerts = 7;

  final List<PredictionResult> _recentPredictions = [];

  List<PredictionResult> get recentPredictions =>
      List.unmodifiable(_recentPredictions);

  double get predictedTomorrowSales {
    if (_recentPredictions.isEmpty) return 0;

    final latest = _recentPredictions.first;

    // Temporary estimated revenue.
    // Later, the backend can return an actual predicted revenue value.
    return latest.expectedDemand * 99.0;
  }

  int get recommendedOrders {
    return _recentPredictions
        .where((prediction) => prediction.requiresRestock)
        .length;
  }

  int get highRiskPredictions {
    return _recentPredictions
        .where(
          (prediction) =>
      prediction.riskLevel.toLowerCase() == 'high',
    )
        .length;
  }

  int get totalRestockUnits {
    return _recentPredictions.fold<int>(
      0,
          (total, prediction) =>
      total + prediction.restockQuantity,
    );
  }

  double get averageConfidence {
    if (_recentPredictions.isEmpty) return 0;

    final total = _recentPredictions.fold<double>(
      0,
          (sum, prediction) =>
      sum + prediction.confidenceScore,
    );

    return total / _recentPredictions.length;
  }

  final List<ChartPoint> salesTrend = const [
    ChartPoint('Mon', 32000),
    ChartPoint('Tue', 38500),
    ChartPoint('Wed', 35200),
    ChartPoint('Thu', 41200),
    ChartPoint('Fri', 46800),
    ChartPoint('Sat', 52300),
    ChartPoint('Sun', 48250),
  ];

  final List<ChartPoint> _demandTrend = [
    const ChartPoint('Mon', 420),
    const ChartPoint('Tue', 460),
    const ChartPoint('Wed', 445),
    const ChartPoint('Thu', 510),
    const ChartPoint('Fri', 590),
    const ChartPoint('Sat', 640),
  ];

  List<ChartPoint> get demandTrend {
    final points = List<ChartPoint>.from(_demandTrend);

    if (_recentPredictions.isNotEmpty) {
      points.add(
        ChartPoint(
          'Latest',
          _recentPredictions.first.expectedDemand.toDouble(),
        ),
      );
    }

    return points;
  }

  final List<CategorySlice> categoryDistribution = const [
    CategorySlice('Electronics', 32, 0),
    CategorySlice('Groceries', 26, 1),
    CategorySlice('Apparel', 18, 2),
    CategorySlice('Home & Living', 14, 3),
    CategorySlice('Other', 10, 4),
  ];

  void addPrediction(PredictionResult prediction) {
    _recentPredictions.insert(0, prediction);

    if (_recentPredictions.length > 10) {
      _recentPredictions.removeLast();
    }

    notifyListeners();
  }

  void updateInventory({
    required int totalUnits,
    required int lowStockCount,
  }) {
    currentInventoryUnits = totalUnits;
    lowStockAlerts = lowStockCount;
    notifyListeners();
  }

  void clearPredictions() {
    _recentPredictions.clear();
    notifyListeners();
  }
}