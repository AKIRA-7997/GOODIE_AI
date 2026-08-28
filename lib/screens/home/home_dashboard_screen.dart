import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/charts/app_donut_chart.dart';
import '../../widgets/charts/app_line_chart.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/dashboard/stat_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    final currency = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            auth.displayName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.25,
                ),
                delegate: SliverChildListDelegate(
                  [
                    StatCard(
                      title: "Today's Sales",
                      value: currency.format(dash.todaysSales),
                      icon: Icons.payments_outlined,
                      accentColor: AppColors.secondary,
                      trendLabel: '+8.2%',
                      trendUp: true,
                    ),
                    StatCard(
                      title: 'Predicted Tomorrow',
                      value: currency.format(
                        dash.predictedTomorrowSales,
                      ),
                      icon: Icons.auto_graph_rounded,
                      accentColor: AppColors.primary,
                      trendLabel: '+4.1%',
                      trendUp: true,
                    ),
                    StatCard(
                      title: 'Current Inventory',
                      value: '${dash.currentInventoryUnits} units',
                      icon: Icons.inventory_2_outlined,
                      accentColor: const Color(0xFFA855F7),
                    ),
                    StatCard(
                      title: 'High-Risk Forecasts',
                      value: '${dash.highRiskPredictions} items',
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppColors.warning,
                    ),
                    StatCard(
                      title: 'Units to Restock',
                      value: '${dash.totalRestockUnits} units',
                      icon: Icons.add_shopping_cart_rounded,
                      accentColor: AppColors.success,
                    ),
                    StatCard(
                      title: 'Average Confidence',
                      value:
                      '${(dash.averageConfidence * 100).toStringAsFixed(1)}%',
                      icon: Icons.verified_outlined,
                      accentColor: AppColors.secondaryDark,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  0,
                ),
                child: SectionCard(
                  title: 'Sales Trend',
                  subtitle: 'Last 7 days',
                  child: AppLineChart(
                    data: dash.salesTrend,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  0,
                ),
                child: SectionCard(
                  title: 'Demand Trend',
                  subtitle: 'Predicted units demanded',
                  child: AppLineChart(
                    data: dash.demandTrend,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  0,
                ),
                child: SectionCard(
                  title: 'Category Distribution',
                  subtitle: 'Share of total sales',
                  child: AppDonutChart(
                    slices: dash.categoryDistribution,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  0,
                ),
                child: SectionCard(
                  title: 'Recent Predictions',
                  subtitle: dash.recentPredictions.isEmpty
                      ? 'No predictions generated yet'
                      : 'Latest GOODIE AI forecasts',
                  child: dash.recentPredictions.isEmpty
                      ? const _EmptyPredictionsState()
                      : Column(
                    children: [
                      for (final prediction
                      in dash.recentPredictions)
                        Padding(
                          padding:
                          const EdgeInsets.only(bottom: 12),
                          child: _RecentPredictionCard(
                            product: prediction.product,
                            store: prediction.store,
                            expectedDemand:
                            prediction.expectedDemand,
                            stockStatus:
                            prediction.stockStatus,
                            riskLevel: prediction.riskLevel,
                            restockQuantity:
                            prediction.restockQuantity,
                            requiresRestock:
                            prediction.requiresRestock,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPredictionCard extends StatelessWidget {
  final String product;
  final String store;
  final int expectedDemand;
  final String stockStatus;
  final String riskLevel;
  final int restockQuantity;
  final bool requiresRestock;

  const _RecentPredictionCard({
    required this.product,
    required this.store,
    required this.expectedDemand,
    required this.stockStatus,
    required this.riskLevel,
    required this.restockQuantity,
    required this.requiresRestock,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(riskLevel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: requiresRestock
                  ? AppColors.warning.withOpacity(0.15)
                  : AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              requiresRestock
                  ? Icons.add_shopping_cart_rounded
                  : Icons.check_circle_outline_rounded,
              color: requiresRestock
                  ? AppColors.warning
                  : AppColors.success,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  store,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _MiniBadge(
                      label: stockStatus,
                      color: _stockColor(stockStatus),
                    ),
                    const SizedBox(width: 6),
                    _MiniBadge(
                      label: '$riskLevel risk',
                      color: riskColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$expectedDemand units',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                requiresRestock
                    ? 'Restock $restockQuantity'
                    : 'Stock sufficient',
                style: TextStyle(
                  color: requiresRestock
                      ? AppColors.warning
                      : AppColors.success,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  Color _stockColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'low':
        return Colors.orangeAccent;
      case 'adequate':
        return Colors.amber;
      case 'healthy':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPredictionsState extends StatelessWidget {
  const _EmptyPredictionsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: AppColors.textMuted,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No predictions yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Generate a demand forecast to see GOODIE insights here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}