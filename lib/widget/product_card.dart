import 'package:flutter/material.dart';
import '../color.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final int stock;
  final String? imageUrl;        // bisa absolute atau relative
  final bool lowStock;
  final VoidCallback? onView;

  /// Opsional: base URL untuk image relative dari API.
  /// Contoh: "https://your-domain/storage"
  final String? imageBaseUrl;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.stock,
    this.imageUrl,
    this.lowStock = false,
    this.onView,
    this.imageBaseUrl,
  });

  String? get _resolvedImage {
    final path = imageUrl?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (imageBaseUrl == null || imageBaseUrl!.isEmpty) return null;
    var base = imageBaseUrl!;
    var p = path;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (p.startsWith('/')) p = p.substring(1);
    return '$base/$p';
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = lowStock ? const Color(0xFFFF3B30) : C.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: _resolvedImage == null
                  ? const Center(
                child: Icon(Icons.image, size: 72, color: Color(0xFFBEC3CF)),
              )
                  : ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _resolvedImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Color(0xFFBEC3CF)),
                  ),
                ),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: C.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Category (subtitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF969EAE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Stock',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF969EAE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$stock Unit',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // View Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
