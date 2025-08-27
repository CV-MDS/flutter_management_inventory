import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/pref.dart';
import '../config/app_color.dart';
import 'drawer_section_label.dart';

class SidebarDrawer extends StatefulWidget {
  const SidebarDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer> {
  String? _userType; // "admin" | "staff" | "owner"

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final t = await Session().getUserType();
    if (!mounted) return;
    setState(() => _userType = t);
  }

  String _roleLabel() {
    switch (_userType) {
      case 'admin':
        return 'Administrator';
      case 'owner':
        return 'Owner';
      case 'staff':
      default:
        return 'Staff Gudang';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAF5F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColor.dark,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Inventory Control",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColor.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roleLabel(),
                          style: const TextStyle(
                            color: AppColor.hint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColor.divider),

            // Menu
            Expanded(
              child: (_userType == null)
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildMenuByRole(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuByRole(BuildContext context) {
    switch (_userType) {
      case 'admin':
        return [
          _drawerItem(
            context,
            index: 0,
            icon: Icons.dashboard_customize_rounded,
            label: "Dashboard",
          ),
          _drawerItem(
            context,
            index: 1,
            icon: Icons.person_outline_rounded,
            label: "Profil",
          ),
          const DrawerSectionLabel("ACTIVITY MANAGEMENT"),
          _drawerItem(
            context,
            index: 2,
            icon: Icons.receipt_long_rounded,
            label: "Activity History",
          ),
          _drawerItem(
            context,
            index: 3,
            icon: Icons.groups_rounded,
            label: "User Management",
          ),
          const DrawerSectionLabel("INVENTORY MANAGEMENT"),
          _drawerItem(
            context,
            index: 4,
            icon: Icons.inventory_2_rounded,
            label: "Products",
          ),
        ];

      case 'owner':
        return [
          _drawerItem(
            context,
            index: 0,
            icon: Icons.dashboard_customize_rounded,
            label: "Dashboard",
          ),
          _drawerItem(
            context,
            index: 1,
            icon: Icons.person_outline_rounded,
            label: "Profil",
          ),
          const DrawerSectionLabel("INVENTORY MANAGEMENT"),
          // pakai index 3 untuk Products (beda dari admin yg 4),
          // sesuaikan switch navigasi kamu.
          _drawerItem(
            context,
            index: 3,
            icon: Icons.inventory_2_rounded,
            label: "Products",
          ),
          const DrawerSectionLabel("REPORTS"),
          _drawerItem(
            context,
            index: 6,
            icon: Icons.insert_chart_outlined_rounded,
            label: "Stock In Reports",
          ),
          _drawerItem(
            context,
            index: 7,
            icon: Icons.insert_chart_outlined_rounded,
            label: "Stock Out Reports",
          ),
        ];

      case 'staff':
      default:
        return [
          _drawerItem(
            context,
            index: 0,
            icon: Icons.dashboard_customize_rounded,
            label: "Dashboard",
          ),
          _drawerItem(
            context,
            index: 1,
            icon: Icons.person_outline_rounded,
            label: "Profil",
          ),
          const DrawerSectionLabel("INVENTORY MANAGEMENT"),
          _drawerItem(
            context,
            index: 2,
            icon: Icons.local_offer_outlined,
            label: "Categories",
          ),
          _drawerItem(
            context,
            index: 3,
            icon: Icons.inventory_2_rounded,
            label: "Products",
          ),
          _drawerItem(
            context,
            index: 4,
            icon: Icons.arrow_back_rounded,
            label: "Stock In",
          ),
          _drawerItem(
            context,
            index: 5,
            icon: Icons.arrow_forward_rounded,
            label: "Stock Out",
          ),
        ];
    }
  }

  Widget _drawerItem(
      BuildContext context, {
        required int index,
        required IconData icon,
        required String label,
      }) {
    final selected = index == widget.selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColor.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColor.textDark),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColor.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
