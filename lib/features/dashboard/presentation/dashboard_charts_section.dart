import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/vintage_card.dart';
import '../../reports/domain/reports_models.dart';

/// Vintage-themed chart components for dashboard:
/// 1. Expense by Category
/// 2. Husband vs Wife (Member contribution)
/// 3. Income vs Expense
class DashboardChartsSection extends StatelessWidget {
  final List<CategoryReportItem> categories;
  final List<MemberReportItem> members;
  final double totalIncome;
  final double totalExpenses;
  final double myExpenses;
  final double spouseExpenses;
  final String currency;

  const DashboardChartsSection({
    super.key,
    required this.categories,
    required this.members,
    required this.totalIncome,
    required this.totalExpenses,
    required this.myExpenses,
    required this.spouseExpenses,
    this.currency = 'INR',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Income vs Expense Chart
        _buildIncomeVsExpenseCard(context),
        const SizedBox(height: 16),

        // 2. Husband vs Wife Spending Comparison Chart
        _buildHusbandVsWifeCard(context),
        const SizedBox(height: 16),

        // 3. Expense by Category Distribution Chart
        _buildExpenseByCategoryCard(context),
      ],
    );
  }

  /// Income vs Expense Bar Comparison Card
  Widget _buildIncomeVsExpenseCard(BuildContext context) {
    final maxAmount = math.max(totalIncome, totalExpenses);
    final incomeRatio = maxAmount > 0 ? (totalIncome / maxAmount).clamp(0.0, 1.0) : 0.0;
    final expenseRatio = maxAmount > 0 ? (totalExpenses / maxAmount).clamp(0.0, 1.0) : 0.0;

    final incomeFormatted = CurrencyFormatter.format(totalIncome, currency: currency);
    final expenseFormatted = CurrencyFormatter.format(totalExpenses, currency: currency);

    return VintageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Income vs Expense',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cashflow',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Income Bar Row
          _buildBarRow(
            label: 'Total Income',
            amount: incomeFormatted,
            ratio: incomeRatio,
            color: AppColors.olive,
            backgroundColor: AppColors.oliveLight,
            icon: Icons.arrow_downward_rounded,
          ),
          const SizedBox(height: 14),

          // Expense Bar Row
          _buildBarRow(
            label: 'Total Expenses',
            amount: expenseFormatted,
            ratio: expenseRatio,
            color: AppColors.terracotta,
            backgroundColor: AppColors.terracottaLight,
            icon: Icons.arrow_upward_rounded,
          ),

          if (totalIncome > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Savings',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalIncome - totalExpenses, currency: currency),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (totalIncome - totalExpenses >= 0)
                          ? AppColors.olive
                          : AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Husband vs Wife / Member Contribution Card
  Widget _buildHusbandVsWifeCard(BuildContext context) {
    // If members report is populated, use members. Otherwise use myExpenses & spouseExpenses.
    final hasMembersData = members.isNotEmpty;
    final totalMemberExpenses = hasMembersData
        ? members.fold<double>(0.0, (sum, m) => sum + m.totalSpent)
        : (myExpenses + spouseExpenses);

    return VintageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Husband vs Wife',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Partner Split',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (hasMembersData) ...[
            for (int i = 0; i < members.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _buildMemberRow(
                name: members[i].relationshipLabel.isNotEmpty && members[i].relationshipLabel != 'Other'
                    ? '${members[i].memberName} · ${members[i].relationshipLabel}'
                    : members[i].memberName,
                amount: CurrencyFormatter.format(members[i].totalSpent, currency: currency),
                percentage: members[i].percentage,
                ratio: totalMemberExpenses > 0
                    ? (members[i].totalSpent / totalMemberExpenses).clamp(0.0, 1.0)
                    : 0.0,
                color: _getMemberColor(i),
              ),
            ],
          ] else ...[
            // Fallback to myExpenses vs spouseExpenses
            _buildMemberRow(
              name: 'My Expenses',
              amount: CurrencyFormatter.format(myExpenses, currency: currency),
              percentage: totalMemberExpenses > 0
                  ? (myExpenses / totalMemberExpenses) * 100
                  : 0.0,
              ratio: totalMemberExpenses > 0
                  ? (myExpenses / totalMemberExpenses).clamp(0.0, 1.0)
                  : 0.0,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            _buildMemberRow(
              name: 'Spouse Expenses',
              amount: CurrencyFormatter.format(spouseExpenses, currency: currency),
              percentage: totalMemberExpenses > 0
                  ? (spouseExpenses / totalMemberExpenses) * 100
                  : 0.0,
              ratio: totalMemberExpenses > 0
                  ? (spouseExpenses / totalMemberExpenses).clamp(0.0, 1.0)
                  : 0.0,
              color: AppColors.mutedGold,
            ),
          ],
        ],
      ),
    );
  }

  /// Expense by Category Distribution Card
  Widget _buildExpenseByCategoryCard(BuildContext context) {
    return VintageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Expense by Category',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Breakdown',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No category expenses recorded for this month.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else ...[
            // Multi-segment horizontal proportion bar
            _buildCategoryDistributionBar(categories),
            const SizedBox(height: 16),

            // Category rows
            for (final cat in categories.take(5)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _parseColor(cat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${cat.percentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyFormatter.format(cat.totalAmount, currency: currency),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBarRow({
    required String label,
    required String amount,
    required double ratio,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberRow({
    required String name,
    required String amount,
    required double percentage,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionBar(List<CategoryReportItem> items) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: items.map((cat) {
            final flex = (cat.percentage * 10).round().clamp(1, 1000);
            return Expanded(
              flex: flex,
              child: Container(
                color: _parseColor(cat.color),
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.primary;
    final clean = colorStr.replaceAll('#', '');
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    }
    return AppColors.terracotta;
  }

  Color _getMemberColor(int index) {
    const palette = [
      AppColors.primary,
      AppColors.mutedGold,
      AppColors.olive,
      AppColors.terracotta,
      AppColors.dark,
    ];
    return palette[index % palette.length];
  }
}
