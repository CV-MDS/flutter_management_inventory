class UserManagementUser {
  final int? id;
  final String name;
  final String email;
  final String roles;
  final DateTime? emailVerifiedAt;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? active;

  const UserManagementUser({
    this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.emailVerifiedAt,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.active
  });

  factory UserManagementUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDT(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return UserManagementUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roles: json['roles'] ?? '',
      emailVerifiedAt: parseDT(json['email_verified_at']),
      deletedAt: parseDT(json['deleted_at']),
      createdAt: parseDT(json['created_at']),
      updatedAt: parseDT(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'roles': roles,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  UserManagementUser copyWith({
    int? id,
    String? name,
    String? email,
    String? roles,
    DateTime? emailVerifiedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
  }) {
    return UserManagementUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active
    );
  }

  /// Helper kalau API balikin list user
  static List<UserManagementUser> listFromJson(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserManagementUser.fromJson)
          .toList();
    }
    return const [];
  }
}
