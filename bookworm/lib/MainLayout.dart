import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bookworm/pages/Dashboard.dart';
import 'package:bookworm/pages/librarian/BookManagement.dart';
import 'package:bookworm/pages/librarian/RoomManagement.dart';
import 'package:bookworm/pages/librarian/UserManagement.dart';
import 'package:bookworm/pages/usermanagement/Login.dart';
import 'package:bookworm/pages/customer/BookSheft.dart';  // Trang tìm sách cho user
import 'package:bookworm/widgets/TopBar.dart';
import 'model/SidebarManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/SidebarManager.dart';

class NavItem {
  final String title;
  final IconData icon;
  final Widget page;

  NavItem({required this.title, required this.icon, required this.page});
}

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? _userName;
  String? _userRole;
  int _selectedIndex = 0;
  final SidebarManager _sidebar = SidebarManager();

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Guest';
      _userRole = prefs.getString('userRole') ?? 'customer';
    });
  }

  List<NavItem> get _navItems {
    switch (_userRole) {
      case 'admin':
        return [
          NavItem(title: 'Dashboard', icon: Icons.dashboard, page: const DashboardPage()),
          NavItem(title: 'Books', icon: Icons.menu_book, page: const BookManagementPage()),
          NavItem(title: 'Users', icon: Icons.people, page: const UserManagementPage()),
          NavItem(title: 'Rooms', icon: Icons.store, page: const RoomManagementPage()),
        ];
      case 'librarian':
        return [
          NavItem(title: 'Dashboard', icon: Icons.dashboard, page: const DashboardPage()),
          NavItem(title: 'Users', icon: Icons.people, page: const UserManagementPage()),
          NavItem(title: 'Books', icon: Icons.menu_book, page: const BookManagementPage()),
          NavItem(title: 'Rooms', icon: Icons.store, page: const RoomManagementPage()),
        ];
      case 'customer':
        return [
          NavItem(title: 'Find Books', icon: Icons.search, page: const BookShelfPage()),
        ];
      default:
        return [
          NavItem(title: 'Find Books', icon: Icons.search, page: const BookShelfPage()),
        ];
    }
  }

  Widget _body() => _navItems[_selectedIndex].page;

  void _onItemTap(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop(); // đóng drawer
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF594A47),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset('assets/logo_dark.png', width: 150, height: 150),
            ),
            const SizedBox(height: 8),
            // Nav items
            ..._navItems.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return ListTile(
                leading: Icon(item.icon, color: Colors.white),
                title: Text(item.title, style: const TextStyle(color: Colors.white)),
                selected: idx == _selectedIndex,
                selectedTileColor: Colors.white24,
                onTap: () => _onItemTap(idx),
              );
            }),
            const Spacer(),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Log Out', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    final time = DateFormat('hh:mm a').format(DateTime.now());
    final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
    return _userName == null
        ? const SizedBox()
        : Row(
      children: [
        AutoSizeText('BookWorm',
            maxLines: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(_userName!,
                maxLines: 1,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            AutoSizeText(_userRole!,
                maxLines: 1,
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(time,
                maxLines: 1,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            AutoSizeText(date,
                maxLines: 1,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu prefs chưa load xong, hiển thị loading
    if (_userName == null || _userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF594A47),
        title: _buildAppBarTitle(),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: _body(),
    );
  }
}
