import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Prominent numeric monetary input with currency prefix and large editorial typography.
class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final String? label;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const AmountInput({
    super.key,
    required this.controller,
    this.currencySymbol = '₹',
    this.label,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencySymbol,
                style: const TextStyle(
                  fontFamily: AppTypography.serifFont,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: autofocus,
                  onChanged: onChanged,
                  cursorColor: AppColors.primary,
                  style: AppTypography.amountHero.copyWith(
                    color: AppColors.dark,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: AppTypography.serifFont,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryBeige,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
