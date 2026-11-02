/// Monthly report item representing income, expense, and savings for a month.
class MonthlyReportItem {
  final int month;
  final String monthName;
  final int year;
  final double income;
  final double expense;
  final double savings;
  final double savingsRate;

  const MonthlyReportItem({
    required this.month,
    this.monthName = '',
    required this.year,
    required this.income,
    required this.expense,
    required this.savings,
    this.savingsRate = 0.0,
  });

  factory MonthlyReportItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    return MonthlyReportItem(
      month: json['month'] as int? ?? 1,
      monthName: json['month_name'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      income: parse(json['income']),
      expense: parse(json['expenses'] ?? json['expense']),
      savings: parse(json['net_savings'] ?? json['savings']),
      savingsRate: parse(json['savings_rate']),
    );
  }
}

/// Category spending or earnings breakdown item.
class CategoryReportItem {
  final String categoryId;
  final String categoryName;
  final String? icon;
  final String color;
  final String type;
  final double totalAmount;
  final double percentage;
  final int transactionCount;

  const CategoryReportItem({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    required this.color,
    this.type = 'expense',
    required this.totalAmount,
    required this.percentage,
    this.transactionCount = 0,
  });

  factory CategoryReportItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    return CategoryReportItem(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String? ?? 'General',
      icon: json['category_icon'] as String?,
      color: json['category_color'] as String? ?? json['color'] as String? ?? '#607D8B',
      type: json['type'] as String? ?? 'expense',
      totalAmount: parse(json['amount'] ?? json['total_amount']),
      percentage: parse(json['percentage']),
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }
}

/// Family member contribution report item.
class MemberReportItem {
  final String memberId;
  final String memberName;
  final String? avatarUrl;
  final String role;
  final String relationship;
  final String relationshipLabel;
  final double totalSpent;
  final double percentage;
  final double personalExpenses;
  final double sharedExpenses;
  final double incomeEarned;

  const MemberReportItem({
    required this.memberId,
    required this.memberName,
    this.avatarUrl,
    required this.role,
    this.relationship = 'other',
    this.relationshipLabel = 'Other',
    required this.totalSpent,
    required this.percentage,
    this.personalExpenses = 0.0,
    this.sharedExpenses = 0.0,
    this.incomeEarned = 0.0,
  });

  factory MemberReportItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    final rawRel = (json['relationship'] as String?)?.toLowerCase() ?? 'other';
    final rawLabel = json['relationship_label'] as String? ??
        (rawRel.isNotEmpty ? rawRel[0].toUpperCase() + rawRel.substring(1) : 'Other');

    return MemberReportItem(
      memberId: json['user_id']?.toString() ?? json['member_id']?.toString() ?? '',
      memberName: json['user_name'] as String? ?? json['member_name'] as String? ?? 'Member',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      relationship: rawRel,
      relationshipLabel: rawLabel,
      totalSpent: parse(json['total_paid'] ?? json['total_spent']),
      percentage: parse(json['percentage_of_total'] ?? json['percentage']),
      personalExpenses: parse(json['personal_expenses']),
      sharedExpenses: parse(json['shared_expenses']),
      incomeEarned: parse(json['income_earned']),
    );
  }
}

/// Payment method breakdown report item.
class PaymentMethodReportItem {
  final String paymentMethod;
  final double amount;
  final double percentage;
  final int transactionCount;

  const PaymentMethodReportItem({
    required this.paymentMethod,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  factory PaymentMethodReportItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    return PaymentMethodReportItem(
      paymentMethod: json['payment_method'] as String? ?? 'other',
      amount: parse(json['amount']),
      percentage: parse(json['percentage']),
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }
}

/// Category distribution report response container with authoritative backend total.
class CategoryReportResponse {
  final String fromDate;
  final String toDate;
  final String currency;
  final String type;
  final double totalAmount;
  final List<CategoryReportItem> categories;

  const CategoryReportResponse({
    required this.fromDate,
    required this.toDate,
    this.currency = 'INR',
    this.type = 'expense',
    required this.totalAmount,
    required this.categories,
  });

  factory CategoryReportResponse.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    final catList = (json['categories'] as List<dynamic>? ?? [])
        .map((e) => CategoryReportItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return CategoryReportResponse(
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
      currency: json['currency'] as String? ?? 'INR',
      type: json['type'] as String? ?? 'expense',
      totalAmount: parse(json['total_amount']),
      categories: catList,
    );
  }
}

/// Member comparison report response container with authoritative backend totals.
class MemberReportResponse {
  final String fromDate;
  final String toDate;
  final String currency;
  final double totalExpenses;
  final double totalIncome;
  final double sharedExpenses;
  final double personalExpenses;
  final List<MemberReportItem> members;

  const MemberReportResponse({
    required this.fromDate,
    required this.toDate,
    this.currency = 'INR',
    required this.totalExpenses,
    required this.totalIncome,
    required this.sharedExpenses,
    required this.personalExpenses,
    required this.members,
  });

  factory MemberReportResponse.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    final memList = (json['members'] as List<dynamic>? ?? [])
        .map((e) => MemberReportItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return MemberReportResponse(
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
      currency: json['currency'] as String? ?? 'INR',
      totalExpenses: parse(json['total_expenses']),
      totalIncome: parse(json['total_income']),
      sharedExpenses: parse(json['shared_expenses']),
      personalExpenses: parse(json['personal_expenses']),
      members: memList,
    );
  }
}

/// Payment method report response container with authoritative backend total.
class PaymentMethodReportResponse {
  final String fromDate;
  final String toDate;
  final String currency;
  final double totalAmount;
  final List<PaymentMethodReportItem> paymentMethods;

  const PaymentMethodReportResponse({
    required this.fromDate,
    required this.toDate,
    this.currency = 'INR',
    required this.totalAmount,
    required this.paymentMethods,
  });

  factory PaymentMethodReportResponse.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) =>
        (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;

    final methodsList = (json['payment_methods'] as List<dynamic>? ?? [])
        .map((e) => PaymentMethodReportItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaymentMethodReportResponse(
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
      currency: json['currency'] as String? ?? 'INR',
      totalAmount: parse(json['total_amount']),
      paymentMethods: methodsList,
    );
  }
}
