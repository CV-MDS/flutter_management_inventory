import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/view/stock_out/stock_out_detail_page.dart';
import 'package:flutter_management_inventory/viewmodel/stockin_viewmodel.dart';
import 'package:intl/intl.dart';

import 'package:flutter_management_inventory/view/stock_out/create_stock_out_page.dart';
// ganti path di bawah sesuai struktur project-mu

class StockOutPage extends StatefulWidget {
  const StockOutPage({super.key});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  // ------- Filter state -------
  final _search = TextEditingController();
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  DateTime? _dateFrom, _dateTo;

  // ------- Data/fetch state -------
  final _vm = StockInViewmodel();
  final _scroll = ScrollController();

  final List<Map<String, dynamic>> _all = [];      // data mentah dari server
  final List<Map<String, dynamic>> _filtered = []; // setelah filter tanggal lokal

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 1;
  int _lastPage = 1;

  // ------- Formatters -------
  final _fmtUi = DateFormat('MMM d, yyyy'); // Aug 13, 2025
  final _fmtPick = DateFormat('dd/MM/yyyy');

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _fetchFirst();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    super.dispose();
  }

  // ================= FETCHING =================
  Future<void> _fetchFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _lastPage = 1;
      _all.clear();
      _filtered.clear();
    });
    await _fetch(page: 1, reset: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    await _fetch(page: _page + 1, reset: false);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _fetch({required int page, required bool reset}) async {
    try {
      final resp = await _vm.getHistoryStockOut(
        page: page,
        perPage: 10,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );

      if (resp.code == 200) {
        // response: { data: { items: [...], pagination: {...} } }
        final data = (resp.data as Map?) ?? const {};
        final items = (data['items'] as List? ?? const []);

        // map untuk UI
        final parsed = items.map<Map<String, dynamic>>((raw) {
          final m = raw as Map;

          String _s(dynamic v) => (v ?? '').toString();

          DateTime _parseDt(dynamic v) {
            if (v is DateTime) return v;
            return DateTime.tryParse('${v ?? ''}') ?? DateTime.now();
          }

          final ref = _s(m['reference_number']);
          final date = _parseDt(m['date']);
          final itemsList = (m['items'] as List? ?? const []);
          final by = _s((m['user'] as Map?)?['name']);

          return {
            'ref': ref,
            'date': date,
            'items': itemsList.length,
            'by': by,
          };
        }).toList();

        // pagination
        final pagination = (data['pagination'] as Map?) ?? const {};
        final current = int.tryParse('${pagination['current_page'] ?? 1}') ?? 1;
        final last = int.tryParse('${pagination['last_page'] ?? 1}') ?? 1;

        setState(() {
          _page = current;
          _lastPage = last;
          if (reset) {
            _all
              ..clear()
              ..addAll(parsed);
          } else {
            _all.addAll(parsed);
          }
          _applyFilterLocal(); // terapkan date range lokal
        });
      } else {
        setState(() => _error = resp.message ?? 'Failed to load');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message ?? 'Failed to load')),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
      _fetchMore();
    }
  }

  // ============== FILTER LOKAL (tanggal) ==============
  void _applyFilterLocal() {
    final from = _dateFrom;
    final to = _dateTo;

    final res = _all.where((e) {
      final dt = e['date'] as DateTime;
      final afterFrom = from == null ? true : !dt.isBefore(from);
      final beforeTo  = to   == null ? true : !dt.isAfter(to);
      return afterFrom && beforeTo;
    }).toList();

    _filtered
      ..clear()
      ..addAll(res);
    setState(() {});
  }

  // ============== UI helpers ==============
  Future<void> _pickDate({required bool from}) async {
    final initial = from ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    if (from) {
      _dateFrom = DateTime(picked.year, picked.month, picked.day);
      _dateFromCtrl.text = _fmtPick.format(_dateFrom!);
    } else {
      _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      _dateToCtrl.text = _fmtPick.format(_dateTo!);
    }
    _applyFilterLocal();
  }

  InputDecoration _dec(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFFDC2626)), // merah
      ),
    );
  }

  Future<void> _onPressFilter() async {
    // search dikirim ke server
    await _fetchFirst();
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: const Text('Stock Out Transactions', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateStockOutPage()),
                );
                if (created == true) _fetchFirst();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Stock Out'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchFirst,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchFirst,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text('Manage outgoing stock transactions',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // ===== Filter Card (responsif) =====
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 680;
                    final mid  = c.maxWidth >= 420;

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _search,
                                  decoration: _dec('Reference number...', prefix: const Icon(Icons.search)),
                                  onSubmitted: (_) => _onPressFilter(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date From', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _dateFromCtrl,
                                  readOnly: true,
                                  decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                                  onTap: () => _pickDate(from: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date To', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _dateToCtrl,
                                  readOnly: true,
                                  decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                                  onTap: () => _pickDate(from: false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 96,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _onPressFilter,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Filter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (mid) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _search,
                            decoration: _dec('Reference number...', prefix: const Icon(Icons.search)),
                            onSubmitted: (_) => _onPressFilter(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date From', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _dateFromCtrl,
                                      readOnly: true,
                                      decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                                      onTap: () => _pickDate(from: true),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date To', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _dateToCtrl,
                                      readOnly: true,
                                      decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                                      onTap: () => _pickDate(from: false),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 88,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _onPressFilter,
                                  icon: const Icon(Icons.search, size: 18),
                                  label: const Text('Filter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Kompak
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _search,
                          decoration: _dec('Reference number...', prefix: const Icon(Icons.search)),
                          onSubmitted: (_) => _onPressFilter(),
                        ),
                        const SizedBox(height: 12),
                        const Text('Date From', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _dateFromCtrl,
                          readOnly: true,
                          decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                          onTap: () => _pickDate(from: true),
                        ),
                        const SizedBox(height: 12),
                        const Text('Date To', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _dateToCtrl,
                          readOnly: true,
                          decoration: _dec('dd/mm/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                          onTap: () => _pickDate(from: false),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _onPressFilter,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              const Text('Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),

              if (_filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Text('No data', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Column(
                  children: [
                    ..._filtered.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 4))],
                          border: Border.all(color: const Color(0xFFF0F2F5)),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Reference + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['ref'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(_fmtUi.format(e['date']),
                                          style: const TextStyle(
                                              color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${e['items']} items',
                                          style: const TextStyle(
                                              color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                      ),
                                      Text('By ${e['by']}',
                                          style: const TextStyle(
                                              color: Color(0xFF4B5563), fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right: actions
                            Column(
                              children: [
                                IconButton(
                                  tooltip: 'View',
                                  onPressed: () => _openDetail(Map<String, dynamic>.from(e)),
                                  icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF475569)),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Edit ${e['ref']}')),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(Map<String, dynamic> e) async {
    final id = (e['id'] ?? '').toString();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID transaksi tidak ditemukan')),
      );
      return;
    }

    // Loading dialog simpel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Panggil endpoint detail
      final resp = await _vm.getHistoryStockOut(
        perPage: 10,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );
      if (resp.code != 200) {
        Navigator.pop(context); // tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Gagal memuat detail')),
        );
        return;
      }

      final data = (resp.data as Map?) ?? const {};
      // -------- mapping aman (null-safe) --------
      String _s(dynamic v) => (v ?? '').toString();
      DateTime _dt(dynamic v) =>
          v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());
      int _i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
      double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0.0;

      final itemsRaw = (data['items'] as List? ?? const []);

      // Bangun model StockOutDetail (dari file detail page yang sudah kubuat)
      final detail = StockOutDetail(
        referenceNumber: _s(data['reference_number']),
        date: _dt(data['date']),
        createdBy: _s((data['user'] as Map?)?['name']),
        createdAt: _dt(data['created_at']),
        notes: _s(data['notes']),
        items: itemsRaw.map((it) {
          final m = it as Map?;
          return StockOutItem(
            productName: _s(m?['product']?['name'] ?? m?['product_name']),
            subtitle: _s(m?['product']?['brand'] ?? m?['brand'] ?? m?['sku']),
            currentStock: _i(m?['current_stock']),
            qtyOut: _i(m?['quantity'] ?? m?['qty_out']),
            amount: _d(m?['amount']),
          );
        }).toList(),
      );

      Navigator.pop(context); // tutup loading

      // Navigate ke halaman detail
      // (import StockOutDetailPage & modelnya)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StockOutDetailPage(
            data: detail,
            onEdit: () {
              // TODO: navigate ke halaman edit menggunakan id yang sama
            },
            onDelete: () async {
              // TODO: panggil delete di VM: await _vm.deleteStockOut(id: id);
              // setelah sukses:
              Navigator.pop(context, true); // close detail
              _fetchFirst();                 // refresh list
            },
          ),
        ),
      );
    } catch (err) {
      Navigator.pop(context); // tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')),
      );
    }
  }

}
