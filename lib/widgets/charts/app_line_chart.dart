import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chart_point.dart';

/// Smooth gradient line chart used for sales/demand trends.
/// Supports an optional second series for comparisons.
class AppLineChart extends StatelessWidget {
  final List<ChartPoint> data;
  final List<ChartPoint>? secondaryData;
  final Color color;
  final Color secondaryColor;
  final double height;

  const AppLineChart({
    super.key,
    required this.data,
    this.secondaryData,
    this.color = AppColors.secondary,
    this.secondaryColor = AppColors.primary,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [
          ...data.map((e) => e.value),
          ...?secondaryData?.map((e) => e.value),
        ].reduce((a, b) => a > b ? a : b) *
        1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[i].label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardAlt,
              tooltipBorder: const BorderSide(color: AppColors.border),
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  s.y.toStringAsFixed(0),
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            _buildLine(data, color),
            if (secondaryData != null) _buildLine(secondaryData!, secondaryColor),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<ChartPoint> points, Color lineColor) {
    return LineChartBarData(
      spots: [
        for (int i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), points[i].value),
      ],
      isCurved: true,
      curveSmoothness: 0.3,
      color: lineColor,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [lineColor.withOpacity(0.28), lineColor.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
