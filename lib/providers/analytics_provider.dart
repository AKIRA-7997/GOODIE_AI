import 'package:flutter/material.dart';
import '../models/chart_point.dart';

/// Supplies dummy series for the Analytics screen's charts.
class AnalyticsProvider extends ChangeNotifier {
  final List<ChartPoint> weeklySales = const [
    ChartPoint('W1', 210000),
    ChartPoint('W2', 245000),
    ChartPoint('W3', 228000),
    ChartPoint('W4', 268000),
  ];

  final List<ChartPoint> monthlySales = const [
    ChartPoint('Jan', 820000),
    ChartPoint('Feb', 780000),
    ChartPoint('Mar', 910000),
    ChartPoint('Apr', 860000),
    ChartPoint('May', 940000),
    ChartPoint('Jun', 990000),
  ];

  final List<ChartPoint> categoryPerformance = const [
    ChartPoint('Electronics', 92),
    ChartPoint('Groceries', 78),
    ChartPoint('Apparel', 65),
    ChartPoint('Home', 58),
    ChartPoint('Fitness', 44),
  ];

  final List<ChartPoint> demandActual = const [
    ChartPoint('Mon', 420),
    ChartPoint('Tue', 460),
    ChartPoint('Wed', 445),
    ChartPoint('Thu', 510),
    ChartPoint('Fri', 590),
    ChartPoint('Sat', 640),
    ChartPoint('Sun', 605),
  ];

  final List<ChartPoint> demandPredicted = const [
    ChartPoint('Mon', 400),
    ChartPoint('Tue', 470),
    ChartPoint('Wed', 460),
    ChartPoint('Thu', 495),
    ChartPoint('Fri', 560),
    ChartPoint('Sat', 615),
    ChartPoint('Sun', 630),
  ];
}
