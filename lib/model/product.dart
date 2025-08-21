class Product {
  final String name;
  final String category;
  final int stock;
  final String? imageUrl;
  const Product({
    required this.name,
    required this.category,
    required this.stock,
    this.imageUrl,
  });
}