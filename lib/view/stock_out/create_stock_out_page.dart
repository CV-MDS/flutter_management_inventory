import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_management_inventory/viewmodel/product_viewmodel.dart';
import 'package:flutter_management_inventory/viewmodel/stockin_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../config/model/resp.dart';            // opsional kalau mau cek resp.code

class CreateStockOutPage extends StatefulWidget {
  const CreateStockOutPage({super.key});

  @override
  State<CreateStockOutPage> createState() => _CreateStockOutPageState();
}

class _CreateStockOutPageState extends State<CreateStockOutPage> {
  final _form = GlobalKey<FormState>();

  // Controllers
  final _refCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _date;

  // Produk dari API -> [{'id':int,'name':String,'available':int}]
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = true;

  // Baris items
  final List<Map<String, dynamic>> _items = [
    {'product_id': null, 'available': null, 'quantity': 1},
  ];

  // Formatter
  final _fmtUi = DateFormat('dd/MM/yyyy');
  final _fmtRef = DateFormat('yyyyMMdd');

  bool _submitting = false;

  // ---------- Helpers ----------
  InputDecoration _dec(String hint, {Widget? suffix, EdgeInsets? pad}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: pad ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFFEF4444)), // merah: stock-out
      ),
    );
  }

  String _makeRef(DateTime d) => 'SO-${_fmtRef.format(d)}-001';

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _dateCtrl.text = _fmtUi.format(_date!);
    _refCtrl.text = _makeRef(_date!);

    _loadProducts();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------- Fetching ----------
  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final resp = await ProductViewmodel().getProducts(perPage: 200);
      // Response umum: { data:{ items:[...] } } atau { items:[...] }
      final root = resp.data;
      List list =
      (root is Map && root['data'] is Map && root['data']['items'] is List)
          ? root['data']['items']
          : (root is Map && root['items'] is List)
          ? root['items']
          : (root is List ? root : const []);

      final parsed = list.map<Map<String, dynamic>>((raw) {
        final m = raw as Map;
        int toInt(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
        return {
          'id': m['id'],
          'name': (m['name'] ?? '').toString(),
          // field stok umumnya 'stock_quantity' / 'stock' / 'available'
          'available': toInt(m['stock_quantity'] ?? m['stock'] ?? m['available']),
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _products = parsed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat produk: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  // ---------- Actions ----------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _dateCtrl.text = _fmtUi.format(_date!);
      _refCtrl.text = _makeRef(_date!); // update ref saat tanggal berubah
    });
  }

  void _addItem() {
    setState(() {
      _items.add({'product_id': null, 'available': null, 'quantity': 1});
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _items.add({'product_id': null, 'available': null, 'quantity': 1});
      }
    });
  }

  Future<void> _submit() async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal belum dipilih')));
      return;
    }
    if (!_form.currentState!.validate()) return;

    // Validasi baris items
    for (final it in _items) {
      final pid = it['product_id'];
      final qty = it['quantity'];
      final avail = it['available'];
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk pada semua baris')));
        return;
      }
      if (qty is! int || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity harus ≥ 1')));
        return;
      }
      if (avail is int && qty > avail) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Qty melebihi stok tersedia')));
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final resp = await StockInViewmodel().createStockOut(
        referenceNumber: _refCtrl.text.trim(),
        date: _date!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: _items
            .map((e) => {
          'product_id': e['product_id'],
          'quantity': e['quantity'],
        })
            .toList(),
      );

      if ((resp.code ?? 500) >= 300) {
        throw resp.message ?? 'Create Stock Out gagal';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create Stock Out berhasil')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------- UI ----------
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
        title: const Text('Create Stock Out', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add new outgoing stock transaction',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ref + Date
                      LayoutBuilder(
                        builder: (_, c) {
                          final isRow = c.maxWidth > 360;

                          // TANPA Expanded
                          final refField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reference Number *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _refCtrl,
                                decoration: _dec('e.g. SO-20250827-001'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          );

                          final dateField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock Out Date *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _dateCtrl,
                                readOnly: true,
                                onTap: _pickDate,
                                decoration: _dec('dd/MM/yyyy', suffix: const Icon(Icons.calendar_today_rounded, size: 18)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          );

                          return isRow
                              ? Row(children: [
                            Expanded(child: refField),
                            const SizedBox(width: 10),
                            Expanded(child: dateField),
                          ])
                              : Column(children: [
                            refField,
                            const SizedBox(height: 12),
                            dateField,
                          ]);
                        },
                      ),

                      const SizedBox(height: 14),

                      const Text('Notes',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _dec('Enter any additional notes (purpose: sale, damaged, expired, etc.)'),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Expanded(
                            child: Text('Items',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                          ),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Item rows
                      ...List.generate(_items.length, (i) {
                        final it = _items[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: LayoutBuilder(
                            builder: (_, c) {
                              final isRow = c.maxWidth > 360;

                              final productFieldCore = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Product',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 6),

                                  // Lihat catatan #3 di bawah untuk tipe generic dropdown
                                  DropdownButtonFormField<int?>(
                                    value: it['product_id'] as int?,
                                    items: _loadingProducts
                                        ? const [
                                      DropdownMenuItem<int?>(value: null, enabled: false, child: Text('Loading...')),
                                    ]
                                        : _products
                                        .map((p) => DropdownMenuItem<int?>(
                                      value: p['id'] as int,
                                      child: Text(p['name'] as String),
                                    ))
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        it['product_id'] = v;
                                        final found = _products.firstWhere((e) => e['id'] == v, orElse: () => {'available': 0});
                                        it['available'] = found['available'] ?? 0;
                                        if ((it['quantity'] as int? ?? 0) <= 0) it['quantity'] = 1;
                                      });
                                    },
                                    validator: (v) => v == null ? 'Pilih produk' : null,
                                    decoration: _dec('Select Product', pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Available Stock',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFFEFEE), borderRadius: BorderRadius.circular(999)),
                                        child: Text(
                                          it['available'] == null ? '-' : '${it['available']}',
                                          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );

                              final qtyField = SizedBox(
                                width: isRow ? 120 : double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quantity',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      initialValue: '${it['quantity']}',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (v) => it['quantity'] = int.tryParse(v) ?? 0,
                                      decoration: _dec('1',
                                          pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                      validator: (v) {
                                        final n = int.tryParse(v ?? '');
                                        if (n == null || n <= 0) return '≥ 1';
                                        final avail = it['available'] as int? ?? 0;
                                        if (avail > 0 && n > avail) return 'Max $avail';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              );

                              final delBtn = IconButton(
                                onPressed: () => _removeItem(i),
                                tooltip: 'Remove',
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              );

                              return isRow
                                  ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: productFieldCore),   // Expanded hanya saat Row
                                  const SizedBox(width: 10),
                                  qtyField,
                                  const SizedBox(width: 6),
                                  delBtn,
                                ],
                              )
                                  : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  productFieldCore,                    // TANPA Expanded saat Column
                                  const SizedBox(height: 10),
                                  qtyField,
                                  Align(alignment: Alignment.centerRight, child: delBtn),
                                ],
                              );
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 6),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                foregroundColor: const Color(0xFF111827),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                                elevation: 0,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text('Create Stock Out'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
