/// Domain entity representing Income.
class Income {
  final String id;
  final String familyId;
  final String userId;
  final String categoryId;
  final String? categoryName;
  final String? receivedBy;
  final String? receivedByName;
  final double amount;
  final String currency;
  final String incomeDate;
  final String title;
  final String? description;
  final DateTime? createdAt;

  const Income({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.categoryId,
    this.categoryName,
    this.receivedBy,
    this.receivedByName,
    required this.amount,
    this.currency = 'USD',
    required this.incomeDate,
    required this.title,
    this.description,
    this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['received_by']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String?,
      receivedBy: json['received_by']?.toString() ?? json['user_id']?.toString(),
      receivedByName: json['received_by_name'] as String?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      incomeDate: json['income_date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
