import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Maps category string identifiers into curated Material icons with vintage tint containers.
class CategoryIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final double containerSize;

  const CategoryIcon({
    super.key,
    required this.iconKey,
    this.size = 20,
    this.color,
    this.backgroundColor,
    this.containerSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIcon(iconKey);
    final iconColor = color ?? AppColors.primary;
    final bg = backgroundColor ?? AppColors.primaryLight;

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size,
          color: iconColor,
        ),
      ),
    );
  }

  static IconData _resolveIcon(String key) {
    switch (key.toLowerCase()) {
      case 'grocery':
      case 'shopping_cart':
        return Icons.shopping_basket_outlined;
      case 'rent':
      case 'home':
        return Icons.roofing_rounded;
      case 'electricity':
      case 'bolt':
        return Icons.bolt_rounded;
      case 'internet':
      case 'wifi':
        return Icons.wifi_rounded;
      case 'fuel':
      case 'local_gas_station':
        return Icons.local_gas_station_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'medical':
      case 'hospital':
        return Icons.healing_rounded;
      case 'education':
      case 'school':
        return Icons.school_outlined;
      case 'travel':
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'entertainment':
      case 'movie':
        return Icons.theater_comedy_outlined;
      case 'insurance':
      case 'security':
        return Icons.shield_outlined;
      case 'salary':
      case 'payments':
        return Icons.account_balance_wallet_outlined;
      case 'freelance':
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.category_outlined;
    }
  }
}
