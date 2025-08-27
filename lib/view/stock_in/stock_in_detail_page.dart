import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockInDetail {
  final String referenceNumber;
  final DateTime date;          // tanggal transaksi (tanpa jam)
  final String createdBy;       // nama user
  final DateTime createdAt;     // waktu dibuat
  final List<StockInItem> items;

  StockInDetail({
    required this.referenceNumber,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.items,
  });

  int get totalItems => items.length;
  int get totalQty   => items.fold(0, (a, b) => a + (b.quantity ?? 0));
}

class StockInItem {
  final String productName;
  final String? productSubtitle; // mis. brand/sku, opsional
  final int? quantity;

  StockInItem({required this.productName, this.productSubtitle, this.quantity});
}

class StockInDetailPage extends StatelessWidget {
  const StockInDetailPage({
    super.key,
    required this.data,
    this.onEdit,
    this.onDelete,
  });

  final StockInDetail data;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);
    final fmtDate  = DateFormat('MMMM d, yyyy');      // August 27, 2025
    final fmtDateT = DateFormat('MMMM d, yyyy h:mm a'); // August 27, 2025 8:40 AM

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF111827),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stock In Details', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: onDelete == null ? null : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await onDelete!();
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // subtitle ref number di bawah title (seperti screenshot)
            Text(
              data.referenceNumber,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // ===== Transaction Information Card =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Transaction Information'),
                  const SizedBox(height: 14),
                  _Info(label: 'Reference Number', value: data.referenceNumber),
                  const SizedBox(height: 12),
                  _Info(label: 'Date', value: fmtDate.format(data.date)),
                  const SizedBox(height: 12),
                  _Info(label: 'Created By', value: data.createdBy),
                  const SizedBox(height: 12),
                  _Info(label: 'Created At', value: fmtDateT.format(data.createdAt)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Items Table =====
            _TableCard(
              title: 'Items',
              headers: const ['PRODUCT', 'QUANTITY'],
              rows: data.items.map((it) => _RowData(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.productName,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    if ((it.productSubtitle ?? '').isNotEmpty)
                      Text(it.productSubtitle!,
                          style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                  ],
                ),
                right: Text('${it.quantity ?? 0}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              )).toList(),
            ),

            const SizedBox(height: 16),

            // ===== Summary cards (2 kolom, stack jika sempit) =====
            LayoutBuilder(builder: (_, c) {
              final isWide = c.maxWidth >= 420;
              final leftCard = _SummaryCard(
                color: const Color(0xFFEFFDF3),
                icon: Icons.inventory_2_outlined,
                title: 'Total Items',
                value: '${data.totalItems}',
                valueColor: const Color(0xFF16A34A),
              );
              final rightCard = _SummaryCard(
                color: const Color(0xFFEFF4FF),
                icon: Icons.stacked_bar_chart_outlined,
                title: 'Total Quantity',
                value: '${data.totalQty}',
                valueColor: const Color(0xFF2563EB),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: leftCard),
                    const SizedBox(width: 12),
                    Expanded(child: rightCard),
                  ],
                );
              }
              return Column(
                children: [
                  leftCard,
                  const SizedBox(height: 10),
                  rightCard,
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/* ====================== Small UI helpers ====================== */

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
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
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)));
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.title, required this.headers, required this.rows});
  final String title;
  final List<String> headers;
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 12),
          _Header(headers: headers),
          const Divider(height: 0),
          ...rows.map((r) => _RowWidget(row: r)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.headers});
  final List<String> headers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(headers.first,
                style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w800, letterSpacing: .2)),
          ),
          Expanded(
            child: Text(headers.last,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w800, letterSpacing: .2)),
          ),
        ],
      ),
    );
  }
}

class _RowData {
  final Widget left;
  final Widget right;
  _RowData({required this.left, required this.right});
}

class _RowWidget extends StatelessWidget {
  const _RowWidget({required this.row});
  final _RowData row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: row.left),
          Expanded(child: Align(alignment: Alignment.centerRight, child: row.right)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: valueColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
