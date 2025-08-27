import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/category.dart';
import '../../viewmodel/category_viewmodel.dart';
import '../../viewmodel/product_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _form = GlobalKey<FormState>();

  // controllers
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _size = TextEditingController();
  final _color = TextEditingController();
  final _desc = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _minStock = TextEditingController(text: '5');

  // dropdown
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCats = true;
  String? _loadCatsError;

  // submit state
  bool _submitting = false;

  // image (opsional, biarkan null jika belum implement pick)
  File? _imageFile;

  Future<void> getCategory() async {
    final result = await CategoryViewmodel().getCategory();
    if (!mounted) return;

    if (result.code == 200) {
      // asumsikan shape: { items: [...] }
      final listRaw = (result.data is Map && result.data['items'] is List)
          ? result.data['items'] as List
          : const [];
      final listData = UnmodifiableListView(listRaw);

      setState(() {
        _categories = listData.map((e) => Category.fromJson(e)).toList();
        _loadingCats = false;
      });
    } else {
      setState(() {
        _loadingCats = false;
        _loadCatsError = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori: ${result.message}')),
      );
    }
  }

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600, // sedikit kompres via resize
        maxHeight: 1600,
        imageQuality: 85, // 0-100 (jpeg)
      );
      if (picked == null) return;

      final file = File(picked.path);
      final err = await _validateImage(file);
      if (err != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      if (!mounted) return;
      setState(() => _imageFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<String?> _validateImage(File file) async {
    // ukuran < 2MB
    final bytes = await file.length();
    const max = 2 * 1024 * 1024;
    if (bytes > max) {
      return 'Ukuran gambar maksimal 2MB. File sekarang ${(bytes/1024/1024).toStringAsFixed(2)}MB';
    }

    // mime check
    final mime = lookupMimeType(file.path) ?? '';
    const allowed = ['image/png','image/jpg','image/jpeg','image/gif'];
    if (!allowed.contains(mime)) {
      return 'Format tidak didukung. Gunakan PNG/JPG/JPEG/GIF';
    }
    return null;
  }


  @override
  void initState() {
    getCategory();
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _size.dispose();
    _color.dispose();
    _desc.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  TextStyle get _h1 => const TextStyle(
      fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF111827));
  TextStyle get _subtitle => const TextStyle(
      fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w600);
  TextStyle get _section => const TextStyle(
      fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827));
  TextStyle get _label => const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280));

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori')),
      );
      return;
    }

    final stockQty = int.tryParse(_stock.text) ?? 0;
    final minStock = int.tryParse(_minStock.text) ?? 0;

    setState(() => _submitting = true);
    try {
      final vm = ProductViewmodel();
      final resp = await vm.createProduct(
        name: _name.text.trim(),
        categoryId: _selectedCategoryId!,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        size: _size.text.trim().isEmpty ? null : _size.text.trim(),
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        stockQuantity: stockQty,
        minStockLevel: minStock,
        imageFile: _imageFile, // opsional
      );

      if (!mounted) return;

      if (resp.code == 200 || resp.code == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Product created')),
        );
        // Kembali ke halaman sebelumnya sambil kirim flag sukses
        Navigator.pop(context, true);
      } else if (resp.code == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Unauthorized')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(resp.message ?? 'Gagal membuat product'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        title: const Text('Create Product',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Create Product', style: _h1),
              const SizedBox(height: 4),
              Text('Add a new product to your inventory', style: _subtitle),
              const SizedBox(height: 14),

              // Card container
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
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Information', style: _section),
                      const SizedBox(height: 12),

                      // Product Name
                      Text('Product Name *', style: _label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Enter product name'),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Category
                      Text('Category *', style: _label),
                      const SizedBox(height: 6),
                      if (_loadingCats) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        const SizedBox(height: 10),
                      ] else if (_loadCatsError != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Gagal memuat kategori: $_loadCatsError',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _loadingCats = true;
                                  _loadCatsError = null;
                                });
                                getCategory();
                              },
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: _dec('Pilih kategori'),
                          items: const [],
                          onChanged: null,
                          validator: (_) => 'Kategori belum tersedia',
                        ),
                      ] else ...[
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: _dec('Select Category'),
                          items: _categories
                              .map((c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                          validator: (v) =>
                          (v == null) ? 'Please select category' : null,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Description
                      Text('Description', style: _label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _desc,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: _dec('Enter product description'),
                      ),

                      const SizedBox(height: 18),
                      Text('Product Details', style: _section),
                      const SizedBox(height: 12),

                      // Brand
                      Text('Brand', style: _label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _brand,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Enter brand'),
                      ),
                      const SizedBox(height: 12),

                      // Size
                      Text('Size', style: _label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _size,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Enter size'),
                      ),
                      const SizedBox(height: 12),

                      // Color
                      Text('Color', style: _label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _color,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Enter color'),
                      ),
                      const SizedBox(height: 12),

                      // Stock & Min Stock
                      LayoutBuilder(
                        builder: (context, c) {
                          final left = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock Quantity *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _stock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: _dec('0'),
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ],
                          );

                          final right = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Min Stock Level *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280))),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _minStock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textInputAction: TextInputAction.done,
                                decoration: _dec('5'),
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ],
                          );

                          final isWide = c.maxWidth > 360;

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 12),
                                Expanded(child: right),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 12),
                              right,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 18),
                      Text('Product Image', style: _section),
                      const SizedBox(height: 8),

                      if (_imageFile == null)
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.image_outlined, size: 36, color: Color(0xFF9CA3AF)),
                                SizedBox(height: 8),
                                Text.rich(TextSpan(children: [
                                  TextSpan(text: 'Upload a file ', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800)),
                                  TextSpan(text: 'or tap to browse', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                                ])),
                                SizedBox(height: 4),
                                Text('PNG, JPG, GIF up to 2MB', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      else
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.swap_horiz, size: 18),
                                    label: const Text('Ganti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: () => setState(() => _imageFile = null),
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(.5),
                                      foregroundColor: Colors.white,
                                    ),
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 18),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                side:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
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
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
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
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              )
                                  : const Text('Create Product'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
