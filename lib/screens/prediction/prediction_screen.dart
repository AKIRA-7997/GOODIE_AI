import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/prediction_result.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/section_card.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Demand Prediction'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SectionCard(
              title: 'Prediction Inputs',
              subtitle: 'Fill in the details to forecast demand',
              child: Column(
                children: [
                  _DropdownField(
                    label: 'Store',
                    value: provider.selectedStore,
                    items: provider.stores,
                    onChanged: provider.setStore,
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: 'Product',
                    value: provider.selectedProduct,
                    items: provider.products,
                    onChanged: provider.setProduct,
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 18),
                  _SliderField(
                    label: 'Price',
                    value: provider.price,
                    min: 5,
                    max: 500,
                    display: '\$${provider.price.toStringAsFixed(2)}',
                    onChanged: provider.setPrice,
                  ),
                  _SliderField(
                    label: 'Discount',
                    value: provider.discount,
                    min: 0,
                    max: 70,
                    display: '${provider.discount.toStringAsFixed(0)}%',
                    onChanged: provider.setDiscount,
                  ),
                  _SliderField(
                    label: 'Temperature',
                    value: provider.temperature,
                    min: -10,
                    max: 45,
                    display: '${provider.temperature.toStringAsFixed(0)}°C',
                    onChanged: provider.setTemperature,
                  ),
                  const SizedBox(height: 6),
                  _SwitchField(
                    label: 'Holiday',
                    subtitle: 'Is this a holiday period?',
                    value: provider.isHoliday,
                    onChanged: provider.setHoliday,
                  ),
                  _SwitchField(
                    label: 'Promotion',
                    subtitle: 'Active marketing promotion?',
                    value: provider.hasPromotion,
                    onChanged: provider.setPromotion,
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'Predict Demand',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: provider.isLoading,
                    onPressed: provider.canPredict
                        ? () async {
                      await provider.predict();

                      final prediction = provider.result;

                      if (prediction != null && context.mounted) {
                        context
                            .read<DashboardProvider>()
                            .addPrediction(prediction);
                      }
                    }
                        : null,
                  ),
                ],
              ),
            ),

            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: provider.errorMessage!),
            ],

            if (provider.result != null) ...[
              const SizedBox(height: 20),
              _PredictionResultCard(result: provider.result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: AppColors.cardAlt,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: AppColors.textMuted,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                display,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchField extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchField({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.secondary,
          title: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionResultCard extends StatelessWidget {
  final PredictionResult result;

  const _PredictionResultCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MainPredictionCard(result: result),
          const SizedBox(height: 16),
          _InventoryOverviewCard(result: result),
          const SizedBox(height: 16),
          _BusinessAdviceCard(result: result),
          const SizedBox(height: 16),
          _DemandFactorsCard(result: result),
        ],
      ),
    );
  }
}

class _MainPredictionCard extends StatelessWidget {
  final PredictionResult result;

  const _MainPredictionCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.product} · ${result.store}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _StatusBadge(
                label: result.stockStatus,
                color: _stockStatusColor(result.stockStatus),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  label: 'Expected Demand',
                  value: '${result.expectedDemand}',
                  suffix: 'units',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultStat(
                  label: 'Recommended Stock',
                  value: '${result.recommendedInventory}',
                  suffix: 'units',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Model confidence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  result.confidenceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stockStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'low':
        return Colors.orangeAccent;
      case 'adequate':
        return Colors.amber;
      case 'healthy':
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
  }
}

class _InventoryOverviewCard extends StatelessWidget {
  final PredictionResult result;

  const _InventoryOverviewCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Inventory Intelligence',
      subtitle: 'Stock position based on predicted demand',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Current Inventory',
                  value: '${result.currentInventory}',
                  suffix: 'units',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightTile(
                  icon: Icons.security_outlined,
                  label: 'Safety Stock',
                  value: '${result.safetyStock}',
                  suffix: 'units',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  icon: result.requiresRestock
                      ? Icons.add_shopping_cart_rounded
                      : Icons.check_circle_outline_rounded,
                  label: 'Restock Required',
                  value: '${result.restockQuantity}',
                  suffix: 'units',
                  accentColor: result.requiresRestock
                      ? Colors.orangeAccent
                      : Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightTile(
                  icon: Icons.warehouse_outlined,
                  label: 'Surplus',
                  value: '${result.surplusQuantity}',
                  suffix: 'units',
                  accentColor: result.hasSurplus
                      ? Colors.amberAccent
                      : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DemandChangeRow(result: result),
          const SizedBox(height: 12),
          _RiskRow(result: result),
        ],
      ),
    );
  }
}

class _DemandChangeRow extends StatelessWidget {
  final PredictionResult result;

  const _DemandChangeRow({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isIncreasing = result.demandIsIncreasing;
    final isDecreasing = result.demandIsDecreasing;

    final Color color = isIncreasing
        ? Colors.greenAccent
        : isDecreasing
        ? Colors.redAccent
        : AppColors.textMuted;

    final IconData icon = isIncreasing
        ? Icons.trending_up_rounded
        : isDecreasing
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return _InformationRow(
      icon: icon,
      label: 'Demand change',
      value:
      '${result.demandChangeLabel} (${result.demandChangePercentage.toStringAsFixed(1)}%)',
      valueColor: color,
    );
  }
}

class _RiskRow extends StatelessWidget {
  final PredictionResult result;

  const _RiskRow({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return _InformationRow(
      icon: Icons.warning_amber_rounded,
      label: 'Stock-out risk',
      value: result.riskLevel,
      valueColor: _riskColor(result.riskLevel),
    );
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return AppColors.textMuted;
    }
  }
}

class _BusinessAdviceCard extends StatelessWidget {
  final PredictionResult result;

  const _BusinessAdviceCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'GOODIE Recommendation',
      subtitle: 'Suggested business action',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.businessAdvice,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandFactorsCard extends StatelessWidget {
  final PredictionResult result;

  const _DemandFactorsCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Demand Factors',
      subtitle: 'Conditions affecting this forecast',
      child: result.demandFactors.isEmpty
          ? const Text(
        'No major demand factors were detected.',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
      )
          : Column(
        children: result.demandFactors
            .map(
              (factor) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    factor,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final Color? accentColor;

  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            suffix,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: valueColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.7),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          suffix,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}