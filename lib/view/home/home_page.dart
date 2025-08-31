import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';
import 'package:flutter_management_inventory/model/dashboard.dart';
import 'package:flutter_management_inventory/view/activity_history/activity_history_page.dart';
import 'package:flutter_management_inventory/view/base_page.dart';
import 'package:flutter_management_inventory/view/product/product_page.dart';
import 'package:flutter_management_inventory/view/profile/profile_page.dart';
import 'package:flutter_management_inventory/view/stock_in/stock_in_page.dart';
import 'package:flutter_management_inventory/view/stock_in_report/stock_in_report_page.dart';
import 'package:flutter_management_inventory/view/stock_out/stock_out_page.dart';
import 'package:flutter_management_inventory/view/stock_out_report/stock_out_report_page.dart';
import 'package:flutter_management_inventory/viewmodel/dashboard_viewmodel.dart';

import '../../config/pref.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/report_viewmodel.dart';
import '../../viewmodel/show_dialog_logout.dart';
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

class _OutBar {
  final String name;
  final int qty;
  _OutBar(this.name, this.qty);
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawer = 0;

  Dashboard? _dashboard;
  bool _isLoading = true;
  String? _error, _userType, _name, _email;

  // ==== owner chart state ====
  int? _ownerInCount, _ownerOutCount;
  bool _ownerLoading = false;
  String? _ownerErr;


  List<_OutBar> _ownerTopOut = [];

  @override
  void initState() {
    super.initState();
    getProfile();
    _fetchDashboard();
  }

  Future<void> getProfile() async {
    final res = await AuthViewmodel().profile();
    if (!mounted) return;
    if (res.code == 200) {
      setState(() {
        _name = res.data['name'];
        _email = res.data['email'];
      });
    }
  }

  Future<void> _fetchDashboard() async {
    final t = await Session().getUserType();
    if (!mounted) return;
    setState(() {
      _userType = t;
      _isLoading = false;
    });

    if (_userType == "admin") {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final res = await DashboardViewmodel().getDashboard();
      if (!mounted) return;

      if (res.code == 200) {
        final dynamic raw = res.data;
        final Map<String, dynamic> payload =
        (raw is Map<String, dynamic> && raw.containsKey('user'))
            ? raw
            : (raw is Map<String, dynamic>
            ? (raw['data'] as Map<String, dynamic>)
            : <String, dynamic>{});

        setState(() {
          _dashboard = Dashboard.fromJson(payload);
          _isLoading = false;
        });
      } else if (res.code == 401) {
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
    } else if (_userType == "owner") {
      _fetchOwnerCharts();
    }
  }

  // ===== owner reports =====
  int _rowsCount(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      final m = Map<String, dynamic>.from(raw['data'] as Map);
      final list = (m['rows'] as List?) ?? (m['items'] as List?) ?? const [];
      return list.length;
    }
    if (raw is Map<String, dynamic>) {
      final list = (raw['rows'] as List?) ?? (raw['items'] as List?) ?? const [];
      return list.length;
    }
    if (raw is List) return raw.length;
    return 0;
  }

  Future<void> _fetchOwnerCharts() async {
    setState(() {
      _ownerLoading = true;
      _ownerErr = null;
      _ownerInCount = null;
      _ownerOutCount = null;
      _ownerTopOut.clear();
    });

    try {
      final inResp  = await ReportViewmodel().stockInReports();
      final outResp = await ReportViewmodel().stockOutsReports();

      final inCount  = _rowsCount(inResp.data);
      final outCount = _rowsCount(outResp.data);

      // --- hitung Top Products dari laporan stock-out ---
      final topOut = _extractTopOut(outResp.data); // ambil top 10 max

      if (!mounted) return;
      setState(() {
        _ownerInCount  = inCount;
        _ownerOutCount = outCount;
        _ownerTopOut   = topOut;
        _ownerLoading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ownerErr = e.toString();
        _ownerLoading = false;
      });
    }
  }

  List<_OutBar> _extractTopOut(dynamic raw) {
    // raw shape: { data: { rows: [ { items: [ { quantity, product:{name} } ] } ] } }
    final Map<String, int> acc = {};

    // ambil list rows
    List rows;
    if (raw is Map && raw['data'] is Map) {
      rows = (raw['data']['rows'] as List?) ?? const [];
    } else if (raw is Map<String, dynamic>) {
      rows = (raw['rows'] as List?) ?? const [];
    } else if (raw is List) {
      rows = raw;
    } else {
      rows = const [];
    }

    for (final r in rows) {
      final items = (r is Map ? r['items'] : null) as List? ?? const [];
      for (final it in items) {
        if (it is! Map) continue;
        final qty = (it['quantity'] is int)
            ? it['quantity'] as int
            : int.tryParse('${it['quantity'] ?? 0}') ?? 0;
        final prod = (it['product'] as Map?) ?? const {};
        final name = (prod['name'] ?? 'Unknown').toString();
        acc[name] = (acc[name] ?? 0) + qty;
      }
    }

    final list = acc.entries
        .map((e) => _OutBar(e.key, e.value))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    // ambil top 10 biar sumbu X masih terbaca
    return list.take(10).toList();
  }


