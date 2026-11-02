import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/budget.dart';
import 'budget_form_dialog.dart';
import 'budget_list_controller.dart';

/// Comprehensive Budgets Screen displaying:
/// - Monthly budget summary & Month/Year picker
/// - Category, Budget, Spent, Remaining, Percentage
/// - Healthy (Olive), Warning 75% (Gold), Alert 90% (Terracotta), Exceeded (Dark red/brown)
/// - Add, Edit, and Delete Budget workflows
/// - Pull-to-refresh & Auto-refresh after expense changes
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(budgetPeriodProvider);
    final budgetsAsync = ref.watch(budgetListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(budgetListControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Month-Year Selector Bar
            _buildMonthSelector(context, ref, period),

            // 2. Budgets Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  await ref.read(budgetListControllerProvider.notifier).refresh();
                },
                child: budgetsAsync.when(
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: EmptyState(
                              icon: Icons.savings_outlined,
                              title: 'No Budgets for ${DateFormatter.formatMonthYear(period.month, period.year)}',
                              message:
                                  'Set category budgets to keep your family spending on track.',
                              actionLabel: 'Add Budget',
                              onAction: () => _openAddBudget(context, period),
                            ),
                          ),
                        ],
                      );
                    }

                    // Compute overall period totals
                    final totalAllocated = budgets.fold<double>(0.0, (sum, b) => sum + b.amount);
                    final totalSpent = budgets.fold<double>(0.0, (sum, b) => sum + b.amountSpent);
                    final totalRemaining = totalAllocated - totalSpent;
                    final totalPercentage = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0.0;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // Summary Card
                        _buildOverviewCard(
                          monthName: DateFormatter.formatMonthYear(period.month, period.year),
                          allocated: totalAllocated,
                          spent: totalSpent,
                          remaining: totalRemaining,
                          percentage: totalPercentage,
                        ),
                        const SizedBox(height: 20),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Category Budgets',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                            ),
                            Text(
                              '${budgets.length} total',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List of Budget Cards
                        ...budgets.map((budget) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBudgetCard(context, ref, budget),
                          );
                        }),
                        const SizedBox(height: 80), // Fab spacing
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: LoadingState(message: 'Loading monthly budgets...'),
                  ),
                  error: (error, _) => Center(
                    child: ErrorState(
                      message: 'Failed to load budgets. Pull down to retry.',
                      onRetry: () =>
                          ref.read(budgetListControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Budget',
        icon: Icons.add_rounded,
        onPressed: () => _openAddBudget(context, period),
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    BudgetPeriodState period,
  ) {
    final monthYearLabel = DateFormatter.formatMonthYear(period.month, period.year);

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
            tooltip: 'Previous Month',
            onPressed: () {
              ref.read(budgetPeriodProvider.notifier).previous();
            },
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pickMonthYear(context, ref, period),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    monthYearLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            tooltip: 'Next Month',
            onPressed: () {
              ref.read(budgetPeriodProvider.notifier).next();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String monthName,
    required double allocated,
    required double spent,
    required double remaining,
    required double percentage,
  }) {
    final statusColor = _resolveStatusColor(percentage, remaining < 0);
    final clampedRatio = (percentage / 100.0).clamp(0.0, 1.0);

    return VintageCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName Overview',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.dark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  remaining < 0
                      ? 'Exceeded'
                      : '${percentage.toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewMetric(
                'Budget',
                CurrencyFormatter.formatNoDecimals(allocated),
                AppColors.dark,
              ),
              _buildOverviewMetric(
                'Spent',
                CurrencyFormatter.formatNoDecimals(spent),
                statusColor,
              ),
              _buildOverviewMetric(
                'Remaining',
                remaining < 0
                    ? '-${CurrencyFormatter.formatNoDecimals(remaining.abs())}'
                    : CurrencyFormatter.formatNoDecimals(remaining),
                remaining < 0 ? AppColors.exceeded : AppColors.olive,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clampedRatio,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) {
    final statusColor = budget.statusColor;
    final clampedRatio = (budget.percentageUsed / 100.0).clamp(0.0, 1.0);

    final formattedSpent = CurrencyFormatter.formatNoDecimals(budget.amountSpent);
    final formattedBudget = CurrencyFormatter.formatNoDecimals(budget.amount);
    final formattedRemaining = budget.remainingAmount < 0
        ? '-${CurrencyFormatter.formatNoDecimals(budget.remainingAmount.abs())}'
        : CurrencyFormatter.formatNoDecimals(budget.remainingAmount);

    return VintageCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Name, and Status Badge + Context Menu
          Row(
            children: [
              CategoryIcon(
                iconKey: budget.categoryIcon ?? budget.categoryName ?? 'category',
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                containerSize: 42,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName ?? 'Category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${budget.percentageUsed.toStringAsFixed(0)}% of limit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  budget.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Actions Popup Menu (Edit, Delete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary, size: 20),
                onSelected: (action) {
                  if (action == 'edit') {
                    _openEditBudget(context, budget);
                  } else if (action == 'delete') {
                    _confirmDelete(context, ref, budget);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.dark),
                        SizedBox(width: 10),
                        Text('Edit Budget'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.terracotta),
                        SizedBox(width: 10),
                        Text('Delete Budget',
                            style: TextStyle(color: AppColors.terracotta)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Financial Comparison: Spent / Budget & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$formattedSpent / $formattedBudget',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              Text(
                '${budget.percentageUsed.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar with color transitions
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clampedRatio,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          // Remaining Metric Footnote
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.remainingAmount < 0 ? 'Over budget by' : 'Remaining to spend',
                style: AppTypography.bodySmall,
              ),
              Text(
                formattedRemaining,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: budget.remainingAmount < 0
                      ? AppColors.exceeded
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _resolveStatusColor(double percent, bool isExceeded) {
    if (isExceeded || percent > 100.0) return AppColors.exceeded;
    if (percent >= 90.0) return AppColors.terracotta;
    if (percent >= 75.0) return AppColors.mutedGold;
    return AppColors.olive;
  }

  void _openAddBudget(BuildContext context, BudgetPeriodState period) {
    BudgetFormDialog.show(
      context,
      initialMonth: period.month,
      initialYear: period.year,
    );
  }

  void _openEditBudget(BuildContext context, Budget budget) {
    BudgetFormDialog.show(
      context,
      initialBudget: budget,
      initialMonth: budget.month,
      initialYear: budget.year,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Budget?'),
        content: Text(
          'Are you sure you want to delete the ${budget.categoryName ?? 'category'} budget for ${DateFormatter.formatMonthYear(budget.month, budget.year)}?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          VintageOutlinedButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(budgetListControllerProvider.notifier)
          .deleteBudget(budget.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Budget deleted successfully' : 'Failed to delete budget',
            ),
            backgroundColor: success ? AppColors.dark : AppColors.terracotta,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pickMonthYear(
    BuildContext context,
    WidgetRef ref,
    BudgetPeriodState period,
  ) {
    int selectedM = period.month;
    int selectedY = period.year;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Select Month & Year'),
            content: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedM,
                    isExpanded: true,
                    items: List.generate(12, (i) {
                      final m = i + 1;
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(DateFormatter.formatMonthYear(m, 2026).split(' ').first),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedM = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedY,
                    isExpanded: true,
                    items: [2024, 2025, 2026, 2027, 2028].map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedY = val);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              VintageOutlinedButton(
                text: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              VintageButton(
                text: 'Apply',
                onPressed: () {
                  ref.read(budgetPeriodProvider.notifier).setPeriod(selectedM, selectedY);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
