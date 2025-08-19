import 'dart:convert';

class RecentActivity {
  final int? id;
  final int? userId;
  final String? action;
  final String? description;
  final String? modelType;
  final int? modelId;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ActivityUser? user;

  const RecentActivity({
    this.id,
    this.userId,
    this.action,
    this.description,
    this.modelType,
    this.modelId,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  RecentActivity copyWith({
    int? id,
    int? userId,
    String? action,
    String? description,
    String? modelType,
    int? modelId,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
    ActivityUser? user,
  }) {
    return RecentActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      description: description ?? this.description,
      modelType: modelType ?? this.modelType,
      modelId: modelId ?? this.modelId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      action: json['action'] as String?,
      description: json['description'] as String?,
      modelType: json['model_type'] as String?,
      modelId: _asInt(json['model_id']),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      user: json['user'] is Map<String, dynamic>
          ? ActivityUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'model_type': modelType,
      'model_id': modelId,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': _toIso(createdAt),
      'updated_at': _toIso(updatedAt),
      'user': user?.toJson(),
    };
  }

  /// Helper untuk parse list langsung dari JSON (List<dynamic> / String).
  static List<RecentActivity> listFrom(dynamic source) {
    if (source is String) {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return decoded
            .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    }
    if (source is List) {
      return source
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

class ActivityUser {
  final int? id;
  final String? name;
  final String? email;
  final String? roles;
  final DateTime? emailVerifiedAt;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityUser({
    this.id,
    this.name,
    this.email,
    this.roles,
    this.emailVerifiedAt,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityUser.fromJson(Map<String, dynamic> json) {
    return ActivityUser(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'email_verified_at': _toIso(emailVerifiedAt),
      'deleted_at': _toIso(deletedAt),
      'created_at': _toIso(createdAt),
      'updated_at': _toIso(updatedAt),
    };
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
