import 'dart:convert';

class User {
  final int? id;
  final String? name;
  final String? email;
  final String? roles;
  final DateTime? emailVerifiedAt;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    this.id,
    this.name,
    this.email,
    this.roles,
    this.emailVerifiedAt,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? roles,
    DateTime? emailVerifiedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      email: json['email'] as String?,
      roles: json['roles'] as String?,
      emailVerifiedAt: _asDate(json['email_verified_at']),
      deletedAt: _asDate(json['deleted_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'roles': roles,
    'email_verified_at': _toIso(emailVerifiedAt),
    'deleted_at': _toIso(deletedAt),
    'created_at': _toIso(createdAt),
    'updated_at': _toIso(updatedAt),
  };

  /// Parse List<User> dari `List` atau `String` JSON.
  static List<User> listFrom(dynamic source) {
    if (source is String) {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return decoded
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    }
    if (source is List) {
      return source
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

/// ===== Helpers aman parse int & datetime =====
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

String? _toIso(DateTime? d) => d?.toUtc().toIso8601String();
