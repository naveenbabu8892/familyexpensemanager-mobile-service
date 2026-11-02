import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modern premium card with warm ivory surface, delicate border, and soft shadow.
class VintageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const VintageCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.border,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(18);

    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: effectiveRadius,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: Padding(
        padding: padding,
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Backward compatibility alias for AppCard.
typedef AppCard = VintageCard;
