import 'package:flutter/material.dart';

import '../config/app_color.dart';
import 'drawer_section_label.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColor.dark,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Inventory Control",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColor.textDark,
                            )),
                        SizedBox(height: 2),
                        Text("Staff Gudang",
                            style: TextStyle(
                              color: AppColor.hint,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColor.divider),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context,
                    index: 0,
                    selectedIndex: selectedIndex,
                    icon: Icons.dashboard_customize_rounded,
                    label: "Dashboard",
                    onTap: onTap,
                  ),
                  _drawerItem(
                    context,
                    index: 1,
                    selectedIndex: selectedIndex,
                    icon: Icons.person_outline_rounded,
                    label: "Profile",
                    onTap: onTap,
                  ),
                  DrawerSectionLabel("Activity Management"),
                  _drawerItem(
                    context,
                    index: 2,
                    selectedIndex: selectedIndex,
                    icon: Icons.receipt_long_rounded,
                    label: "Activity History",
                    onTap: onTap,
                  ),
                  DrawerSectionLabel("User Management"),
                  _drawerItem(
                    context,
                    index: 3,
                    selectedIndex: selectedIndex,
                    icon: Icons.groups_rounded,
                    label: "User Management",
                    onTap: onTap,
                  ),
                  DrawerSectionLabel("Inventory Management"),
                  _drawerItem(
                    context,
                    index: 4,
                    selectedIndex: selectedIndex,
                    icon: Icons.inventory_2_rounded,
                    label: "Products",
                    onTap: onTap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, {
        required int index,
        required int selectedIndex,
        required IconData icon,
        required String label,
        required ValueChanged<int> onTap,
      }) {
    final selected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(index),
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