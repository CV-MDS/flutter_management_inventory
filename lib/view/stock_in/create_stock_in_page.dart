import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../viewmodel/stockin_viewmodel.dart';

class CreateStockInPage extends StatefulWidget {
  const CreateStockInPage({super.key});

  @override
  State<CreateStockInPage> createState() => _CreateStockInPageState();
}

class _CreateStockInPageState extends State<CreateStockInPage> {
  final _form = GlobalKey<FormState>();

  // --- Controllers / state ---
  final _refCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _date;

  // Dummy products (ganti dengan fetch API jika diperlukan)
  final List<Map<String, dynamic>> _products = const [
    {'id': 1, 'name': 'Product A'},
    {'id': 2, 'name': 'Product B'},
    {'id': 3, 'name': 'Product C'},
  ];

  // Items = list of {product_id, quantity}
  final List<Map<String, dynamic>> _items = [
    {'product_id': null, 'quantity': 1},
  ];

  final _fmtUi = DateFormat('dd/MM/yyyy');
  final _fmtApi = DateFormat('yyyy-MM-dd');

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // generate ref number sederhana: SI-yyyymmdd-001
    final now = DateTime.now();
    _refCtrl.text =
    'SI-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001';
    _date = now;
    _dateCtrl.text = _fmtUi.format(now);
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
        _dateCtrl.text = _fmtUi.format(_date!);
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({'product_id': null, 'quantity': 1});
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _items.add({'product_id': null, 'quantity': 1});
      }
    });
  }

  InputDecoration _dec(String hint, {Widget? suffix, EdgeInsets? pad}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: pad ??
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
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
        borderSide: const BorderSide(color: Color(0xFF22C55E)),
      ),
    );
  }

  Future<void> _submit() async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal belum dipilih')),
      );
      return;
    }

    if (!_form.currentState!.validate()) return;

    // Validasi item
    for (final it in _items) {
      final pid = it['product_id'];
      final qty = it['quantity'];
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih produk untuk semua baris item')),
        );
        return;
      }
      if (qty is! int || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity harus > 0')),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final res = await StockInViewmodel().createStockIn(
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

      if ((res.code ?? 500) >= 300) {
        throw res.message ?? 'Create Stock In gagal';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create Stock In berhasil')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);
    final w = MediaQuery.of(context).size.width;
    final wide = w >= 380; // ambang sederhana agar responsif

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF111827),
        titleSpacing: 0,
        title: const Text(
          'Create Stock In',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
                  'Add new incoming stock transaction',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                // Card konten
                Container(
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
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Baris Ref & Tanggal (responsif: row/column) ---
                      LayoutBuilder(
                        builder: (_, c) {
                          final isRow = c.maxWidth > 360;

                          final refField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reference Number *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _refCtrl,
                                decoration: _dec('e.g. SI-20250826-001'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          );

                          final dateField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock In Date *',
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

                          if (isRow) {
                            return Row(
                              children: [
                                Expanded(child: refField),
                                const SizedBox(width: 10),
                                Expanded(child: dateField),
                              ],
                            );
                          }
                          // stacked: no Expanded
                          return Column(
                            children: [
                              refField,
                              const SizedBox(height: 12),
                              dateField,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // --- Notes ---
                      const Text(
                        'Notes',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _dec('Enter any additional notes'),
                      ),

                      const SizedBox(height: 18),

                      // --- Items header + add btn ---
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Items',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827)),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle:
                                const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // --- Item rows (responsif) ---
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
                          child: LayoutBuilder(builder: (_, c) {
                            final isRow = c.maxWidth > 360; // cukup lebar? sejajarkan

                            Widget productField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: it['product_id'] as int?,
                                  items: _products
                                      .map((p) => DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['name'] as String)))
                                      .toList(),
                                  onChanged: (v) => setState(() => it['product_id'] = v),
                                  decoration: _dec('Select Product', pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  validator: (v) => v == null ? 'Pilih produk' : null,
                                ),
                              ],
                            );

                            Widget qtyField = SizedBox(
                              width: isRow ? 120 : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    initialValue: '${it['quantity']}',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (v) => it['quantity'] = int.tryParse(v) ?? 0,
                                    decoration: _dec('1', pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n <= 0) return '>= 1';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            );

                            final deleteBtn = IconButton(
                              onPressed: () => _removeItem(i),
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                            );

                            if (isRow) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: productField),
                                  const SizedBox(width: 10),
                                  qtyField,
                                  const SizedBox(width: 6),
                                  deleteBtn,
                                ],
                              );
                            }
                            // stacked: no Expanded
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                productField,
                                const SizedBox(height: 10),
                                qtyField,
                                Align(alignment: Alignment.centerRight, child: deleteBtn),
                              ],
                            );
                          }),
                        );
                      }),

                      const SizedBox(height: 6),

                      // --- Action buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                side:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                foregroundColor: const Color(0xFF111827),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800),
                                elevation: 0,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text('Create Stock In'),
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
