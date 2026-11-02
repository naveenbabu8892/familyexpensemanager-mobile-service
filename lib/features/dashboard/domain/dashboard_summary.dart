/// Unified recent transaction item model for the dashboard feed.
class DashboardTransactionItem {
  final String id;
  final String type; // 'expense' or 'income'
  final String title;
  final double amount;
  final String currency;
  final String date;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String userName;
  final bool? isShared;
  final String? paymentMethod;
  final DateTime? createdAt;

  const DashboardTransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.currency = 'INR',
    required this.date,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.userName,
    this.isShared,
    this.paymentMethod,
    this.createdAt,
  });

  bool get isExpense => type.toLowerCase() == 'expense';

  factory DashboardTransactionItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    return DashboardTransactionItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'expense',
      title: json['title'] as String? ?? '',
      amount: parse(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      date: json['date'] as String? ?? '',
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      userName: json['user_name'] as String? ?? json['paid_by_name'] as String? ?? '',
      isShared: json['is_shared'] as bool?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Consolidated budget status indicators for dashboard period.
class DashboardBudgetStatus {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double percentageUsed;
  final bool hasWarning;
  final bool isExceeded;
  final int activeBudgetsCount;
  final int budgetsExceededCount;

  const DashboardBudgetStatus({
    this.totalBudget = 0.0,
    this.totalSpent = 0.0,
    this.totalRemaining = 0.0,
    this.percentageUsed = 0.0,
    this.hasWarning = false,
    this.isExceeded = false,
    this.activeBudgetsCount = 0,
    this.budgetsExceededCount = 0,
  });

  factory DashboardBudgetStatus.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    return DashboardBudgetStatus(
      totalBudget: parse(json['total_budget']),
      totalSpent: parse(json['total_spent']),
      totalRemaining: parse(json['total_remaining']),
      percentageUsed: parse(json['percentage_used']),
      hasWarning: json['has_warning'] as bool? ?? false,
      isExceeded: json['is_exceeded'] as bool? ?? false,
      activeBudgetsCount: json['active_budgets_count'] as int? ?? 0,
      budgetsExceededCount: json['budgets_exceeded_count'] as int? ?? 0,
    );
  }
}

/// Active period date window.
class DashboardPeriod {
  final String fromDate;
  final String toDate;
  final int? month;
  final int? year;

  const DashboardPeriod({
    required this.fromDate,
    required this.toDate,
    this.month,
    this.year,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      fromDate: json['from_date'] as String? ?? '',
      toDate: json['to_date'] as String? ?? '',
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }
}

/// Domain entity representing the complete family dashboard summary.
class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double remainingBalance;
  final double savingsRate;
  final double sharedExpenses;
  final double personalExpenses;
  final double myExpenses;
  final double spouseExpenses;
  final String currency;
  final DashboardPeriod? period;
  final DashboardBudgetStatus? budgetStatus;
  final List<DashboardTransactionItem> recentTransactions;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.remainingBalance,
    this.savingsRate = 0.0,
    required this.sharedExpenses,
    required this.personalExpenses,
    required this.myExpenses,
    required this.spouseExpenses,
    this.currency = 'INR',
    this.period,
    this.budgetStatus,
    this.recentTransactions = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    DashboardBudgetStatus? budget;
    if (json['budget_status'] is Map<String, dynamic>) {
      budget = DashboardBudgetStatus.fromJson(
        json['budget_status'] as Map<String, dynamic>,
      );
    }

    DashboardPeriod? period;
    if (json['period'] is Map<String, dynamic>) {
      period = DashboardPeriod.fromJson(
        json['period'] as Map<String, dynamic>,
      );
    }

    final txs = (json['recent_transactions'] as List? ?? [])
        .map((e) => DashboardTransactionItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardSummary(
      totalIncome: parse(json['total_income']),
      totalExpenses: parse(json['total_expenses']),
      remainingBalance: parse(json['remaining_balance']),
      savingsRate: parse(json['savings_rate']),
      sharedExpenses: parse(json['shared_expenses']),
      personalExpenses: parse(json['personal_expenses']),
      myExpenses: parse(json['my_expenses']),
      spouseExpenses: parse(json['spouse_expenses']),
      currency: json['currency'] as String? ?? 'INR',
      period: period,
      budgetStatus: budget,
      recentTransactions: txs,
    );
  }
}
