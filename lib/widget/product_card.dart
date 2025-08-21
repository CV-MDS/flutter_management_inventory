import 'package:flutter/material.dart';

import '../color.dart';
import '../model/product.dart';

class ProductCard extends StatelessWidget {
  final Product data;
  final VoidCallback? onView;

  const ProductCard({super.key, required this.data, this.onView});

  @override
  Widget build(BuildContext context) {
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
          // Image placeholder
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: data.imageUrl == null || data.imageUrl!.isEmpty
                  ? const Center(
                child: Icon(Icons.image, size: 72, color: Color(0xFFBEC3CF)),
              )
                  : ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  data.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Color(0xFFBEC3CF)),
                  ),
                ),
              ),
            ),
          ),

          // Texts
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              data.name,
              style: const TextStyle(
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: C.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'T-Shirts', // subtitle sesuai screenshot
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF969EAE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stock row
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
                  '${data.stock} Unit',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: C.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // View button dark
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