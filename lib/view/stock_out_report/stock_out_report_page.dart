import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_color.dart';
import '../../viewmodel/report_viewmodel.dart';

class StockOutReportPage extends StatefulWidget {
  const StockOutReportPage({super.key});

  @override
  State<StockOutReportPage> createState() => _StockOutReportPageState();
}

class _StockOutReportPageState extends State<StockOutReportPage> {
  final _fmtHdr = DateFormat('dd/MM/yyyy');
  final _fmtRow = DateFormat('dd/MM/yyyy');

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  DateTime? _from;
  DateTime? _to;

  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _rows = [];
  final List<Map<String, dynamic>> _filtered = [];

  int get _totalTrans => _filtered.length;
  int get _totalItems =>
      _filtered.fold<int>(0, (a, b) => a + (b['total_qty'] as int));

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _fromCtrl.text = _fmtHdr.format(_from!);
    _toCtrl.text = _fmtHdr.format(_to!);
    _fetch();
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  /* ====================== FETCH & PARSING ====================== */

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _filtered.clear();
    });

    try {
      final resp = await ReportViewmodel().stockOutsReports();
      if ((resp.code ?? 500) >= 300) throw resp.message ?? 'Failed';

      final root = resp.data;
      final map = (root is Map && root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'] as Map)
          : (root is Map<String, dynamic> ? root : <String, dynamic>{});
      final rawRows = (map['rows'] as List?) ??
          (map['items'] as List?) ??
          (root is List ? root : const []);

      int toInt(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
      DateTime toDt(v) =>
          v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());
      String s(v) => (v ?? '').toString();

      final parsed = rawRows.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);

        final date = toDt(m['date']);
        final user = s((m['user'] as Map?)?['name']);
        final ref = s(m['reference_number']);

        final items = (m['items'] as List? ?? const []).cast<Map>();
        final totalQty =
        items.fold<int>(0, (a, it) => a + toInt(it['quantity']));

        final names = <String>[];
        for (final it in items) {
          final prod = (it['product'] as Map?) ?? const {};
          final name = s(prod['name']);
          if (name.isNotEmpty) names.add(name);
        }
        final itemsText = names.isEmpty
            ? '-'
            : (names.length <= 2
            ? names.join(', ')
            : '${names.take(2).join(', ')} +${names.length - 2}');

        return {
          'date': date,
          'ref': ref,
          'items_text': itemsText,
          'total_qty': totalQty,
          'user': user,
        };
      }).toList();

      setState(() {
        _rows.addAll(parsed);
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final from = _from;
    final to = _to;

    final res = _rows.where((r) {
      final dt = r['date'] as DateTime;
      final a = from == null ? true : !dt.isBefore(from);
      final b = to == null ? true : !dt.isAfter(to);
      return a && b;
    }).toList()
      ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    _filtered
      ..clear()
      ..addAll(res);
    setState(() {});
  }

  /* ====================== UI HELPERS ====================== */

  Future<void> _pickDate({required bool from}) async {
    final init = from ? (_from ?? DateTime.now()) : (_to ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    if (from) {
      _from = DateTime(picked.year, picked.month, picked.day);
      _fromCtrl.text = _fmtHdr.format(_from!);
    } else {
      _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      _toCtrl.text = _fmtHdr.format(_to!);
    }
    _applyFilter();
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rentang tanggal terlebih dahulu')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final Uint8List bytes = await ReportViewmodel()
          .stockOutPDFBytes(from: _from, to: _to);

      final dir = await getTemporaryDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/stock_out_$ts.pdf');
      await file.writeAsBytes(bytes, flush: true);

      try {
        final res = await OpenFilex.open(file.path);
        if (res.type != ResultType.done) {
          await Share.shareXFiles([XFile(file.path)], text: 'Stock Out Report');
        }
      } on MissingPluginException {
        await Share.shareXFiles([XFile(file.path)], text: 'Stock Out Report');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /* ====================== BUILD ====================== */

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF111827),
        titleSpacing: 0,
        title: const Text('Laporan Stock Out', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errState()
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporan data stock out dengan filter tanggal',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Filter Card
              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(builder: (_, c) {
                  final wide = c.maxWidth >= 680;
                  final mid = c.maxWidth >= 480;

                  Widget dateFrom = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Mulai',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fromCtrl,
                        readOnly: true,
                        onTap: () => _pickDate(from: true),
                        decoration: _dec('dd/MM/yyyy'),
                      ),
                    ],
                  );

                  Widget dateTo = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Akhir',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _toCtrl,
                        readOnly: true,
                        onTap: () => _pickDate(from: false),
                        decoration: _dec('dd/MM/yyyy'),
                      ),
                    ],
                  );

                  Widget actions = Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_from != null &&
                              _to != null &&
                              _from!.isAfter(_to!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Tanggal mulai tidak boleh melebihi tanggal akhir')),
                            );
                            return;
                          }
                          _applyFilter();
                        },
                        icon: const Icon(Icons.filter_alt_rounded, size: 18),
                        label: const Text('Filter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _exporting ? null : _exportPdf,
                        icon: _exporting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(_exporting ? 'Exporting...' : 'Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  );

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: dateFrom),
                        const SizedBox(width: 12),
                        Expanded(child: dateTo),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  }
                  if (mid) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: dateFrom),
                            const SizedBox(width: 12),
                            Expanded(child: dateTo),
                          ],
                        ),
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dateFrom,
                      const SizedBox(height: 10),
                      dateTo,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  );
                }),
              ),

              const SizedBox(height: 14),

              // Summary
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Total Transaksi',
                      value: '$_totalTrans',
                      tint: const Color(0xFFEFF4FF),
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Total Items',
                      value: '$_totalItems',
                      tint: const Color(0xFFEFFDF3),
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Table
              _TableCard(
                title: 'Data Stock Out',
                headers: const ['NO', 'TANGGAL', 'REFERENSI', 'ITEMS', 'TOTAL QTY', 'USER'],
                rows: List.generate(_filtered.length, (i) {
                  final r = _filtered[i];
                  return [
                    Text('${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    Text(_fmtRow.format(r['date']),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      r['ref'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(r['items_text'], overflow: TextOverflow.ellipsis),
                    Text('${r['total_qty']}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      r['user'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ];
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? 'Error',
              style:
              const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/* ====================== Small widgets ====================== */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
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
                        color: color, fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.title,
    required this.headers, // header full: ['NO','TANGGAL','REFERENSI','ITEMS','TOTAL QTY','USER']
    required this.rows,    // setiap row punya 6 widget sesuai urutan header full
  });

  final String title;
  final List<String> headers;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // ===== mode compact utk layar sempit =====
        final bool compact = c.maxWidth < 520;

        // header & kolom yang ditampilkan
        final List<String> hdrs = compact
            ? const ['NO', 'REFERENSI', 'ITEMS', 'QTY', 'USER'] // Tanggal disembunyikan, Total Qty => QTY
            : headers;

        // mapping row: ambil subset kolom bila compact
        final List<List<Widget>> displayRows = compact
            ? rows
            .map((r) => <Widget>[r[0], r[2], r[3], r[4], r[5]]) // drop index 1 (Tanggal)
            .toList()
            : rows;

        // fleks kolom
        final List<int> colFlex = compact
            ? const [1, 4, 2, 2, 3]     // NO, REF, ITEMS, QTY, USER
            : const [1, 2, 3, 4, 2, 3]; // NO, TGL, REF, ITEMS, QTY, USER

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
              const SizedBox(height: 12),

              // ===== header =====
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: List.generate(hdrs.length, (i) {
                    return Expanded(
                      flex: colFlex[i],
                      child: Text(
                        hdrs[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false, // biar tidak pecah baris
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Divider(height: 0),

              // ===== rows =====
              if (displayRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No data', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
                  ),
                )
              else
                ...List.generate(displayRows.length, (i) {
                  final r = displayRows[i];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(r.length, (j) {
                        // indeks bantu biar rapih
                        final qtyIndex  = compact ? 3 : 4;
                        final userIndex = compact ? 4 : 5;
                        final isItemsCol = compact ? j == 2 : j == 3;

                        return Expanded(
                          flex: colFlex[j],
                          child: Padding(
                            // beri jarak kecil di kanan QTY & kiri USER supaya tidak “nempel”
                            padding: EdgeInsets.only(
                              right: j == qtyIndex ? 8 : 0,
                              left:  j == userIndex ? 8 : 0,
                            ),
                            child: isItemsCol
                                ? DefaultTextStyle(
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                              child: r[j],
                            )
                                : Align(
                              alignment: j == qtyIndex ? Alignment.centerRight : Alignment.centerLeft,
                              child: r[j],
                            ),
                          ),
                        );

                      }),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
