import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Activity {
  final String activity; // e.g. "Login"
  final String module;   // e.g. "System"
  final String description;
  final String user;
  final String role;     // e.g. "Admin"
  final DateTime at;
  final bool ok;         // hijau/merah

  Activity({
    required this.activity,
    required this.module,
    required this.description,
    required this.user,
    required this.role,
    required this.at,
    required this.ok,
  });
}

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final _search = TextEditingController();
  final _all = <Activity>[
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: true,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: true,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: true,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: false,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: true,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: false,
    ),
    Activity(
      activity: 'Login',
      module: 'System',
      description: 'Login Login',
      user: 'Admin',
      role: 'Admin',
      at: DateTime(2025, 8, 15, 18, 05),
      ok: true,
    ),
  ];

  List<Activity> _filtered = [];
  bool _autoRefresh = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(_all);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((a) {
        return a.activity.toLowerCase().contains(query) ||
            a.module.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query) ||
            a.user.toLowerCase().contains(query) ||
            a.role.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleAutoRefresh() {
    setState(() => _autoRefresh = !_autoRefresh);
    _timer?.cancel();
    if (_autoRefresh) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    }
  }

  // Di sini kamu sambungkan ke API-mu. Sekarang cuma simulasi.
  Future<void> _refresh() async {
    // contoh: swap status ok/false beberapa item biar kelihatan berubah
    setState(() {
      for (var i = 0; i < _all.length; i += 2) {
        _all[i] = Activity(
          activity: _all[i].activity,
          module: _all[i].module,
          description: _all[i].description,
          user: _all[i].user,
          role: _all[i].role,
          at: DateTime.now(),
          ok: !_all[i].ok,
        );
      }
      _applyFilter(_search.text);
    });
  }

  void _exportCsv() {
    final header = "Activity,Module,Description,User,Role,Date,Time,OK";
    final rows = _filtered.map((a) {
      final d = DateFormat("MMM d, y").format(a.at);
      final t = DateFormat("hh:mm a").format(a.at);
      return [
        a.activity,
        a.module,
        a.description,
        a.user,
        a.role,
        d,
        t,
        a.ok ? "1" : "0",
      ].map((s) => '"$s"').join(',');
    }).join('\n');

    final csv = "$header\n$rows";
    // Di real app, simpan/share CSV. Untuk demo, tampilkan dialog.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV Preview'),
        content: SingleChildScrollView(child: SelectableText(csv)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  String _dateLine(DateTime dt) => DateFormat("MMM d, y").format(dt); // Aug 15, 2025
  String _timeLine(DateTime dt) => DateFormat("hh:mm a").format(dt); // 06:05 PM

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F6FA);
    const dark = Color(0xFF2C2F39);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Top search + filter icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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

            // Dark header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Activity History",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Track and monitor all activities in the\nsystem",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: dark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  onPressed: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text("Filters & Search", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _autoRefresh ? Colors.green : Colors.black26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _toggleAutoRefresh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.autorenew,
                          size: 18, color: _autoRefresh ? Colors.green : const Color(0xFF333333)),
                      const SizedBox(width: 6),
                      Text("Auto Refresh",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _autoRefresh ? Colors.green : const Color(0xFF333333),
                          )),
                    ]),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _exportCsv,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Header row (labels)
            _HeaderRow(),

            // Data rows
            ..._filtered.map((a) => _ActivityRow(
              activity: a,
              dateLine: _dateLine(a.at),
              timeLine: _timeLine(a.at),
            )),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      color: Color(0xFF8B8E99),
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: const [
          Expanded(flex: 28, child: Text("Activity", style: label)),
          Expanded(flex: 32, child: Text("Description", style: label)),
          Expanded(flex: 22, child: Text("User", style: label)),
          Expanded(flex: 28, child: Text("Date & Time", style: label)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Activity activity;
  final String dateLine;
  final String timeLine;

  const _ActivityRow({
    required this.activity,
    required this.dateLine,
    required this.timeLine,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Container(height: 1, color: const Color(0xFFE7E8EE), margin: const EdgeInsets.symmetric(vertical: 10));

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity col
            Expanded(
              flex: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.login, size: 22, color: Color(0xFF2C2F39)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.activity,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                      const SizedBox(height: 2),
                      Text(activity.module,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
                    ],
                  ),
                ],
              ),
            ),

            // Description col
            Expanded(
              flex: 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  activity.description,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2A2A2A)),
                ),
              ),
            ),

            // User col
            Expanded(
              flex: 22,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: activity.ok ? const Color(0xFF38D430) : const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                        const SizedBox(height: 2),
                        Text(activity.role,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Date & Time col
            Expanded(
              flex: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLine,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                  const SizedBox(height: 2),
                  Text(timeLine, style: const TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
                ],
              ),
            ),
          ],
        ),
        divider,
      ],
    );
  }
}
