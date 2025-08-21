import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/model/user_management.dart';
import 'package:flutter_management_inventory/widget/pill.dart';

class UserTile extends StatelessWidget {
  final UserManagementUser user;
  final VoidCallback onTap;
  const UserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, size: 30, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                      const SizedBox(height: 4),
                      Text(user.email, style: const TextStyle(color: Color(0xFF8B8E99))),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Pill(
                    text: user.active ?? false ? "Aktif" : "Nonaktif",
                    bg: user.active ?? false ? const Color(0xFF5AF157) : Colors.grey.shade400,
                    fg: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Pill(
                    text: user.roles,
                    bg: const Color(0xFFFF3B30),
                    fg: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}