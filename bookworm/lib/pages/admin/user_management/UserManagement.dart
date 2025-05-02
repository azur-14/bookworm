// /pages/user_management/user_management_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../model/User.dart';
import 'UserTable.dart';
import 'UserAddUpdateDialog.dart';
import 'UserViewDialog.dart';
import 'UserDeleteDialog.dart';
import 'SearchBar.dart';
// /pages/user_management/user_management_page.dart

class LibrarianManagementPage extends StatefulWidget {
  const LibrarianManagementPage({Key? key}) : super(key: key);

  @override
  _LibrarianManagementPageState createState() => _LibrarianManagementPageState();
}

class _LibrarianManagementPageState extends State<LibrarianManagementPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late DateTime _currentTime;
  final List<User> _users = [];
  final TextEditingController _searchCtl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _ticker = createTicker((_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _ticker.start();
    _loadUsers();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/users'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final usersFromServer = await fetchUsers();
      setState(() {
        _users
          ..clear()
          ..addAll(usersFromServer);
      });
    } catch (e) {
      debugPrint('Lỗi tải danh sách user: $e');
    }
  }

  void _addUser(User newUser) {
    setState(() {
      _users.add(newUser);
    });
  }

  void _updateUser(User updatedUser) {
    setState(() {
      final index = _users.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
    });
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => UserDeleteDialog(
        user: user,
        onConfirmDelete: () {
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
          });
        },
      ),
    );
  }

  void _openAddUserDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (ctx) => UserAddUpdateDialog(
          onSubmit: _addUser,
        ),
      );
    });
  }

  void _openUpdateUserDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => UserAddUpdateDialog(
        user: user,
        onSubmit: _updateUser,
      ),
    );
  }

  void _openViewUserDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => UserViewDialog(user: user),
    );
  }

  List<User> _filterUsers() {
    if (_searchQuery.trim().isEmpty) {
      return _users;
    }
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFFFF3EB),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Librarian Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openAddUserDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Librarian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: const Color(0xFFFFF3EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    UserSearchBar(
                      controller: _searchCtl,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: UserTable(
                        users: _filterUsers(),
                        onView: _openViewUserDialog,
                        onEdit: _openUpdateUserDialog,
                        onDelete: _deleteUser,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Text('$formattedDate, $formattedTime')],
          ),
        ),
      ],
    );
  }
}
