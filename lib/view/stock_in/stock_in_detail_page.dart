import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_management_inventory/viewmodel/stockin_viewmodel.dart';

import 'create_stock_in_page.dart';
// import 'package:flutter_management_inventory/view/stock_in/create_stock_in_page.dart'; // aktifkan kalau mau navigate ke edit

/* ===== Model kecil untuk memegang data di UI ===== */

class _StockInItem {
  final String productName;
  final String? productSubtitle;
  final int quantity;
  _StockInItem({required this.productName, this.productSubtitle, required this.quantity});
}

class _StockInDetailData {
  final int id;
  final String referenceNumber;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;
  final List<_StockInItem> items;

  _StockInDetailData({
    required this.id,
    required this.referenceNumber,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.items,
  });

  int get totalItems => items.length;
  int get totalQty => items.fold(0, (a, b) => a + b.quantity);
}

/* =================== PAGE =================== */

class StockInDetailPage extends StatefulWidget {
  const StockInDetailPage({super.key, required this.id});
  final dynamic id;

  @override
  State<StockInDetailPage> createState() => _StockInDetailPageState();
}

class _StockInDetailPageState extends State<StockInDetailPage> {
  final _vm = StockInViewmodel();

  bool _loading = true;
  String? _error;
  _StockInDetailData? _data;

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // NOTE: sesuaikan nama method VM kamu: getDetailStockIn / getHistoryStockInDetail
      final resp = await _vm.getDetailStockIn(id: '${widget.id}');
      if (resp.code != 200) {
        throw resp.message ?? 'Failed to load';
      }

      // Robust: resp.data bisa sudah "data" atau masih {data: {...}}
      final root = resp.data;
      final map = (root is Map && root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'] as Map)
          : Map<String, dynamic>.from((root as Map?) ?? const {});

      // Helper parser
      int _i(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
      String _s(v) => (v ?? '').toString();
      DateTime _dt(v) =>
          v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());

      final itemsRaw = (map['items'] as List? ?? const []);
      final items = itemsRaw.map<_StockInItem>((it) {
        final m = it as Map?;
        return _StockInItem(
          productName: _s(m?['product']?['name']),
          productSubtitle: _s(m?['product']?['brand']),
          quantity: _i(m?['quantity']),
        );
      }).toList();

      final parsed = _StockInDetailData(
        id: _i(map['id']),
        referenceNumber: _s(map['reference_number']),
        date: _dt(map['date']),
        createdBy: _s(map['user']?['name']),
        createdAt: _dt(map['created_at']),
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



  // === Actions ===
  Future<void> _editTransaction(dynamic id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID transaksi tidak ditemukan')),
      );
      return;
    }

    // loading mini
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      // asumsi ada API detail: getHistoryStockInDetail(id)
      final resp = await _vm.getDetailStockIn(id: id.toString());
      Navigator.pop(context); // tutup loading

      if (resp.code != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Gagal memuat detail')),
        );
        return;
      }

      final m = (resp.data as Map?) ?? const {};
      // helper parse
      String _s(v) => (v ?? '').toString();
      int _i(v) => int.tryParse('${v ?? 0}') ?? 0;
      DateTime _dt(v) => v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());

      final ref   = _s(m['reference_number']);
      final date  = _dt(m['date']);
      final notes = _s(m['notes']);
      final items = (m['items'] as List? ?? const []).map<Map<String, dynamic>>((it) {
        final x = it as Map?;
        return {
          'product_id'  : _i(x?['product_id']),
          'product_name': _s(x?['product']?['name'] ?? x?['product_name']),
          'quantity'    : _i(x?['quantity']),
        };
      }).toList();

      // buka form edit
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateStockInPage(
            isEdit: true,
            editId: id is int ? id : int.tryParse('$id'),
            initialReference: ref,
            initialDate: date,
            initialNotes: notes.isEmpty ? null : notes,
            initialItems: items,
          ),
        ),
      );
    } catch (err) {
      Navigator.pop(context); // tutup loading kalau masih terbuka
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')),
      );
    }
  }

  Future<void> _onDelete() async {
    if (_data == null) return;
    // TODO: panggil VM delete. Contoh:
    // final resp = await _vm.deleteStockIn(id: _data!.id);
    // if ((resp.code ?? 500) >= 300) throw resp.message ?? 'Delete failed';
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
    final fmtDate = DateFormat('MMMM d, yyyy');
    final fmtDateT = DateFormat('MMMM d, yyyy h:mm a');

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
              onPressed: () {
                _editTransaction(widget.id);
              },
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
            // subtitle ref number
            Text(
              _data!.referenceNumber,
              style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // ===== Transaction Information =====
            _Card(
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
            ),

            const SizedBox(height: 16),

            // ===== Items =====
            _TableCard(
              title: 'Items',
              headers: const ['PRODUCT', 'QUANTITY'],
              rows: _data!.items
                  .map((it) => _RowData(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    if ((it.productSubtitle ?? '').isNotEmpty)
                      Text(it.productSubtitle!,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                  ],
                ),
                right: Text('${it.quantity}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // ===== Summary =====
            LayoutBuilder(builder: (_, c) {
              final isWide = c.maxWidth >= 420;
              final leftCard = _SummaryCard(
                color: const Color(0xFFEFFDF3),
                icon: Icons.inventory_2_outlined,
                title: 'Total Items',
                value: '${_data!.totalItems}',
                valueColor: const Color(0xFF16A34A),
              );
              final rightCard = _SummaryCard(
                color: const Color(0xFFEFF4FF),
                icon: Icons.stacked_bar_chart_outlined,
                title: 'Total Quantity',
                value: '${_data!.totalQty}',
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
              return Column(children: [leftCard, const SizedBox(height: 10), rightCard]);
            }),
          ],
        ),
      ),
    );
  }
}

/* ====================== UI helpers (sama seperti punyamu) ====================== */

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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: valueColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
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
