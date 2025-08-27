import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../color.dart';
import '../../model/product.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    this.imageUrl,
    this.onEdit,
  });

  /// Data produk
  final Product product;

  /// URL gambar absolute (kalau backend-mu perlu baseUrl + path)
  final String? imageUrl;

  /// Handler tombol Edit
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final createdAt = _tryParse(product.createdAt);
    final updatedAt = _tryParse(product.updatedAt);
    final dateFmt = DateFormat('MMM d, yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        foregroundColor: C.textDark,
        titleSpacing: 0,
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ===== Header title & subtitle =====
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 26,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: C.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Product details and information',
              style: TextStyle(fontSize: 13, color: Color(0xFF9AA1B2), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // ===== Product Image Card =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Product Image'),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ProductImage(url: imageUrl),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== Basic Information Card =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Basic Information'),
                  const SizedBox(height: 12),
                  _TwoColRow(
                    left: _InfoItem(label: 'Product Name', value: product.name),
                    right: _InfoItem(
                      label: 'Category',
                      valueWidget: _CategoryChip(product.category?.name ?? '-'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoColRow(
                    left: _InfoItem(label: 'Brand', value: product.brand?.isNotEmpty == true ? product.brand! : 'Not specified'),
                    right: _InfoItem(label: 'Color', value: (product.color?.isNotEmpty == true) ? product.color! : 'Not specified'),
                  ),
                  const SizedBox(height: 12),
                  _TwoColRow(
                    left: _InfoItem(label: 'Size', value: (product.size?.isNotEmpty == true) ? product.size! : 'Not specified'),
                    right: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _InfoItem(label: 'Description', value: (product.description?.isNotEmpty == true) ? product.description! : 'Not specified'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== Stock Card =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Stock'),
                  const SizedBox(height: 12),
                  _TwoColRow(
                    left: _InfoItem(
                      label: 'Current Stock',
                      valueWidget: Text(
                        '${product.stockQuantity} units',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: product.isLowStock ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    right: _InfoItem(
                      label: 'Min Stock Level',
                      value: '${product.minStockLevel ?? 0} units',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== Metadata Card =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Metadata'),
                  const SizedBox(height: 12),
                  _TwoColRow(
                    left: _InfoItem(
                      label: 'Created',
                      value: createdAt != null ? dateFmt.format(createdAt) : '-',
                    ),
                    right: _InfoItem(
                      label: 'Last Updated',
                      value: updatedAt != null ? dateFmt.format(updatedAt) : '-',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _tryParse(dynamic d) {
    if (d == null) return null;
    if (d is DateTime) return d;
    // backend kadang string ISO8601
    try { return DateTime.parse(d.toString()); } catch (_) { return null; }
  }
}

/* ----------------------- Small UI helpers ----------------------- */

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.textDark),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, this.value, this.valueWidget});
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '-',
            style: const TextStyle(fontSize: 14, color: C.textDark, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _TwoColRow extends StatelessWidget {
  const _TwoColRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final isWide = c.maxWidth > 360;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        // stack vertikal di layar sempit
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      // placeholder default mirip screenshot
      return Container(
        color: const Color(0xFFF9FAFB),
        alignment: Alignment.center,
        child: Icon(Icons.account_circle, size: 120, color: Colors.blue.shade300),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF9FAFB),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF9CA3AF)),
      ),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
