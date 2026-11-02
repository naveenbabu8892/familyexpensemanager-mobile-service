/// Domain entity representing an Expense.
class Expense {
  final String id;
  final String familyId;
  final String createdBy;
  final String paidBy;
  final String categoryId;
  final String? categoryName;
  final String? paidByName;
  final double amount;
  final String currency;
  final String expenseDate;
  final String paymentMethod;
  final String title;
  final String? description;
  final bool isShared;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.paidBy,
    required this.categoryId,
    this.categoryName,
    this.paidByName,
    required this.amount,
    this.currency = 'USD',
    required this.expenseDate,
    required this.paymentMethod,
    required this.title,
    this.description,
    this.isShared = true,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      paidBy: json['paid_by']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String?,
      paidByName: json['paid_by_name'] as String?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      expenseDate: json['expense_date'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isShared: json['is_shared'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
