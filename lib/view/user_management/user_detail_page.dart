import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/view/user_management/user_management_page.dart';
import 'package:intl/intl.dart';

/// -----------------------
/// User Detail Page
/// -----------------------
///
String _fmtDT(DateTime dt) => DateFormat("d MMMM y, HH:mm").format(dt);

class UserDetailPage extends StatelessWidget {
  final AppUser user;
  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF5F6FA);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Detail User",
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF222222))),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: Color(0xFF222222))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                          const SizedBox(height: 4),
                          Text(user.email, style: const TextStyle(color: Color(0xFF8B8E99))),
                        ],
                      ),
                    ),
                    Pill(text: user.role, bg: const Color(0xFFFF3B30), fg: Colors.white),
                  ]),
                  const SizedBox(height: 12),
                  Pill(
                    text: user.active ? "Aktif" : "Nonaktif",
                    bg: user.active ? const Color(0xFF5AF157) : Colors.grey.shade400,
                    fg: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text("Bergabung sejak",
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                  Text(_fmtDT(user.joinedAt), style: const TextStyle(color: Color(0xFF8B8E99))),
                  const SizedBox(height: 12),
                  const Text("Terakhir Diupdate",
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                  Text(_fmtDT(user.updatedAt), style: const TextStyle(color: Color(0xFF8B8E99))),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      const Text("Akun dibuat", style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 2),
                    child: Text(_fmtDT(user.joinedAt), style: const TextStyle(color: Color(0xFF8B8E99))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2F39),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}