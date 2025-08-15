import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';
import 'package:flutter_management_inventory/view/base_page.dart';

import '../../config/pref.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../widget/activity_tile.dart';
import '../../widget/circle_icon.dart';
import '../../widget/custom_toast.dart';
import '../../widget/quick_tile.dart';
import '../../widget/section_header.dart';
import '../../widget/sidebar_drawer.dart';
import '../../widget/stat_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawer = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarDrawer(
        selectedIndex: _selectedDrawer,
        onTap: (i) {
          setState(() => _selectedDrawer = i);
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    CircleIcon(
                      icon: Icons.menu,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ],
                ),
              ),
            ),

            // Header profile + tombol aksi kanan + search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColor.dark,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Dasboard",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.textDark,
                                  )),
                              SizedBox(height: 2),
                              Text("Administrator",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColor.hint,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
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
                                          (Route<dynamic> route) => false);
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
                            child: Row(
                              children: const [
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
                        const SizedBox(width: 10),
                        CircleIcon(
                          icon: Icons.tune_rounded,
                          onTap: () {},
                          dark: true,
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang, Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Kelola seluruh sistem dan pengguna\ndengan akses penuh",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                        value: "4",
                        label: "Total User",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.inventory_2_rounded,
                        value: "4",
                        label: "Products",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.today_rounded,
                        value: "4",
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
                subtitle:
                "Administrative controls and system management",
                onTap: () {},
              ),
            ),

            // Quick Action Tiles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: const [
                    QuickTile(
                      icon: Icons.person_rounded,
                      title: "Lihat Profile",
                      subtitle: "Kelola informasi akun",
                    ),
                    SizedBox(height: 10),
                    QuickTile(
                      icon: Icons.groups_rounded,
                      title: "Management Users",
                      subtitle: "Quick Access",
                    ),
                    SizedBox(height: 10),
                    QuickTile(
                      icon: Icons.history_toggle_off_rounded,
                      title: "Activity Logs",
                      subtitle: "Quick Access",
                    ),
                  ],
                ),
              ),
            ),

            // Your activity header
            SliverToBoxAdapter(
              child: SectionHeader(
                title: "Your activity",
                onTap: () {},
              ),
            ),

            // Activity list
            SliverList.separated(
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ActivityTile(
                    title: "Login",
                    subtitle: "Login by admin",
                    trailingTime: "1h",
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

  Future<bool> showConfirmLogoutDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // biar tidak ketutup tanpa pilihan
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
}
