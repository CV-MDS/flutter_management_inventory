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
import '../profile/profile_page.dart';
import '../user_management/user_management_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {

  final _search = TextEditingController();
  String Category = 'All Category';
  bool _lowStockOnly = false;

  final _all = <Product>[
    const Product(name: 'Baldwin Boxy Fit', category: 'T-Shirts', stock: 13),
    const Product(name: 'Classic Crewneck', category: 'T-Shirts', stock: 3),
    const Product(name: 'Everyday Hoodie', category: 'Outer', stock: 7),
    const Product(name: 'Denim Jacket', category: 'Outer', stock: 1),
  ];

  final _items = <Product>[];

  final int _lowStockAt = 5;

  List<String> get Categories {
    final set = <String>{'All Category'};
    for (final p in _all) {
      set.add(p.category);
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    final cat = Category;

    final filtered = _all.where((p) {
      final matchSearch =
          p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
      final matchCat = (cat == 'All Category') ? true : (p.category == cat);
      final matchLow = _lowStockOnly ? p.stock <= _lowStockAt : true;
      return matchSearch && matchCat && matchLow;
    }).toList();

    setState(() {
      _items
        ..clear()
        ..addAll(filtered);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _selectedDrawer = 4;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductPage()),
              );
              break;
            case 2: // Activity History
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityHistoryPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementPage()),
              );
              break;
            case 4:

              break;
          }
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 12),
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // left icon (rounded dark)
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
                  // right floating square button
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

            // ===== Filter Panel (Dark) =====
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
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    const LabelWhite('Category'),
                    const SizedBox(height: 8),
                    CategoryDropdown(
                      value: Category,
                      items: Categories,
                      onChanged: (v) => setState(() => Category = v ?? 'All Category'),
                    ),
                    const SizedBox(height: 10),
                    // teks abu kecil "Checkbox Field" (agar match persis screenshot)
                    const Text(
                      'Checkbox Field',
                      style: TextStyle(
                        color: Color(0x66FFFFFF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Low stock checkbox
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: _lowStockOnly,
                            onChanged: (v) => setState(() => _lowStockOnly = v ?? false),
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
                        onPressed: _applyFilter,
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

            // ===== Products List =====
            ..._items.map(
                  (p) => ProductCard(
                data: p,
                onView: () {
                  // TODO: aksi ketika "View" ditekan
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View: ${p.name}')),
                  );
                },
              ),
            ),
            if (_items.isEmpty)
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
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}