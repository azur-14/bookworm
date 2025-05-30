import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../model/User.dart';
import '../../../theme/AppColor.dart';
import '../../librarian/user_management/SearchBar.dart';
import '../../librarian/user_management/UserAddUpdateDialog.dart';
import '../../librarian/user_management/UserDeleteDialog.dart';
import '../../librarian/user_management/UserTable.dart';
import '../../librarian/user_management/UserViewDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibrarianManagementPage extends StatefulWidget {
  const LibrarianManagementPage({Key? key}) : super(key: key);
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<LibrarianManagementPage>
    with SingleTickerProviderStateMixin {
  // --- dữ liệu & trạng thái ---
  late final Ticker _ticker;
  late DateTime _currentTime;
  final TextEditingController _searchCtl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _adminId = 'unknown_admin';
  final List<User> _users = [];

  // filter & sort
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _sortField   = 'Name';
  bool   _sortAsc     = true;
  final List<String> _status = ['All','Active','Inactive'];
  final List<String> _sortBy = ['Name','Email'];

  // pagination
  int _currentPage = 1;
  static const int _rowsPerPage = 20;
  int get _totalPages => (_processedUsers.length / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();
  List<User> get _paginatedUsers {
    final start = (_currentPage - 1) * _rowsPerPage;
    return _processedUsers.skip(start).take(_rowsPerPage).toList();
  }

  @override
  void initState() {
    super.initState();
    _initAdmin();
    _startClock();
    _loadUsers();
    _searchCtl.addListener(_onSearchChanged);
  }

  void _initAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminId = prefs.getString('userId') ?? 'unknown_admin';
    });
  }

  void _startClock() {
    _currentTime = DateTime.now();
    _ticker = createTicker((_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _searchCtl.removeListener(_onSearchChanged);
    _searchCtl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchCtl.text.trim();
        _currentPage = 1; // reset trang khi search thay đổi
      });
    });
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/users?role=librarian'),
        headers: {
          'Content-Type':'application/json',
          if (token!=null) 'Authorization':'Bearer $token',
        },
      );
      if (res.statusCode != 200) throw Exception(res.body);
      final data = json.decode(res.body) as List;
      setState(() {
        _users
          ..clear()
          ..addAll(data.map((j) => User.fromJson(j)));
        _currentPage = 1;
      });
    } catch (e) {
      setState(() { _errorMessage = 'Không tải được danh sách thủ thư'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Kết hợp Search + Filter + Sort
  List<User> get _processedUsers {
    var list = _users.where((u) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
      final matchRole   = _roleFilter=='All' || u.role==_roleFilter;
      final matchStatus = _statusFilter=='All' || u.status==_statusFilter;
      return matchSearch && matchRole && matchStatus;
    }).toList();
    list.sort((a,b){
      final cmp = _sortField=='Name'
          ? a.name.compareTo(b.name)
          : a.email.compareTo(b.email);
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _confirmDelete(User u) => showDialog(
    context: context,
    builder: (_) => UserDeleteDialog(
      user: u,
      onConfirmDelete: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          final res = await http.delete(
            Uri.parse('http://localhost:3000/api/users/${u.id}'),
            headers: {
              'Content-Type':'application/json',
              if (token!=null) 'Authorization':'Bearer $token',
            },
          );
          if (res.statusCode!=200) throw Exception(res.body);
          setState(() {
            _users.removeWhere((e)=>e.id==u.id);
            if (_currentPage>_totalPages) _currentPage=_totalPages;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thủ thư')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e')),
          );
        }
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background, // be nhạt
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildHeader(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Search + Filter/Sort ---
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: UserSearchBar(
                              controller: _searchCtl,
                              onChanged: (v) => setState((){
                                _searchQuery = v;
                                _currentPage = 1;
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildDropdown('Status', _statusFilter, _status, (v) => setState(() {
                                _statusFilter = v!; _currentPage = 1;
                              })),
                              const Spacer(),
                              _buildDropdown('Sort by', _sortField, _sortBy, (v) => setState(() {
                                _sortField = v!; _currentPage = 1;
                              })),
                              IconButton(
                                icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                                onPressed: () => setState(() => _sortAsc = !_sortAsc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Table ---
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        child: ConstrainedBox(
                          // Bắt buộc table rộng ít nhất đúng kích thước màn hình (trừ padding)
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 32,
                          ),
                          // Nếu table còn rộng hơn, nó vẫn sẽ scroll bình thường
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(child: Text(_errorMessage!))
                              : UserTable(
                            users: _paginatedUsers,
                            onView: (u) => showDialog(
                              context: context,
                              builder: (_) => UserViewDialog(user: u),
                            ),
                            onEdit: (u) => showDialog(
                              context: context,
                              builder: (_) => UserAddUpdateDialog(
                                user: u,
                                onSubmit: (newU) {
                                  setState(() => _users[_users.indexWhere((e)=>e.id==newU.id)] = newU);
                                },
                              ),
                            ),
                            onDelete: _confirmDelete,
                          ),
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(height: 12),

                  // --- Pagination Controls ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text('Page $_currentPage/$_totalPages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Footer cố định ---
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                DateFormat('MMM dd, yyyy – hh:mm a').format(_currentTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => UserAddUpdateDialog(onSubmit: (u){
              setState(() => _users.add(u));
            }),
          ),
          tooltip: 'Tạo thủ thư',
          child: const Icon(Icons.person_add_alt_1),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('Librarian Management',
            style: Theme.of(ctx).textTheme.titleLarge!
                .copyWith(color: AppColors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.white,
            onPressed: _loadUsers,
            tooltip: 'Tải lại',
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return Row(
      children: [
        Text('$label:'),
        const SizedBox(width: 6),
        DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
