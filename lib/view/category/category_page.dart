import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodel/category_viewmodel.dart';
import '../category/create_category_page.dart'; // kalau beda path, sesuaikan

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _search = TextEditingController();
  final _fmtDate = DateFormat('MMM d, yyyy'); // Aug 12, 2025

  final _vm = CategoryViewmodel();

  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _all = [];
  final List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ===== Fetch list =====
  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _all.clear();
      _filtered.clear();
    });

    try {
      final resp = await _vm.getCategory(); // atau getCategory(search: _search.text) kalau server support
      if ((resp.code ?? 500) >= 300) throw resp.message ?? 'Failed';

      // Robust parsing: {data:{items:[...]}} atau {items:[...]} atau langsung list
      final root = resp.data;
      final map = (root is Map && root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'] as Map)
          : (root is Map<String, dynamic> ? root : <String, dynamic>{});
      final rawList = (map['items'] as List?) ?? (root is List ? root : const []);

      int asInt(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
      DateTime asDt(v) => v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());
      String asStr(v) => (v ?? '').toString();

      final parsed = rawList.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'id': asInt(m['id']),
          'name': asStr(m['name']),
          'desc': asStr(m['description']),
          'products': asInt(m['products_count'] ?? m['products']?.length),
          'created': asDt(m['created_at']),
        };
      }).toList();

      setState(() {
        _all.addAll(parsed);
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
    final q = _search.text.trim().toLowerCase();
    final res = _all.where((e) {
      final n = (e['name'] as String).toLowerCase();
      final d = (e['desc'] as String).toLowerCase();
      return q.isEmpty ? true : (n.contains(q) || d.contains(q));
    }).toList();

    _filtered
      ..clear()
      ..addAll(res);
    setState(() {});
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
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
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }

  // ===== Detail popup (bottom sheet) =====
  Future<void> _showDetail(dynamic id) async {
    // loader kecil sementara fetch detail
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await _vm.categoryDetail(id: id);
      Navigator.pop(context); // tutup loader
      if ((resp.code ?? 500) >= 300) throw resp.message ?? 'Failed';

      final root = resp.data;
      final m = (root is Map && root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'] as Map)
          : Map<String, dynamic>.from((root as Map?) ?? const {});
      String s(v) => (v ?? '').toString();
      int i(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
      DateTime dt(v) => v is DateTime ? v : (DateTime.tryParse('${v ?? ''}') ?? DateTime.now());

      final name = s(m['name']);
      final desc = s(m['description']);
      final created = dt(m['created_at']);
      final products = (m['products'] as List? ?? const []).cast<Map>();

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${i(m['products_count'])} products',
                        style:
                        const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc.isEmpty ? 'No description' : desc,
                  style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      _fmtDate.format(created),
                      style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Products',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                if (products.isEmpty)
                  const Text('No products', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600))
                else
                  ...products.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  'Stock: ${p['stock_quantity'] ?? 0} • Min: ${p['min_stock_level'] ?? 0}',
                                  style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context); // tutup loader jika masih terbuka
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load detail failed: $e')));
    }
  }

  // ===== Delete =====
  Future<void> _delete(dynamic id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Category "$name" will be deleted permanently.'),
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
    if (ok != true) return;

    try {
      final resp = await _vm.deleteCategoryById(id: id);
      if ((resp.code ?? 500) >= 300) throw resp.message ?? 'Delete failed';
      // hapus dari list lokal
      _all.removeWhere((e) => e['id'] == id);
      _applyFilter();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Category deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // ===== Build =====
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
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCategoryPage()),
                );
                if (created == true) _fetch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
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
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage product categories',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // Search (filter lokal)
              TextField(
                controller: _search,
                decoration: _dec('Search categories...'),
                onChanged: (_) => _applyFilter(),
                onSubmitted: (_) => _applyFilter(),
              ),
              const SizedBox(height: 16),

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
                    child: Text('No categories',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Column(
                  children: _filtered.map((e) {
                    return LayoutBuilder(builder: (context, c) {
                      final tight = c.maxWidth < 340;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: const Color(0xFFF0F2F5)),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e['desc'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF2FF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          "${e['products']} products",
                                          style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.event, size: 16, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            _fmtDate.format(e['created']),
                                            style: const TextStyle(
                                              color: Color(0xFF334155),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // right actions
                            if (tight)
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'View') {
                                    await _showDetail(e['id']);
                                  } else if (v == 'Edit') {
                                    // TODO: navigate ke edit page kalau ada
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('TODO: Edit category')),
                                    );
                                  } else if (v == 'Delete') {
                                    await _delete(e['id'], e['name']);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'View', child: Text('View')),
                                  PopupMenuItem(value: 'Edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'Delete', child: Text('Delete')),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  IconButton(
                                    tooltip: 'View',
                                    onPressed: () => _showDetail(e['id']),
                                    icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF475569)),
                                  ),
                                  // --- versi ikon (bukan tight)
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () async {
                                      final updated = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => CreateCategoryPage(id: e['id'])),
                                      );
                                      if (updated == true) _fetch(); // refresh list
                                    },
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569)),
                                  ),

// --- versi popup (tight)
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'View') {
                                        await _showDetail(e['id']);
                                      } else if (v == 'Edit') {
                                        final updated = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(builder: (_) => CreateCategoryPage(id: e['id'])),
                                        );
                                        if (updated == true) _fetch();
                                      } else if (v == 'Delete') {
                                        await _delete(e['id'], e['name']);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'View', child: Text('View')),
                                      PopupMenuItem(value: 'Edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'Delete', child: Text('Delete')),
                                    ],
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => _delete(e['id'], e['name']),
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    });
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
