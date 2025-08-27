import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';
import 'package:flutter_management_inventory/model/dashboard.dart';
import 'package:flutter_management_inventory/view/activity_history/activity_history_page.dart';
import 'package:flutter_management_inventory/view/base_page.dart';
import 'package:flutter_management_inventory/view/product/product_page.dart';
import 'package:flutter_management_inventory/view/profile/profile_page.dart';
import 'package:flutter_management_inventory/view/stock_in/stock_in_page.dart';
import 'package:flutter_management_inventory/view/stock_out/stock_out_page.dart';
import 'package:flutter_management_inventory/viewmodel/dashboard_viewmodel.dart';

import '../../config/pref.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../widget/activity_tile.dart';
import '../../widget/circle_icon.dart';
import '../../widget/custom_toast.dart';
import '../../widget/quick_tile.dart';
import '../../widget/section_header.dart';
import '../../widget/sidebar_drawer.dart';
import '../../widget/stat_card.dart';
import '../category/category_page.dart';
import '../user_management/user_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawer = 0;

  Dashboard? _dashboard;
  bool _isLoading = true;
  String? _error, _userType, _name, _email;

  @override
  void initState() {
    super.initState();
    getProfile();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    final t = await Session().getUserType();
    if (!mounted) return;
    setState(() {
      _userType = t;
      _isLoading = false;
    });

    if (_userType == "admin"){
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final res = await DashboardViewmodel().getDashboard();
      if (!mounted) return;

      if (res.code == 200) {
        // Beberapa wrapper Resp punya res.data langsung berisi payload “data”,
        // tapi kalau tidak, fallback ke res.data['data'].
        final dynamic raw = res.data;
        final Map<String, dynamic> payload = (raw is Map<String, dynamic> && raw.containsKey('user'))
            ? raw
            : (raw is Map<String, dynamic> ? (raw['data'] as Map<String, dynamic>) : <String, dynamic>{});

        setState(() {
          _dashboard = Dashboard.fromJson(payload);
          _isLoading = false;
        });
      } else if (res.code == 401) {
        // Token invalid → paksa logout
        await Session().logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BasePage()),
              (route) => false,
        );
      } else {
        setState(() {
          _error = res.message ?? 'Failed to load dashboard';
          _isLoading = false;
        });
      }
    }

  }

  String _agoShort(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  Future<void> getProfile() async {
    await AuthViewmodel().profile().then((value) {
      if (value.code == 200){
        setState(() {
          _name = value.data['name'];
          _email = value.data['email'];
        });
      }
    },);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarDrawer(
        selectedIndex: _selectedDrawer,
        onTap: (i) => _handleDrawerTap(i),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorState()
            : CustomScrollView(
          slivers: [
            // Header profile + tombol aksi kanan + search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfilePage()),
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColor.dark,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _go(1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Dashboard",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _userType ?? "",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColor.hint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        CircleIcon(
                          icon: Icons.logout_rounded,
                          onTap: () async {
                            final ok = await showConfirmLogoutDialog(context);
                            if (ok) {
                              AuthViewmodel().logout().then((value) async {
                                if (value.code == 200) {
                                  await Session().logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const BasePage()),
                                        (Route<dynamic> route) => false,
                                  );
                                  showToast(context: context, msg: "Logout Berhasil");
                                } else {
                                  showToast(context: context, msg: "Terjadi Kesalahan");
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleIcon(
                          icon: Icons.tune_rounded,
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          dark: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppColor.hint),
                                SizedBox(width: 8),
                                Text(
                                  "Searching",
                                  style: TextStyle(
                                    color: AppColor.hint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Welcome card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColor.dark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang, $_name",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),

            // Stat cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.insert_drive_file_rounded,
                        value: (_dashboard?.totalUsers ?? 0).toString(),
                        label: "Total User",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.inventory_2_rounded,
                        value: (_dashboard?.totalProducts ?? 0).toString(),
                        label: "Products",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.today_rounded,
                        value: (_dashboard?.todayActivities ?? 0).toString(),
                        label: "Today activity",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions header
            SliverToBoxAdapter(
              child: SectionHeader(
                title: "Quick Actions",
                subtitle: "Administrative controls and system management",
                onTap: () {},
              ),
            ),

            // Quick Action Tiles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    QuickTile(
                      icon: Icons.person_rounded,
                      title: "Lihat Profile",
                      subtitle: "Kelola informasi akun",
                      onTap: () => _go(1),
                    ),
                    const SizedBox(height: 10),
                    _userType == "admin" ? QuickTile(
                      icon: Icons.groups_rounded,
                      title: "Management Users",
                      subtitle: "Quick Access",
                      onTap: () => _go(3),
                    ) : Container(),
                    const SizedBox(height: 10),
                    _userType == "admin" ? QuickTile(
                      icon: Icons.history_toggle_off_rounded,
                      title: "Activity Logs",
                      subtitle: "Quick Access",
                      onTap: () => _go(2),
                    ) : Container(),
                  ],
                ),
              ),
            ),

            // Your activity header
            _userType == "admin" ? SliverToBoxAdapter(
              child: SectionHeader(
                title: "Your activity",
                onTap: () {},
              ),
            ) : const SliverToBoxAdapter(child: SizedBox.shrink()),

            // Activity list dari API
            if ((_dashboard?.recentActivities ?? []).isEmpty)
              _userType == "admin" ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('No recent activity')),
                ),
              ) : const SliverToBoxAdapter(child: SizedBox.shrink())
            else
              _userType == "admin" ? SliverList.separated(
                itemCount: _dashboard!.recentActivities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = _dashboard!.recentActivities[i];
                  final title = (a.action ?? '').isEmpty
                      ? 'Activity'
                      : a.action![0].toUpperCase() + a.action!.substring(1);
                  final subtitle = a.description ?? a.ipAddress ?? '-';
                  final trailing = a.createdAt != null ? _agoShort(a.createdAt!) : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ActivityTile(
                      title: title,
                      subtitle: subtitle,
                      trailingTime: trailing,
                    ),
                  );
                },
              ) : const SliverToBoxAdapter(child: SizedBox.shrink()),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
        case 0: break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage())); break;
        case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage())); break;
        case 4: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage())); break;
        default: break;
      }
      return;
    }

    if (type == 'staff') {
      switch (i) {
        case 0: break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPage()));
          break;
        case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage())); break;
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
        case 0: break;
        case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
        case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage())); break;
        case 3:
        // TODO: ganti ke StockInReportsPage
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Go to Stock In Reports')));
          break;
        case 4:
        // TODO: ganti ke StockOutReportsPage
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Go to Stock Out Reports')));
          break;
        default: break;
      }
      return;
    }
  }


  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? 'Error', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<bool> showConfirmLogoutDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _go(int index) {
    // Perbarui selected drawer state agar highlight di sidebar sesuai
    setState(() => _selectedDrawer = index);

    switch (index) {
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()));
        break;
    }
  }
}
