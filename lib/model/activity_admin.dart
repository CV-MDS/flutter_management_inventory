// activity_admin.dart
import 'user.dart';

class ActivityAdmin {
  final int? id;
  final int? userId;
  final String? action;
  final String? description;
  final String? modelType;
  final String? modelId; // null di contoh; biarkan String? agar fleksibel
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  const ActivityAdmin({
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

  factory ActivityAdmin.fromJson(Map<String, dynamic> json) => ActivityAdmin(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    action: json['action'] as String?,
    description: json['description'] as String?,
    modelType: json['model_type'] as String?,
    modelId: json['model_id']?.toString(),
    ipAddress: json['ip_address'] as String?,
    userAgent: json['user_agent'] as String?,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
    user: json['user'] != null ? User.fromJson(json['user']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'action': action,
    'description': description,
    'model_type': modelType,
    'model_id': modelId,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'user': user?.toJson(),
  };

  ActivityAdmin copyWith({
    int? id,
    int? userId,
    String? action,
    String? description,
    String? modelType,
    String? modelId,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
  }) {
    return ActivityAdmin(
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

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

// Helper opsional untuk list:
extension ActivityAdminListParsing on List<dynamic>? {
  List<ActivityAdmin> toActivityAdminList() =>
      (this ?? []).map((e) => ActivityAdmin.fromJson(e as Map<String, dynamic>)).toList();
}
