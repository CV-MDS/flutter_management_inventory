import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_management_inventory/view/product/create_product_page.dart';
import 'package:flutter_management_inventory/view/product/product_detail_page.dart';
import 'package:flutter_management_inventory/view/stock_out_report/stock_out_report_page.dart';

import '../../color.dart';
import '../../model/product.dart';
import '../../widget/category_dropdown.dart';
import '../../widget/label_white.dart';
import '../../widget/product_card.dart';
import '../../widget/search_field.dart';
import '../../widget/sidebar_drawer.dart';
import '../activity_history/activity_history_page.dart';
import '../category/category_page.dart';
import '../home/home_page.dart';
import '../stock_in/stock_in_page.dart';
import '../stock_in_report/stock_in_report_page.dart';
import '../stock_out/stock_out_page.dart';
import '../user_management/user_management_page.dart';
import '../profile/profile_page.dart';
import '../../viewmodel/product_viewmodel.dart';
import '../../config/model/resp.dart';
import '../../config/pref.dart'; // NEW: untuk Session().getUserType()

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late int _selectedDrawer = 3;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _search = TextEditingController();
  String _selectedCategory = 'All Category';
  bool _lowStockOnly = false;

  final _vm = ProductViewmodel();
  final _scroll = ScrollController();

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _refreshing = false;

  int _page = 1;
  int _lastPage = 1;

  final List<Product> _all = [];
  final List<Product> _filtered = [];

  String? _userType; // NEW

  bool get _canAdd => (_userType?.toLowerCase() ?? '') != 'admin'; // NEW

  List<String> get _categories {
    final s = <String>{'All Category'};
    for (final p in _all) {
      final name = p.category?.name?.trim();
      if (name != null && name.isNotEmpty) s.add(name);
    }
    return s.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserType(); // NEW
    _fetchFirst();
    _scroll.addListener(_onScroll);
  }

  // NEW: muat userType dari session
  Future<void> _loadUserType() async {
    final t = await Session().getUserType();

    if (!mounted) return;
    setState(() {
      _userType = t;
      _selectedDrawer = t == "owner" ? 2 : t == "admin" ? 1 : 3;
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

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
          _applyFilterLocal();
        });
      } else if (resp.code == 401) {
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
      _fetchMore();
    }
  }

  void _applyFilterLocal() {
    final cat = _selectedCategory;
    final onlyLow = _lowStockOnly;

    final result = _all.where((p) {
      final matchCat = (cat == 'All Category') ? true : (p.category?.name == cat);
      final matchLow = onlyLow ? p.isLowStock : true;
      return matchCat && matchLow;
    }).toList();

    _filtered
      ..clear()
      ..addAll(result);
  }

  void _onPressFilter() async {
    await _fetchFirst();
  }

  // NEW: handler untuk tombol Add Product
  void _onAddProduct() {
    // TODO: ganti ke halaman AddProduct saat sudah ada
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProductPage(),),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: C.bg,
      drawer: SidebarDrawer(
        selectedIndex: _selectedDrawer,
        onTap: (i) => _handleDrawerTap(i),
      ),
      floatingActionButton: _canAdd
          ? FloatingActionButton.extended(
        onPressed: _onAddProduct,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: C.dark,
        foregroundColor: Colors.white,
      ) : null,
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
                        onChanged: (_) => setState(() {}),
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
                  return ProductCard(
                    name: p.name,
                    category: catName,
                    stock: p.stockQuantity,
                    imageUrl: "${dotenv.env['IMAGE_BASE_URL']!}${p.image}",
                    lowStock: p.isLowStock,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            product: p,
                            imageUrl: "${dotenv.env['IMAGE_BASE_URL']!}${p.image}",
                            onEdit: () {
                              // TODO: arahkan ke halaman edit product
                              // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(product: p)));
                            },
                          ),
                        ),
                      );
                    },
                  );
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

  void _handleDrawerTap(int i) {
    setState(() => _selectedDrawer = i);
    Navigator.pop(context);

    final type = _userType ?? 'admin';

    if (type == 'admin') {
      switch (i) {
        case 0: Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));  break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage())); break;
        case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage())); break;
        case 4: break;
        default: break;
      }
      return;
    }

    if (type == 'staff') {
      switch (i) {
        case 0: Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())); break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPage()));
          break;
        case 3: break;
        case 4: Navigator.push(context, MaterialPageRoute(builder: (_) => const StockInPage()));
        break;
        case 5:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutPage()));
          break;
        default: break;
      }
      return;
    }

    if (type == 'owner') {
      switch (i) {
        case 0: Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())); break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2: break;
        case 3:Navigator.push(context, MaterialPageRoute(builder: (_) => const StockInReportPage())); break;
        case 4:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutReportPage())); break;
        default: break;
      }
      return;
    }
  }
}
