import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/model/user_management.dart';
import 'package:flutter_management_inventory/view/user_management/user_detail_page.dart';

import '../../config/endpoint.dart';
import '../../config/model/resp.dart';
import '../../config/network.dart';
import '../../config/pref.dart';
import '../../widget/user_tile.dart';


class _Debouncer {
  _Debouncer(this.millis);
  final int millis;
  Timer? _t;

  void run(VoidCallback f) {
    _t?.cancel();
    _t = Timer(Duration(milliseconds: millis), f);
  }

  void dispose() => _t?.cancel();
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _debounce = _Debouncer(400);

  // data
  final _users = <UserManagementUser>[];

  // status
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;

  // pagination
  int _page = 1;
  int _perPage = 15;
  int _lastPage = 1;
  String _serverQuery = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirstPage(); // initial load
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    _debounce.dispose();
    super.dispose();
  }

  // -------- Fetchers ----------
  Future<void> _loadFirstPage({String query = ''}) async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _page = 1;
      _serverQuery = query;
    });

    try {
      final data = await _fetchUsers(page: 1, perPage: _perPage, search: query);
      setState(() {
        _users
          ..clear()
          ..addAll(data.items);
        _lastPage = data.lastPage;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading) return;
    if (_page >= _lastPage) return;

    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final data = await _fetchUsers(page: next, perPage: _perPage, search: _serverQuery);
      setState(() {
        _page = next;
        _users.addAll(data.items);
      });
    } catch (e) {
      // bisa tampilkan snackbar kalau mau
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await _loadFirstPage(query: _serverQuery);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent * 0.92) {
      _loadMore();
    }
  }

  // -------- Search ----------
  void _onSearchChanged(String text) {
    _debounce.run(() {
      _loadFirstPage(query: text.trim());
    });
  }

  // -------- Networking ----------
  Future<_UsersResponse> _fetchUsers({
    required int page,
    required int perPage,
    String? search,
  }) async {
    final token = await Session().getUserToken();
    final header = {'Authorization': 'Bearer $token'};

    final base = Uri.parse(Endpoint.usersByAdmin);
    final qp = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final url = base.replace(queryParameters: {...base.queryParameters, ...qp}).toString();

    final raw = await Network.getApiWithHeaders(url, header);
    final resp = Resp.fromJson(raw);

    if (resp.code == 200) {
      final data = (resp.data ?? {}) as Map;
      final items = (data['items'] as List? ?? const []);
      final pag = (data['pagination'] as Map? ?? const {});
      final lastPage = (pag['last_page'] as num?)?.toInt() ?? 1;

      final users = items.map<UserManagementUser>((it) {
        final map = it as Map;
        final name = (map['name'] ?? '').toString();
        final email = (map['email'] ?? '').toString();
        final rolesRaw = (map['roles'] ?? '').toString(); // admin/owner/staff
        final active = map['deleted_at'] == null;
        DateTime p(dynamic v) =>
            (v is String && v.isNotEmpty) ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();
        final joined = p(map['created_at']);
        final updated = p(map['updated_at']);

        String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
        return UserManagementUser(
          name: name,
          email: email,
          roles: _cap(rolesRaw),
          active: active,
          createdAt: joined,
          updatedAt: updated,
        );
      }).toList();

      return _UsersResponse(items: users, lastPage: lastPage);
    } else if (resp.code == 401) {
      throw Exception('Unauthorized. Silakan login ulang.');
    } else {
      throw Exception(resp.message ?? 'Gagal memuat data pengguna.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkChip = const Color(0xFF2C2F39);
    final bg = const Color(0xFFF5F6FA);

    Widget _body() {
      if (_initialLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _loadFirstPage(query: _serverQuery),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: _users.length + 3 + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 0: search bar, 1: button tambah, 2: spacer
            if (index == 0) {
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
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
              );
            }
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkChip,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // TODO: buka form create user
                  },
                  child: const Text("Tambahkan User", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              );
            }
            if (index == 2) {
              return const SizedBox(height: 12);
            }

            final i = index - 3;
            if (i >= 0 && i < _users.length) {
              final u = _users[i];
              return UserTile(
                user: u,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserDetailPage(user: u)),
                  );
                },
              );
            }

            // loader bawah (pagination)
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leadingWidth: 74,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Color(0xFFD9D9D9),
            child: Icon(Icons.person, color: Colors.black87),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Management",
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF222222))),
            SizedBox(height: 2),
            Text("Kelola pengguna sistem", style: TextStyle(fontSize: 12, color: Color(0xFF8B8E99))),
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
      body: _body(),
    );
  }
}


class _UsersResponse {
  final List<UserManagementUser> items;
  final int lastPage;
  _UsersResponse({required this.items, required this.lastPage});
}