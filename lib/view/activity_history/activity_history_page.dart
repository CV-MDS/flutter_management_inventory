// lib/view/activity_history/activity_history_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_management_inventory/model/activity_admin.dart';
import 'package:flutter_management_inventory/viewmodel/activity_viewmodel.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  // UI controllers & timers
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  Timer? _autoTimer;
  bool _autoRefresh = false;

  // Data
  bool _loading = true;
  String? _error;

  List<ActivityAdmin> _items = [];
  List<ActivityAdmin> _filtered = []; // jika mau filter di client untuk quick search
  List<String> _filterActions = [];   // dari server (filters.actions)
  String? _selectedAction;            // filter action active

  // Pagination
  int _page = 1;
  int _perPage = 15;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _fetch(resetToFirstPage: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _autoTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ====== API FETCH ======
  Future<void> _fetch({bool resetToFirstPage = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      if (resetToFirstPage) _page = 1;
    });

    try {
      // >>>> SESUAIKAN DENGAN VIEWMODEL MU <<<<
      // Disarankan getActivities menerima optional params.
      final resp = await ActivityViewmodel().getActivities(
        page: _page,
        perPage: _perPage,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        action: _selectedAction,
      );

      if (!mounted) return;
      if (resp.code == 200) {
        final data = resp.data ?? {};
        final list = (data['items'] as List? ?? [])
            .map((e) => ActivityAdmin.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final filters = data['filters'] as Map<String, dynamic>? ?? {};
        final actions = (filters['actions'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        setState(() {
          _items = list;
          _filtered = List.of(_items);
          _page = (pagination['current_page'] as num?)?.toInt() ?? 1;
          _perPage = (pagination['per_page'] as num?)?.toInt() ?? _perPage;
          _total = (pagination['total'] as num?)?.toInt() ?? _items.length;
          _lastPage = (pagination['last_page'] as num?)?.toInt() ?? 1;
          _filterActions = actions;
          _loading = false;
        });
      } else {
        setState(() {
          _error = resp.message ?? 'Failed to fetch activities';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ====== SEARCH / FILTER ======
  void _onSearchChanged(String v) {
    // server-side filter via _fetch (rekomendasi)
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetch(resetToFirstPage: true);
    });

    // optional: client-side filter cepat (tanpa request)
    setState(() {
      final q = v.trim().toLowerCase();
      if (q.isEmpty) {
        _filtered = List.of(_items);
        return;
      }
      _filtered = _items.where((a) {
        final action = (a.action ?? '').toLowerCase();
        final desc = (a.description ?? '').toLowerCase();
        final user = (a.user?.name ?? '').toLowerCase();
        final role = (a.user?.roles ?? '').toLowerCase();
        final ip = (a.ipAddress ?? '').toLowerCase();
        return action.contains(q) ||
            desc.contains(q) ||
            user.contains(q) ||
            role.contains(q) ||
            ip.contains(q);
      }).toList();
    });
  }

  void _onChangeAction(String? action) {
    setState(() => _selectedAction = action?.isEmpty == true ? null : action);
    _fetch(resetToFirstPage: true);
  }

  // ====== AUTO REFRESH ======
  void _toggleAutoRefresh() {
    setState(() => _autoRefresh = !_autoRefresh);
    _autoTimer?.cancel();
    if (_autoRefresh) {
      _autoTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetch());
    }
  }

  // ====== EXPORT CSV ======
  void _exportCsv() {
    final header = "Activity,Description,User,Role,IP,Date,Time";
    final rows = _filtered.map((a) {
      final created = a.createdAt ?? DateTime.now();
      final d = DateFormat("MMM d, y").format(created);
      final t = DateFormat("hh:mm a").format(created);
      return [
        (a.action ?? ''),
        (a.description ?? ''),
        (a.user?.name ?? ''),
        (a.user?.roles ?? ''),
        (a.ipAddress ?? ''),
        d,
        t,
      ].map((s) => '"${s.replaceAll('"', '""')}"').join(',');
    }).join('\n');

    final csv = "$header\n$rows";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV Preview'),
        content: SingleChildScrollView(child: SelectableText(csv)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ====== HELPERS ======
  String _dateLine(DateTime? dt) =>
      dt == null ? '-' : DateFormat("MMM d, y").format(dt);
  String _timeLine(DateTime? dt) =>
      dt == null ? '-' : DateFormat("hh:mm a").format(dt);

  Color _statusColor(String? action) {
    switch ((action ?? '').toLowerCase()) {
      case 'login':
        return const Color(0xFF29CC63); // green
      case 'create':
        return const Color(0xFF2F80ED); // blue
      case 'update':
        return const Color(0xFFF2994A); // orange
      case 'delete':
        return const Color(0xFFFF3B30); // red
      default:
        return const Color(0xFF9AA0A6); // grey
    }
  }

  IconData _actionIcon(String? action) {
    switch ((action ?? '').toLowerCase()) {
      case 'login':
        return Icons.login_rounded;
      case 'create':
        return Icons.add_circle_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F6FA);
    const dark = Color(0xFF2C2F39);

    final body = RefreshIndicator(
      onRefresh: () => _fetch(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Search + Action filter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAction ?? '',
                    items: <String>['', ..._filterActions].map((e) {
                      final label = e.isEmpty ? 'All Actions' : e;
                      return DropdownMenuItem(value: e, child: Text(label));
                    }).toList(),
                    onChanged: _onChangeAction,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dark header
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {}, // optional: buka bottom sheet filter
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text("Filters & Search",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _autoRefresh ? Colors.green : Colors.black26),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _toggleAutoRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.autorenew,
                        size: 18,
                        color: _autoRefresh ? Colors.green : const Color(0xFF333333)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _filtered.isEmpty ? null : _exportCsv,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child:
                  Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Loading / Error / Empty
          if (_loading) ...[
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            )),
          ] else if (_error != null) ...[
            _ErrorState(
              message: _error!,
              onRetry: () => _fetch(),
            ),
          ] else if (_filtered.isEmpty) ...[
            const _EmptyState(),
          ] else ...[
            const _HeaderRow(),
            ..._filtered.map((a) => _ActivityRow(
              icon: _actionIcon(a.action),
              dotColor: _statusColor(a.action),
              action: (a.action ?? '').isEmpty
                  ? '-'
                  : (a.action!.substring(0, 1).toUpperCase() + a.action!.substring(1)),
              module: (a.modelType ?? 'System'),
              description: (a.description ?? '-'),
              user: (a.user?.name ?? '-'),
              role: (a.user?.roles ?? '-'),
              dateLine: _dateLine(a.createdAt),
              timeLine: _timeLine(a.createdAt),
            )),
            const SizedBox(height: 8),

            // Pagination controls
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _page > 1
                      ? () {
                    setState(() => _page -= 1);
                    _fetch();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Prev'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      'Page $_page of $_lastPage • total $_total',
                      style: const TextStyle(
                        color: Color(0xFF8B8E99),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _page < _lastPage
                      ? () {
                    setState(() => _page += 1);
                    _fetch();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Scaffold(backgroundColor: bg, body: SafeArea(child: body));
  }
}

// ====== SMALL WIDGETS ======
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Error: $message',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No activity found',
          style: TextStyle(
            color: Color(0xFF2A2A2A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

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
  final IconData icon;
  final Color dotColor;
  final String action;
  final String module;
  final String description;
  final String user;
  final String role;
  final String dateLine;
  final String timeLine;

  const _ActivityRow({
    required this.icon,
    required this.dotColor,
    required this.action,
    required this.module,
    required this.description,
    required this.user,
    required this.role,
    required this.dateLine,
    required this.timeLine,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      height: 1,
      color: const Color(0xFFE7E8EE),
      margin: const EdgeInsets.symmetric(vertical: 10),
    );

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
                  Icon(icon, size: 22, color: const Color(0xFF2C2F39)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                      const SizedBox(height: 2),
                      Text(module,
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
                  description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF2A2A2A)),
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
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: Color(0xFF2A2A2A))),
                        const SizedBox(height: 2),
                        Text(role,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8B8E99))),
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
                  Text(timeLine,
                      style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
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
