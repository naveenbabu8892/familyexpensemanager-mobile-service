import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'category_icon.dart';

/// Clean transaction list item showing category icon, title, metadata badges, and prominent amount.
class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String amount;
  final bool isExpense;
  final bool isShared;
  final String? payer;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    this.isExpense = true,
    this.isShared = true,
    this.payer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isExpense ? AppColors.terracotta : AppColors.olive;
    final prefix = isExpense ? '-' : '+';
    final formattedAmount = amount.startsWith('+') || amount.startsWith('-')
        ? amount
        : '$prefix$amount';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CategoryIcon(
              iconKey: category,
              color: amountColor,
              backgroundColor: isExpense ? AppColors.terracottaLight : AppColors.oliveLight,
              containerSize: 44,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        date,
                        style: AppTypography.bodySmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isShared ? AppColors.primary : AppColors.mutedGold)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isShared ? 'Shared' : 'Personal',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isShared ? AppColors.primary : AppColors.mutedGold,
                          ),
                        ),
                      ),
                      if (payer != null)
                        Text(
                          '• $payer',
                          style: AppTypography.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formattedAmount,
              style: AppTypography.amountMedium.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