  String _agoShort(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
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
            // ===== Header/profile/search =====
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
                            MaterialPageRoute(
                                builder: (_) => const ProfilePage()),
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColor.dark,
                            child: Icon(Icons.person,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _go(1),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                            final ok =
                            await showConfirmLogoutDialog(context);
                            if (ok) {
                              AuthViewmodel()
                                  .logout()
                                  .then((value) async {
                                if (value.code == 200) {
                                  await Session().logout();
                                  if (!mounted) return;
                                  Navigator.of(context)
                                      .pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const BasePage()),
                                        (Route<dynamic> route) => false,
                                  );
                                  showToast(
                                      context: context,
                                      msg: "Logout Berhasil");
                                } else {
                                  showToast(
                                      context: context,
                                      msg: "Terjadi Kesalahan");
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
                          onTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
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
                                  color:
                                  Colors.black.withOpacity(.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: const Row(
                              children: [
                                Icon(Icons.search,
                                    color: AppColor.hint),
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

            // ===== Welcome card =====
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
                        "Selamat Datang, ${_name ?? '-'}",
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

            // === Owner charts ===
            if (_userType == "owner")
              const SliverToBoxAdapter(child: SizedBox(height: 4))
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),

            if (_userType == "owner")
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _ownerStockTrendsCard()))
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),

// >>> Tambahkan ini <<<
            if (_userType == "owner")
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _ownerTopProductsCard()))
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),


