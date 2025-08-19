import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/view/home/home_page.dart';
import 'package:flutter_management_inventory/view/user_management/user_management_page.dart';

import '../../widget/sidebar_drawer.dart';
import '../activity_history/activity_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name = 'Admin',
    this.email = 'admin@gmail.com',
    this.role = 'Admin',
    this.statusActive = true,
    this.joinDate,
    this.lastActive,
  });

  final String name;
  final String email;
  final String role;
  final bool statusActive;
  final DateTime? joinDate;
  final DateTime? lastActive;

  @override
  State<ProfilePage> createState() => _ProfilePageState();

  static Widget _chip(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  Color get _navy => const Color(0xFF2C3047);

  Color get _softBg => const Color(0xFFF5F7FB);

  Color get _chipRed => const Color(0xFFFF6B6B);

  Color get _chipGreen => const Color(0xFF29CC63);

  Color get _textDark => const Color(0xFF232323);

  Color get _textGrey => const Color(0xFF8C8C8C);

  String _fmtDate(DateTime d, {bool withTime = false}) {
    // 12 August 2025, 15:20
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final m = months[d.month - 1];
    final base = '${d.day} $m ${d.year}';
    if (!withTime) return base;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$base, $hh:$mm';
  }

  String _ago(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 1) return '(${diff.inDays} days ago)';
    if (diff.inHours >= 1) return '(${diff.inHours} hours ago)';
    if (diff.inMinutes >= 1) return '(${diff.inMinutes} minutes ago)';
    return '(just now)';
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedDrawer = 0;

  @override
  Widget build(BuildContext context) {
    final joined = widget.joinDate ?? DateTime.now().subtract(const Duration(days: 3));
    final last = widget.lastActive ?? DateTime.now().subtract(const Duration(days: 3, hours: -15, minutes: -20));

    return Scaffold(
      backgroundColor: _softBg,
      key: _scaffoldKey,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  _circleSquare(
                    bg: _navy,
                    icon: Icons.tune_rounded,
                    iconColor: Colors.white,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  _circleSquare(
                    bg: Colors.white,
                    border: Border.all(color: Colors.black12),
                    icon: Icons.open_in_new_rounded,
                    iconColor: _textDark,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== Top Card =====
              Container(
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ProfilePage._chip(widget.role, color: _chipRed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Akun',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 18),
                    _label('Nama Lengkap'),
                    _value(widget.name),
                    const SizedBox(height: 14),
                    _label('Alamat Gmail'),
                    _value(widget.email),
                    const SizedBox(height: 14),

                    _label('Role/Jabatan'),
                    ProfilePage._chip(widget.role, color: _chipRed),
                    const SizedBox(height: 14),

                    _label('Status Akun'),
                    ProfilePage._chip(widget.statusActive ? 'Aktif' : 'Nonaktif',
                        color: _chipGreen),
                    const SizedBox(height: 14),

                    _label('Bergabung Sejak'),
                    _value('${_fmtDate(joined)} ${_ago(joined)}'),
                    const SizedBox(height: 14),

                    _label('Bergabung Sejak'),
                    _value('${_fmtDate(last, withTime: true)} ${_ago(last)}'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          'Administrative controls and system management',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _circleSquare(
                    bg: Colors.white,
                    border: Border.all(color: Colors.black12),
                    icon: Icons.arrow_forward_rounded,
                    iconColor: _textDark,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _quickAction(
                icon: Icons.person_rounded,
                title: 'Lihat Profile',
                subtitle: 'Kelola informasi akun',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _quickAction(
                icon: Icons.group_rounded,
                title: 'Management Users',
                subtitle: 'Quick Access',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserManagementPage(),),);
                },
              ),
              const SizedBox(height: 12),
              _quickAction(
                icon: Icons.history_edu_rounded,
                title: 'Activity Logs',
                subtitle: 'Quick Access',
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // ===== Edit Button =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Small UI helpers =====
  Widget _circleSquare({
    required Color bg,
    Border? border,
    required IconData icon,
    Color iconColor = Colors.black,
    double size = 44,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: _textGrey,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _value(String text) => Text(
    text,
    style: TextStyle(
      color: _textDark,
      fontSize: 15.5,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF333333)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
