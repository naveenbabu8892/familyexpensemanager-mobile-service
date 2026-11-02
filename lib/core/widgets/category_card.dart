import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'category_icon.dart';
import 'vintage_card.dart';

/// Card representing a financial category with icon, title, and optional transaction amount.
class CategoryCard extends StatelessWidget {
  final String title;
  final String iconKey;
  final String? subtitle;
  final String? amount;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.iconKey,
    this.subtitle,
    this.amount,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VintageCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      border: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 1.8 : 1.0,
      ),
      color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryIcon(
                iconKey: iconKey,
                containerSize: 38,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headingSmall.copyWith(fontSize: 14),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.bodySmall,
            ),
          ],
          if (amount != null) ...[
            const SizedBox(height: 6),
            Text(
              amount!,
              style: AppTypography.amountSmall.copyWith(
                color: AppColors.dark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
