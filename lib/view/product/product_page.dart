import 'package:flutter/material.dart';

import '../../color.dart';
import '../../model/product.dart';
import '../../widget/category_dropdown.dart';
import '../../widget/label_white.dart';
import '../../widget/product_card.dart';
import '../../widget/search_field.dart';
import '../../widget/sidebar_drawer.dart';
import '../activity_history/activity_history_page.dart';
import '../home/home_page.dart';
import '../user_management/user_management_page.dart';
import '../profile/profile_page.dart'; // kalau perlu
import '../../viewmodel/product_viewmodel.dart';
import '../../config/model/resp.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // ===== Drawer =====
  int _selectedDrawer = 4;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ===== UI State =====
  final _search = TextEditingController();
  String _selectedCategory = 'All Category';
  bool _lowStockOnly = false;

  // ===== Data State =====
  final _vm = ProductViewmodel();
  final _scroll = ScrollController();

  bool _initialLoading = true;     // loader tengah saat pertama kali load
  bool _loadingMore = false;       // loader kecil saat ambil halaman berikutnya
  bool _refreshing = false;

  int _page = 1;
  int _lastPage = 1;

  final List<Product> _all = [];       // semua hasil fetch (dari server)
  final List<Product> _filtered = [];  // hasil setelah filter lokal

  // derive kategori dari data
  List<String> get _categories {
    final s = <String>{'All Category'};
    for (final p in _all) {
      final name = p.category?.name?.trim();
      if (name != null && name.isNotEmpty) s.add(name);
    }
    return s.toList();
  }

  // ===== Lifecycle =====
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
    super.dispose();
  }

  // ===== Fetching =====
  Future<void> _fetchFirst() async {
    setState(() {
      _initialLoading = true;
      _page = 1;
      _lastPage = 1;
      _all.clear();
      _filtered.clear();
    });

    await _fetch(page: 1, reset: true, serverSearch: _search.text.trim());

    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    await _fetch(page: _page + 1, reset: false, serverSearch: _search.text.trim());
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _fetchFirst();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetch({
    required int page,
    required bool reset,
    String? serverSearch,
  }) async {
    try {
      final Resp resp = await _vm.getProducts(
        page: page,
        perPage: 10,
        search: (serverSearch ?? '').isEmpty ? null : serverSearch,
      );

      if (resp.code == 200) {
        final map = (resp.data as Map?) ?? const {};
        final items = (map['items'] as List? ?? const [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = (map['pagination'] as Map?) ?? const {};
        final current = int.tryParse('${pagination['current_page'] ?? 1}') ?? 1;
        final last = int.tryParse('${pagination['last_page'] ?? 1}') ?? 1;

        setState(() {
          _page = current;
          _lastPage = last;
          if (reset) {
            _all
              ..clear()
              ..addAll(items);
          } else {
            _all.addAll(items);
          }
          _applyFilterLocal(); // terapkan filter kategori & low stock
        });
      } else if (resp.code == 401) {
        // TODO: arahkan ke login kalau perlu
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message ?? 'Unauthorized')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message ?? 'Fetch products failed')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 120) {
      _fetchMore();
    }
  }

  // ===== Filter Lokal =====
  void _applyFilterLocal() {
    final cat = _selectedCategory;
    final onlyLow = _lowStockOnly;

    final result = _all.where((p) {
      final matchCat = (cat == 'All Category')
          ? true
          : (p.category?.name == cat);
      final matchLow = onlyLow ? p.isLowStock : true;
      return matchCat && matchLow;
    }).toList();

    _filtered
      ..clear()
      ..addAll(result);
  }

  void _onPressFilter() async {
    // Search dikirim ke server, kategori & low stock di client
    await _fetchFirst();
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: C.bg,
      drawer: SidebarDrawer(
        selectedIndex: _selectedDrawer,
        onTap: (i) {
          setState(() => _selectedDrawer = i);
          Navigator.pop(context);

          switch (i) {
            case 0:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomePage()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProductPage()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserManagementPage()));
              break;
            case 4:
            // already in Product Page
              break;
          }
        },
      ),
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 12),

              // ===== Header =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: C.dark,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.07),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Products',
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: C.textDark,
                                )),
                            SizedBox(height: 4),
                            Text('Manage your product inventory',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9AA1B2),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.open_in_new_rounded, color: C.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ===== Filter Panel =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  decoration: BoxDecoration(
                    color: C.dark,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabelWhite('Search'),
                      const SizedBox(height: 8),
                      SearchField(
                        controller: _search,
                        hint: 'Searching',
                        onSubmitted: (_) => _onPressFilter(),
                        onChanged: (_) => setState(() {}), // biar UX responsif
                      ),
                      const SizedBox(height: 14),
                      const LabelWhite('Category'),
                      const SizedBox(height: 8),
                      CategoryDropdown(
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (v) {
                          setState(() {
                            _selectedCategory = v ?? 'All Category';
                            _applyFilterLocal();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Checkbox Field',
                        style: TextStyle(
                          color: Color(0x66FFFFFF),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: _lowStockOnly,
                              onChanged: (v) {
                                setState(() {
                                  _lowStockOnly = v ?? false;
                                  _applyFilterLocal();
                                });
                              },
                              activeColor: const Color(0xFF4CD964),
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Low Stock Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _onPressFilter,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: C.textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Filter',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== List Produk =====
              if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(
                          color: C.hint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._filtered.map((p) {
                  final catName = p.category?.name ?? '-';
                  // ── Gunakan ProductCard versi named parameters ──
                  return ProductCard(
                    name: p.name,
                    category: catName,
                    stock: p.stockQuantity,
                    imageUrl: p.image, // tampilkan kalau widget mendukung
                    lowStock: p.isLowStock,
                    onView: () {
                      // TODO: navigasi ke detail
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View: ${p.name}')),
                      );
                    },
                  );

                  // Jika ProductCard kamu masih pakai `data:` dengan class sederhana,
                  // kamu bisa bikin adapter kecil seperti ini:
                  // final ui = _UiProduct(p.name, catName, p.stockQuantity);
                  // return ProductCard(data: ui, onView: () { ... });
                }),

              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// OPTIONAL: adapter jika ProductCard kamu masih butuh `data:`
// (hapus jika tidak diperlukan)
// ───────────────────────────────────────────────────────────────
class _UiProduct {
  final String name;
  final String category;
  final int stock;
  _UiProduct(this.name, this.category, this.stock);
}
