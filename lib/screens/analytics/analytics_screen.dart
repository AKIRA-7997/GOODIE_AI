import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/charts/app_bar_chart.dart';
import '../../widgets/charts/app_line_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SectionCard(
              title: 'Weekly Sales',
              subtitle: 'Last 4 weeks performance',
              child: AppBarChart(
                data: analytics.weeklySales,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Monthly Sales',
              subtitle: 'Last 6 months performance',
              child: AppBarChart(
                data: analytics.monthlySales,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Category Performance',
              subtitle: 'Performance score out of 100',
              child: AppBarChart(
                data: analytics.categoryPerformance,
                color: const Color(0xFFA855F7),
                height: 220,
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Demand Comparison',
              subtitle: 'Actual vs predicted demand',
              trailing: Row(
                children: [
                  _LegendDot(color: AppColors.secondary, label: 'Actual'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.primary, label: 'Predicted'),
                ],
              ),
              child: AppLineChart(
                data: analytics.demandActual,
                secondaryData: analytics.demandPredicted,
                color: AppColors.secondary,
                secondaryColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
