import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // --- State & Controllers ---
  final _search = TextEditingController();

  final List<Map<String, dynamic>> _all = [
    {
      'name': 'accessories',
      'desc': 'Accessories, gelang, kalung, anting dll',
      'products': 1,
      'created': DateTime(2025, 8, 12),
    },
    {
      'name': 'Tshirt',
      'desc': 'Macam Macam baju',
      'products': 4,
      'created': DateTime(2025, 8, 12),
    },
    {
      'name': 'Celana',
      'desc': 'Celana cargo, dll',
      'products': 0,
      'created': DateTime(2025, 8, 12),
    },
    {
      'name': 'Shoes',
      'desc': 'Macam Macam sepatu',
      'products': 0,
      'created': DateTime(2025, 8, 12),
    },
  ];
  final List<Map<String, dynamic>> _filtered = [];

  final _fmtDate = DateFormat('MMM d, yyyy'); // Aug 12, 2025

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    final res = _all.where((e) {
      final n = (e['name'] as String).toLowerCase();
      final d = (e['desc'] as String).toLowerCase();
      return q.isEmpty ? true : (n.contains(q) || d.contains(q));
    }).toList();
    setState(() {
      _filtered
        ..clear()
        ..addAll(res);
    });
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Category tapped')),
                );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage product categories',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // Search
              TextField(
                controller: _search,
                decoration: _dec('Search categories...'),
                onChanged: (_) => _applyFilter(),
                onSubmitted: (_) => _applyFilter(),
              ),

              const SizedBox(height: 16),

              // List
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
                    child: Text('No categories', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Column(
                  children: _filtered.map((e) {
                    return LayoutBuilder(builder: (context, c) {
                      final tight = c.maxWidth < 340; // mode super compact
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
                            // left: name + desc + chips
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
                                      // products badge
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
                                      // created
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

                            // right: actions (ikon / popup saat sempit)
                            tight
                                ? PopupMenuButton<String>(
                              onSelected: (v) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$v ${e['name']}')),
                                );
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'View', child: Text('View')),
                                PopupMenuItem(value: 'Edit', child: Text('Edit')),
                                PopupMenuItem(value: 'Delete', child: Text('Delete')),
                              ],
                            )
                                : Column(
                              children: [
                                IconButton(
                                  tooltip: 'View',
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('View ${e['name']}')),
                                  ),
                                  icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF475569)),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Edit ${e['name']}')),
                                  ),
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569)),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete ${e['name']}')),
                                  ),
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
