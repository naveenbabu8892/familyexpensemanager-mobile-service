import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'vintage_card.dart';

/// Progress card displaying monthly budget allocation, amount spent, and warning badge.
class BudgetProgressCard extends StatelessWidget {
  final String categoryName;
  final String spentAmount;
  final String totalBudget;
  final double percentage;
  final String? warningBadge;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.categoryName,
    required this.spentAmount,
    required this.totalBudget,
    required this.percentage,
    this.warningBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _resolveStatusColor(percentage);
    final clampedRatio = (percentage / 100.0).clamp(0.0, 1.0);

    return VintageCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  warningBadge ?? '${percentage.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$spentAmount spent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amountSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalBudget budget',
                style: AppTypography.amountSmall.copyWith(
                  color: AppColors.dark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clampedRatio,
              minHeight: 7,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  static Color _resolveStatusColor(double percent) {
    if (percent > 100) return AppColors.exceeded;
    if (percent >= 90) return AppColors.terracotta;
    if (percent >= 75) return AppColors.mutedGold;
    return AppColors.olive;
  }
}
