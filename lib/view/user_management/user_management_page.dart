import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/view/user_management/user_detail_page.dart';
import 'package:intl/intl.dart';

/// -----------------------
/// Model & Dummy Data
/// -----------------------
class AppUser {
  final String name;
  final String email;
  final String role; // e.g. "Staff", "Admin"
  final bool active;
  final DateTime joinedAt;
  final DateTime updatedAt;

  const AppUser({
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.joinedAt,
    required this.updatedAt,
  });
}

final _dummyUsers = <AppUser>[
  AppUser(
    name: 'Staff dua',
    email: 'Staffdua@gmail.com',
    role: 'Staff',
    active: true,
    joinedAt: DateTime(2025, 8, 12, 15, 20),
    updatedAt: DateTime(2025, 8, 12, 15, 20),
  ),
  AppUser(
    name: 'Staff tiga',
    email: 'Stafftiga@gmail.com',
    role: 'Staff',
    active: true,
    joinedAt: DateTime(2025, 8, 12, 15, 20),
    updatedAt: DateTime(2025, 8, 12, 15, 20),
  ),
  AppUser(
    name: 'Staff empat',
    email: 'Staffempat@gmail.com',
    role: 'Staff',
    active: true,
    joinedAt: DateTime(2025, 8, 12, 15, 20),
    updatedAt: DateTime(2025, 8, 12, 15, 20),
  ),
];


/// -----------------------
/// Badges
/// -----------------------
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final EdgeInsets padding;
  final double radius;
  const Pill(
      {super.key,
        required this.text,
        required this.bg,
        required this.fg,
        this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Text(text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          )),
    );
  }
}

/// -----------------------
/// User Management Page
/// -----------------------
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _search = TextEditingController();
  List<AppUser> _filtered = List.of(_dummyUsers);

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = _dummyUsers
          .where((u) =>
      u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.role.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkChip = const Color(0xFF2C2F39);
    final bg = const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leadingWidth: 74,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.black87),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Management",
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF222222))),
            SizedBox(height: 2),
            Text("Kelola pengguna sistem",
                style: TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Color(0xFF222222)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: _applyFilter,
                  decoration: InputDecoration(
                    hintText: "Searching",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkChip,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: const Text(
              "Tambahkan User",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          ..._filtered.map((u) => _UserTile(
            user: u,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserDetailPage(user: u)),
              );
            },
          )),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.onTap});

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
                    text: user.active ? "Aktif" : "Nonaktif",
                    bg: user.active ? const Color(0xFF5AF157) : Colors.grey.shade400,
                    fg: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(width: 2),
                  Pill(
                    text: user.role,
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


