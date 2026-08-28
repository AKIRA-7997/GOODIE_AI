import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/status_badge.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inventory')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                onChanged: provider.setQuery,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textMuted),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: provider.filter == 'All',
                    onTap: () => provider.setFilter('All'),
                  ),
                  _FilterChip(
                    label: 'Good (${provider.goodCount})',
                    selected: provider.filter == 'Good',
                    onTap: () => provider.setFilter('Good'),
                    color: AppColors.success,
                  ),
                  _FilterChip(
                    label: 'Low (${provider.lowCount})',
                    selected: provider.filter == 'Low',
                    onTap: () => provider.setFilter('Low'),
                    color: AppColors.warning,
                  ),
                  _FilterChip(
                    label: 'Critical (${provider.criticalCount})',
                    selected: provider.filter == 'Critical',
                    onTap: () => provider.setFilter('Critical'),
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(label: item.status),
                                ],
                              ),
                              const Divider(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Current Stock',
                                      value: '${item.currentStock}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Predicted Demand',
                                      value: '${item.predictedDemand}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withOpacity(0.18)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? activeColor : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? activeColor : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
