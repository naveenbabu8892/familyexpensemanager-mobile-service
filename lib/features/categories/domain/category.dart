/// Domain entity representing a transaction category.
class Category {
  final String id;
  final String? familyId;
  final String name;
  final String icon;
  final String color;
  final String type; // 'expense' or 'income'
  final bool isDefault;
  final DateTime? createdAt;

  const Category({
    required this.id,
    this.familyId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#607D8B',
      type: json['type'] as String? ?? 'expense',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isIncome => type.toLowerCase() == 'income';
}
