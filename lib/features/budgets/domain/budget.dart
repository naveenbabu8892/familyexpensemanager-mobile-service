import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Domain entity representing a monthly Budget with calculated usage.
class Budget {
  final String id;
  final String familyId;
  final String categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double amount;
  final int month;
  final int year;
  final String createdBy;
  final double amountSpent;
  final double remainingAmount;
  final double percentageUsed;
  final String? warningStatus; // 'warning_75', 'warning_90', 'exceeded_100', 'normal'
  final DateTime? createdAt;

  const Budget({
    required this.id,
    required this.familyId,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    this.amountSpent = 0.0,
    this.remainingAmount = 0.0,
    this.percentageUsed = 0.0,
    this.warningStatus,
    this.createdAt,
  });

  double get spentAmount => amountSpent;

  bool get isExceeded => percentageUsed > 100.0 || remainingAmount < 0;

  Color get statusColor {
    if (percentageUsed > 100.0 || remainingAmount < 0) {
      return AppColors.exceeded; // Dark red/brown when exceeded
    }
    if (percentageUsed >= 90.0) {
      return AppColors.terracotta; // Terracotta around 90%
    }
    if (percentageUsed >= 75.0) {
      return AppColors.mutedGold; // Gold around 75%
    }
    return AppColors.olive; // Olive for healthy budgets
  }

  String get statusLabel {
    if (percentageUsed > 100.0 || remainingAmount < 0) {
      return 'Exceeded';
    }
    if (percentageUsed >= 90.0) {
      return 'Near Limit';
    }
    if (percentageUsed >= 75.0) {
      return 'Warning';
    }
    return 'Healthy';
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    return Budget(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      amount: parse(json['amount']),
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
      createdBy: json['created_by'] as String? ?? '',
      amountSpent: parse(json['amount_spent'] ?? json['spent_amount']),
      remainingAmount: parse(json['remaining_amount']),
      percentageUsed: parse(json['percentage_used']),
      warningStatus: json['warning_status'] as String? ?? json['warning_level'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
