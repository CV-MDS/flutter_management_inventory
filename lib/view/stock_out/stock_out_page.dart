import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockOutPage extends StatefulWidget {
  const StockOutPage({super.key});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  // --- State/filter ---
  final _search = TextEditingController();
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  DateTime? _dateFrom, _dateTo;

  // Dummy data
  final List<Map<String, dynamic>> _all = [
    {
      'ref': 'SO-20250813-002',
      'date': DateTime(2025, 8, 13),
      'items': 1,
      'by': 'Staff Satu',
    },
    {
      'ref': 'SO-20250813-001',
      'date': DateTime(2025, 8, 13),
      'items': 1,
      'by': 'Staff Satu',
    },
  ];
  final List<Map<String, dynamic>> _filtered = [];

  final _fmtUi = DateFormat('MMM d, yyyy');
  final _fmtPick = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  @override
  void dispose() {
    _search.dispose();
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      if (from) {
        _dateFrom = DateTime(picked.year, picked.month, picked.day);
        _dateFromCtrl.text = _fmtPick.format(_dateFrom!);
      } else {
        _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _dateToCtrl.text = _fmtPick.format(_dateTo!);
      }
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    final from = _dateFrom;
    final to = _dateTo;

    final res = _all.where((e) {
      final ref = (e['ref'] as String).toLowerCase();
      final by = (e['by'] as String).toLowerCase();
      final dt = (e['date'] as DateTime);

      final matchQ = q.isEmpty ? true : (ref.contains(q) || by.contains(q));
      final afterFrom = from == null ? true : !dt.isBefore(from);
      final beforeTo = to == null ? true : !dt.isAfter(to);

      return matchQ && afterFrom && beforeTo;
    }).toList();

    setState(() {
      _filtered
        ..clear()
        ..addAll(res);
    });
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New Stock Out tapped')),
                );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    final mid = c.maxWidth >= 420;

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
                                  onSubmitted: (_) => _applyFilter(),
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
                                  decoration: _dec('dd/mm/yyyy',
                                      suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
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
                                  decoration: _dec('dd/mm/yyyy',
                                      suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
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
                              onPressed: _applyFilter,
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
                            onSubmitted: (_) => _applyFilter(),
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
                                      decoration: _dec('dd/mm/yyyy',
                                          suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
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
                                      decoration: _dec('dd/mm/yyyy',
                                          suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
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
                                  onPressed: _applyFilter,
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

                    // Kompak (hp kecil)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _search,
                          decoration: _dec('Reference number...', prefix: const Icon(Icons.search)),
                          onSubmitted: (_) => _applyFilter(),
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
                            onPressed: _applyFilter,
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
                  children: _filtered.map((e) {
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
                                Text(e['ref'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A))),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(_fmtUi.format(e['date']),
                                        style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${e['items']} items',
                                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    ),
                                    Text('By ${e['by']}',
                                        style: const TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('View ${e['ref']}')),
                                  );
                                },
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
