import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockOutDetail {
  final String referenceNumber;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;
  final String? notes;
  final List<StockOutItem> items;

  StockOutDetail({
    required this.referenceNumber,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.items,
    this.notes,
  });

  int get totalItems => items.length;
  int get totalQty    => items.fold(0, (a, b) => a + (b.qtyOut ?? 0));
  double get totalAmount =>
      items.fold(0.0, (a, b) => a + (b.amount ?? 0));
}

class StockOutItem {
  final String productName;
  final String? subtitle;     // brand/sku
  final int? currentStock;    // stock on hand sebelum/after (sesuaikan kebutuhanmu)
  final int? qtyOut;
  final double? amount;       // opsional, jika tidak ada tetap tampil $0.00

  StockOutItem({
    required this.productName,
    this.subtitle,
    this.currentStock,
    this.qtyOut,
    this.amount,
  });
}

class StockOutDetailPage extends StatelessWidget {
  const StockOutDetailPage({
    super.key,
    required this.data,
    this.onEdit,
    this.onDelete,
  });

  final StockOutDetail data;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);
    final fmtDate  = DateFormat('MMMM d, yyyy');
    final fmtDateT = DateFormat('MMMM d, yyyy h:mm a');
    final fmtMoney = NumberFormat.simpleCurrency(decimalDigits: 2);

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
        title: const Text('Stock Out Details',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: onDelete == null
                  ? null
                  : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content:
                    const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await onDelete!();
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Sub-title (reference)
            Text(
              data.referenceNumber,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // ===== Row: Transaction Info + Summary (stack on narrow) =====
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 640;
              final info = _Card(
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
              );

              final summary = _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Transaction Summary'),
                    const SizedBox(height: 14),
                    _KeyValueRow(label: 'Total Items', value: '${data.totalItems}'),
                    const Divider(height: 18),
                    _KeyValueRow(label: 'Total Quantity', value: '${data.totalQty}'),
                    if (data.totalAmount > 0) ...[
                      const Divider(height: 18),
                      _KeyValueRow(label: 'Total Amount', value: fmtMoney.format(data.totalAmount)),
                    ],
                  ],
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    Expanded(child: summary),
                  ],
                );
              }
              return Column(children: [info, const SizedBox(height: 12), summary]);
            }),

            const SizedBox(height: 16),

            // ===== Notes =====
            if ((data.notes ?? '').isNotEmpty)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Notes'),
                    const SizedBox(height: 12),
                    Text(
                      data.notes!,
                      style: const TextStyle(
                          color: Color(0xFF111827), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            if ((data.notes ?? '').isNotEmpty) const SizedBox(height: 16),

            // ===== Items Table =====
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Items'),
                  const SizedBox(height: 12),
                  _ItemsHeader(),
                  const Divider(height: 0),
                  ...data.items.map((it) => _ItemRow(
                    name: it.productName,
                    subtitle: it.subtitle,
                    currentStock: it.currentStock ?? 0,
                    qtyOut: it.qtyOut ?? 0,
                    amountText:
                    fmtMoney.format(it.amount ?? 0), // tampil $0.00 bila null
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Summary footer cards (orange) =====
            LayoutBuilder(builder: (_, c) {
              final isWide = c.maxWidth >= 420;
              final left = _SummaryCard(
                color: const Color(0xFFFFF1F2),
                icon: Icons.inventory_2_outlined,
                title: 'Total Items',
                value: '${data.totalItems}',
                valueColor: const Color(0xFFDC2626),
              );
              final right = _SummaryCard(
                color: const Color(0xFFFFF7ED),
                icon: Icons.stacked_bar_chart_outlined,
                title: 'Total Quantity Out',
                value: '${data.totalQty}',
                valueColor: const Color(0xFFF97316),
              );
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                );
              }
              return Column(children: [left, const SizedBox(height: 10), right]);
            }),
          ],
        ),
      ),
    );
  }
}

/* ================== small UI helpers ================== */

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
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)));
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
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontWeight: FontWeight.w700))),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF111827), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('PRODUCT')),
          Expanded(child: _HeaderText('CURRENT STOCK', alignRight: true)),
          Expanded(child: _HeaderText('QUANTITY OUT', alignRight: true)),
          Expanded(child: _HeaderText('AMOUNT', alignRight: true)),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text, {this.alignRight = false});
  final String text;
  final bool alignRight;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
        letterSpacing: .2,
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    this.subtitle,
    required this.currentStock,
    required this.qtyOut,
    required this.amountText,
  });

  final String name;
  final String? subtitle;
  final int currentStock;
  final int qtyOut;
  final String amountText;

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
          // Product
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                if ((subtitle ?? '').isNotEmpty)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Current stock (badge hijau)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$currentStock',
                  style: const TextStyle(
                      color: Color(0xFF16A34A), fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          // Qty out
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('$qtyOut',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ),
          ),
          // Amount
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(amountText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ),
          ),
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
                    style: const TextStyle(
                        color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        color: valueColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
