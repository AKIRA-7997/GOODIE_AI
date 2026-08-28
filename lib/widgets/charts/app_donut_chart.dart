import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chart_point.dart';

const List<Color> _palette = [
  AppColors.secondary,
  AppColors.primary,
  Color(0xFFA855F7),
  AppColors.warning,
  AppColors.textMuted,
];

/// Donut chart with a centered legend, used for category distribution.
class AppDonutChart extends StatelessWidget {
  final List<CategorySlice> slices;

  const AppDonutChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value,
                    color: _palette[s.colorIndex % _palette.length],
                    radius: 26,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _palette[s.colorIndex % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(s.value / total * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