            // ===== Admin/Staff: Stat cards =====
            if (_userType != "owner")
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.insert_drive_file_rounded,
                          value:
                          (_dashboard?.totalUsers ?? 0).toString(),
                          label: "Total User",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          icon: Icons.inventory_2_rounded,
                          value: (_dashboard?.totalProducts ?? 0)
                              .toString(),
                          label: "Products",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          icon: Icons.today_rounded,
                          value: (_dashboard?.todayActivities ?? 0)
                              .toString(),
                          label: "Today activity",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ===== Quick Actions =====
            if (_userType != "owner")
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: "Quick Actions",
                  subtitle:
                  "Administrative controls and system management",
                  onTap: () {},
                ),
              ),
            if (_userType != "owner")
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      QuickTile(
                        icon: Icons.person_rounded,
                        title: "Lihat Profile",
                        subtitle: "Kelola informasi akun",
                        onTap: () => _go(1),
                      ),
                      const SizedBox(height: 10),
                      if (_userType == "admin")
                        QuickTile(
                          icon: Icons.groups_rounded,
                          title: "Management Users",
                          subtitle: "Quick Access",
                          onTap: () => _go(3),
                        ),
                      const SizedBox(height: 10),
                      if (_userType == "admin")
                        QuickTile(
                          icon:
                          Icons.history_toggle_off_rounded,
                          title: "Activity Logs",
                          subtitle: "Quick Access",
                          onTap: () => _go(2),
                        ),
                    ],
                  ),
                ),
              ),

            // ===== Admin: Activity =====
            if (_userType == "admin")
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: "Your activity",
                  onTap: () {},
                ),
              ),
            if (_userType == "admin" &&
                (_dashboard?.recentActivities ?? []).isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('No recent activity')),
                ),
              ),
            if (_userType == "admin" &&
                (_dashboard?.recentActivities ?? []).isNotEmpty)
              SliverList.separated(
                itemCount: _dashboard!.recentActivities.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = _dashboard!.recentActivities[i];
                  final title = (a.action ?? '').isEmpty
                      ? 'Activity'
                      : a.action![0].toUpperCase() +
                      a.action!.substring(1);
                  final subtitle =
                      a.description ?? a.ipAddress ?? '-';
                  final trailing = a.createdAt != null
                      ? _agoShort(a.createdAt!)
                      : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: ActivityTile(
                      title: title,
                      subtitle: subtitle,
                      trailingTime: trailing,
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ===== Drawer navigation =====
  void _handleDrawerTap(int i) {
    setState(() => _selectedDrawer = i);
    Navigator.pop(context);

    final type = _userType ?? 'admin';

    if (type == 'admin') {
      switch (i) {
        case 0:
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProductPage()));
          break;
      }
      return;
    }

    if (type == 'staff') {
      switch (i) {
        case 0:
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          break;
        case 2:
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoryPage()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProductPage()));
          break;
        case 4:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StockInPage()));
          break;
        case 5:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StockOutPage()));
          break;
      }
      return;
    }

    if (type == 'owner') {
      switch (i) {
        case 0:
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProductPage()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StockInReportPage()));
          break;
        case 4:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StockOutReportPage()));
          break;
      }
      return;
    }
  }

  // ===== helpers =====
  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? 'Error',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _go(int index) {
    setState(() => _selectedDrawer = index);
    switch (index) {
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UserManagementPage()));
        break;
    }
  }

  // ===== Owner chart card =====
  Widget _ownerStockTrendsCard() {
    const green = Color(0xFF22C55E);
    const red = Color(0xFFEF4444);
    final inCount = _ownerInCount ?? 0;
    final outCount = _ownerOutCount ?? 0;
    final total = (inCount + outCount).toDouble();

    if (_ownerLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ownerErr != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_ownerErr!,
                style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _fetchOwnerCharts, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stock Trends',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColor.textDark)),
          const SizedBox(height: 4),
          const Text('Stock In vs Stock Out (bulan ini)',
              style:
              TextStyle(color: AppColor.hint, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          SizedBox(
            height: 260,
            child: total == 0
                ? const Center(
              child: Text('No data',
                  style: TextStyle(
                      color: AppColor.hint,
                      fontWeight: FontWeight.w700)),
            )
                : PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(
                    value: inCount.toDouble(),
                    color: green,
                    title: '',
                  ),
                  PieChartSectionData(
                    value: outCount.toDouble(),
                    color: red,
                    title: '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: green, label: 'Stock In'),
              SizedBox(width: 16),
              _LegendDot(color: red, label: 'Stock Out'),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _SummaryTintCard(
                  bg: const Color(0xFFEFFDF3),
                  dot: green,
                  title: 'Total Stock In',
                  value: inCount.toString(),
                  caption: 'This month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTintCard(
                  bg: const Color(0xFFFFF2F2),
                  dot: red,
                  title: 'Total Stock Out',
                  value: outCount.toString(),
                  caption: 'This month',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerTopProductsCard() {
    const red = Color(0xFFEF4444);

    if (_ownerLoading) {
      return const _OwnerCardShell(child: Center(child: CircularProgressIndicator()));
    }
    if (_ownerErr != null) {
      return _OwnerCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OwnerCardHeader(title: 'Top Products Stock-Out', subtitle: 'Periode: 30 hari terakhir'),
            const SizedBox(height: 12),
            Text(_ownerErr!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchOwnerCharts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_ownerTopOut.isEmpty) {
      return const _OwnerCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OwnerCardHeader(title: 'Top Products Stock-Out', subtitle: 'Periode: 30 hari terakhir'),
            SizedBox(height: 12),
            Center(child: Text('No data', style: TextStyle(color: AppColor.hint, fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }

    // hitung maxY & interval grid
    final maxY = _ownerTopOut.map((e) => e.qty).reduce((a, b) => a > b ? a : b).toDouble();
    final niceMax = (maxY == 0) ? 1.0 : (maxY * 1.2);
    final interval = (niceMax / 8).clamp(1, 999).ceilToDouble();

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < _ownerTopOut.length; i++) {
      final v = _ownerTopOut[i].qty.toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: v,
              width: 18,
              color: red.withOpacity(.15),
              borderSide: const BorderSide(color: red, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return _OwnerCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OwnerCardHeader(title: 'Top Products Stock-Out', subtitle: 'Periode: 30 hari terakhir'),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: niceMax,
                barGroups: groups,
                gridData: FlGridData(
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: interval,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= _ownerTopOut.length) return const SizedBox.shrink();
                        final label = _ownerTopOut[idx].name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                barTouchData: BarTouchData(enabled: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _OwnerCardShell extends StatelessWidget {
  const _OwnerCardShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _OwnerCardHeader extends StatelessWidget {
  const _OwnerCardHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColor.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColor.hint, fontWeight: FontWeight.w600)),
          ]),
        ),
        // Optional: dropdown metrik (placeholder)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: const Text('Total Qty', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}


// ===== Small UI helpers for owner card =====
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColor.textDark)),
      ],
    );
  }
}

class _SummaryTintCard extends StatelessWidget {
  const _SummaryTintCard({
    required this.bg,
    required this.dot,
    required this.title,
    required this.value,
    required this.caption,
  });
  final Color bg;
  final Color dot;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColor.textDark)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColor.textDark)),
          const SizedBox(height: 4),
          Text(caption,
              style: const TextStyle(
                  color: AppColor.hint, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
