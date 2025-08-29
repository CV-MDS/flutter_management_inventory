import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/viewmodel/stockin_viewmodel.dart';
import 'package:intl/intl.dart';

// ================== Model ringan utk UI ==================
class _StockOutItem {
  final String productName;
  final String? subtitle;     // brand/sku (opsional)
  final int currentStock;     // fallback ke product.stock_quantity
  final int qtyOut;           // quantity out
  final double amount;        // opsional; kalau tdk ada => 0
  _StockOutItem({
    required this.productName,
    this.subtitle,
    required this.currentStock,
    required this.qtyOut,
    required this.amount,
  });
}

class _StockOutDetailData {
  final int id;
  final String referenceNumber;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;
  final String? notes;
  final List<_StockOutItem> items;

  _StockOutDetailData({
    required this.id,
    required this.referenceNumber,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.items,
    this.notes,
  });

  int get totalItems => items.length;
  int get totalQty    => items.fold(0, (a, b) => a + b.qtyOut);
  double get totalAmount => items.fold(0.0, (a, b) => a + b.amount);
}

// ================== PAGE ==================
class StockOutDetailPage extends StatefulWidget {
  const StockOutDetailPage({super.key, required this.id});
  final dynamic id;

  @override
  State<StockOutDetailPage> createState() => _StockOutDetailPageState();
}

class _StockOutDetailPageState extends State<StockOutDetailPage> {
  final _vm = StockInViewmodel();

  bool _loading = true;
  String? _error;
  _StockOutDetailData? _data;

  // ============ FETCH ============
  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final resp = await _vm.getDetailStockOut(id: '${widget.id}');
      if ((resp.code ?? 500) >= 300) {
        throw resp.message ?? 'Failed to load';
      }

      // robust: {data:{...}} atau {...}
      final root = resp.data;
      final map = (root is Map && root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'] as Map)
          : Map<String, dynamic>.from((root as Map?) ?? const {});

      int i(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
      double d(v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0.0;
      String s(v) => (v ?? '').toString();
      DateTime dt(v) => v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());

      final itemsRaw = (map['items'] as List? ?? const []);
      final items = itemsRaw.map<_StockOutItem>((e) {
        final m = (e as Map?) ?? const {};
        final prod = (m['product'] as Map?) ?? const {};
        final name = s(prod['name']);
        final brand = s(prod['brand']);
        final currentStock = i(m['current_stock'] ?? prod['stock_quantity']);
        final qtyOut = i(m['quantity']);
        final amount = d(m['amount']); // kalau tdk ada di API, akan 0.0
        return _StockOutItem(
          productName: name,
          subtitle: brand.isEmpty ? null : brand,
          currentStock: currentStock,
          qtyOut: qtyOut,
          amount: amount,
        );
      }).toList();

      final parsed = _StockOutDetailData(
        id: i(map['id']),
        referenceNumber: s(map['reference_number']),
        date: dt(map['date']),
        createdBy: s(map['user']?['name']),
        createdAt: dt(map['created_at']),
        notes: s(map['notes']).isEmpty ? null : s(map['notes']),
        items: items,
      );

      if (!mounted) return;
      setState(() {
        _data = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ===== Actions (aman kalau halaman edit/delete belum ada) =====
  Future<void> _onEdit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Edit stock out')),
    );
  }

  Future<void> _onDelete() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: sambungkan ke endpoint Delete')),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

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
        title: const Text('Stock Out Details', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: ElevatedButton.icon(
              onPressed: _data == null ? null : _onEdit,
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
              onPressed: _data == null
                  ? null
                  : () async {
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
                if (ok == true) await _onDelete();
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // sub-title (reference)
            Text(
              _data!.referenceNumber,
              style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Info + Summary
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 640;

              Widget info = _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Transaction Information'),
                    const SizedBox(height: 14),
                    _Info(label: 'Reference Number', value: _data!.referenceNumber),
                    const SizedBox(height: 12),
                    _Info(label: 'Date', value: fmtDate.format(_data!.date)),
                    const SizedBox(height: 12),
                    _Info(label: 'Created By', value: _data!.createdBy),
                    const SizedBox(height: 12),
                    _Info(label: 'Created At', value: fmtDateT.format(_data!.createdAt)),
                  ],
                ),
              );

              Widget summary = _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Transaction Summary'),
                    const SizedBox(height: 14),
                    _KeyValueRow(label: 'Total Items', value: '${_data!.totalItems}'),
                    const Divider(height: 18),
                    _KeyValueRow(label: 'Total Quantity', value: '${_data!.totalQty}'),
                    if (_data!.totalAmount > 0) ...[
                      const Divider(height: 18),
                      _KeyValueRow(
                        label: 'Total Amount',
                        value: fmtMoney.format(_data!.totalAmount),
                      ),
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

            // Notes
            if ((_data!.notes ?? '').isNotEmpty)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Notes'),
                    const SizedBox(height: 12),
                    Text(_data!.notes!,
                        style: const TextStyle(
                            color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            if ((_data!.notes ?? '').isNotEmpty) const SizedBox(height: 16),

            // Items table
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Items'),
                  const SizedBox(height: 12),
                  const _ItemsHeader(),
                  const Divider(height: 0),
                  ..._data!.items.map((it) => _ItemRow(
                    name: it.productName,
                    subtitle: it.subtitle,
                    currentStock: it.currentStock,
                    qtyOut: it.qtyOut,
                    amountText: fmtMoney.format(it.amount),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Footer summaries
            LayoutBuilder(builder: (_, c) {
              final isWide = c.maxWidth >= 420;
              final left = _SummaryCard(
                color: const Color(0xFFFFF1F2),
                icon: Icons.inventory_2_outlined,
                title: 'Total Items',
                value: '${_data!.totalItems}',
                valueColor: const Color(0xFFDC2626),
              );
              final right = _SummaryCard(
                color: const Color(0xFFFFF7ED),
                icon: Icons.stacked_bar_chart_outlined,
                title: 'Total Quantity Out',
                value: '${_data!.totalQty}',
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

// ================== small UI helpers ==================
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
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
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
      style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w800, letterSpacing: .2),
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
          // product
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                if ((subtitle ?? '').isNotEmpty)
                  Text(subtitle!, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // current stock badge
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFFDF3), borderRadius: BorderRadius.circular(999)),
                child: const Text('',
                    style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          // qty & amount
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('$qtyOut',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(amountText,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: valueColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 18)),
            ]),
          ),
        ],
      ),
    );
  }
}
