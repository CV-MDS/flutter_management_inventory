import 'category.dart'; // pastikan path import sesuai

class Product {
  final int id;
  final String name;
  final int categoryId;
  final String? description;
  final String? brand;
  final String? size;
  final String? color;
  final int stockQuantity;
  final int minStockLevel;
  final String? image; // path/gambar relatif dari API
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Category? category; // nested

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description,
    this.brand,
    this.size,
    this.color,
    required this.stockQuantity,
    required this.minStockLevel,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  /// Convenience: apakah stok di bawah/minimum?
  bool get isLowStock => stockQuantity <= minStockLevel;

  factory Product.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime? _d(dynamic v) =>
        v == null ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));

    return Product(
      id: _i(json['id']),
      name: (json['name'] ?? '').toString(),
      categoryId: _i(json['category_id']),
      description: json['description']?.toString(),
      brand: json['brand']?.toString(),
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      stockQuantity: _i(json['stock_quantity']),
      minStockLevel: _i(json['min_stock_level']),
      image: json['image']?.toString(),
      createdAt: _d(json['created_at']),
      updatedAt: _d(json['updated_at']),
      category: json['category'] is Map<String, dynamic>
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_id': categoryId,
    'description': description,
    'brand': brand,
    'size': size,
    'color': color,
    'stock_quantity': stockQuantity,
    'min_stock_level': minStockLevel,
    'image': image,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    if (category != null) 'category': category!.toJson(),
  };

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? description,
    String? brand,
    String? size,
    String? color,
    int? stockQuantity,
    int? minStockLevel,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      color: color ?? this.color,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}
