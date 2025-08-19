import 'dart:convert';

import 'user.dart';
import 'recent_activity.dart';

class Dashboard {
  final User? user;
  final String? role;
  final int? totalUsers;
  final int? totalProducts;
  final int? totalCategories;
  final List<RecentActivity> recentActivities;
  final int? todayActivities;

  const Dashboard({
    this.user,
    this.role,
    this.totalUsers,
    this.totalProducts,
    this.totalCategories,
    this.recentActivities = const [],
    this.todayActivities,
  });

  bool get isAdmin => role?.toLowerCase() == 'admin';

  Dashboard copyWith({
    User? user,
    String? role,
    int? totalUsers,
    int? totalProducts,
    int? totalCategories,
    List<RecentActivity>? recentActivities,
    int? todayActivities,
  }) {
    return Dashboard(
      user: user ?? this.user,
      role: role ?? this.role,
      totalUsers: totalUsers ?? this.totalUsers,
      totalProducts: totalProducts ?? this.totalProducts,
      totalCategories: totalCategories ?? this.totalCategories,
      recentActivities: recentActivities ?? this.recentActivities,
      todayActivities: todayActivities ?? this.todayActivities,
    );
  }

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      role: json['role'] as String?,
      totalUsers: _asInt(json['totalUsers']),
      totalProducts: _asInt(json['totalProducts']),
      totalCategories: _asInt(json['totalCategories']),
      recentActivities: (json['recentActivities'] as List? ?? const [])
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayActivities: _asInt(json['todayActivities']),
    );
  }

  /// Convenience: parse dari String JSON
  static Dashboard? fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return Dashboard.fromJson(decoded);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'user': user?.toJson(),
    'role': role,
    'totalUsers': totalUsers,
    'totalProducts': totalProducts,
    'totalCategories': totalCategories,
    'recentActivities':
    recentActivities.map((e) => e.toJson()).toList(),
    'todayActivities': todayActivities,
  };
}

/// ===== Helpers =====
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
