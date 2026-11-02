/// Domain entity representing a Family.
class Family {
  final String id;
  final String name;
  final String currency;
  final String timezone;
  final String createdBy;
  final DateTime? createdAt;
  final String? userRole;

  const Family({
    required this.id,
    required this.name,
    this.currency = 'USD',
    this.timezone = 'UTC',
    required this.createdBy,
    this.createdAt,
    this.userRole,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      timezone: json['timezone'] as String? ?? 'UTC',
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      userRole: json['user_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'timezone': timezone,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'user_role': userRole,
      };
}

/// Domain entity representing a Relationship Option.
class RelationshipOption {
  final String value;
  final String label;

  const RelationshipOption({required this.value, required this.label});

  factory RelationshipOption.fromJson(Map<String, dynamic> json) {
    return RelationshipOption(
      value: json['value'] as String? ?? 'other',
      label: json['label'] as String? ?? 'Other',
    );
  }
}

/// Domain entity representing a Family Member.
class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final String role; // 'owner' or 'member'
  final String relationship; // 'husband', 'wife', 'father', 'mother', etc.
  final String relationshipLabel; // 'Husband', 'Wife', 'Father', 'Mother', etc.
  final String status;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final DateTime? joinedAt;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    this.relationship = 'other',
    this.relationshipLabel = 'Other',
    this.status = 'active',
    this.fullName,
    this.email,
    this.avatarUrl,
    this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final rawRel = (json['relationship'] as String?)?.toLowerCase() ?? 'other';
    final rawLabel = json['relationship_label'] as String? ??
        (rawRel.isNotEmpty ? rawRel[0].toUpperCase() + rawRel.substring(1) : 'Other');

    return FamilyMember(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: json['role'] as String? ?? 'member',
      relationship: rawRel,
      relationshipLabel: rawLabel,
      status: json['status'] as String? ?? 'active',
      fullName: (json['name'] ?? json['user_full_name'] ?? json['full_name']) as String?,
      email: (json['user_email'] ?? json['email']) as String?,
      avatarUrl: (json['user_avatar_url'] ?? json['avatar_url']) as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isActive => status.toLowerCase() == 'active';
}
