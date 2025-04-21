import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/pages/customer/BorrowHistoryPage.dart';
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

  String? _userId;

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Guest';
      _userRole = prefs.getString('userRole') ?? 'customer';
      _userId = prefs.getString('userId'); // ✅ thêm dòng này
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
          NavItem(
            title: 'Book Borrowed History',
            icon: Icons.history,
            page: BorrowHistoryPage(userId: _userId!), // ✅ truyền đúng userId
          ),

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
    final String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
    final String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

    return Row(
      children: [
        // Branding text on the left.
        AutoSizeText(
          'BookWorm Dashboard',
          maxLines: 1,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        // User information.
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
        // Date/Time.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(
              formattedTime,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            AutoSizeText(
              formattedDate,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // 🔧 Setting Icon
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            showEditProfileDialog(context); // Mở popup thay vì chuyển trang
          },
        ),
      ],
    );
  }
  void showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.settings, size: 24),
                      const SizedBox(width: 8),
                      const Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Avatar placeholder
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.brown.shade300,
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Input fields
                  _buildTextField("Username"),
                  _buildTextField("Email"),
                  _buildTextField("Name"),
                  _buildTextField("Phone Number"),
                  _buildTextField("Role"),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton("CANCEL", Colors.grey.shade300, Colors.black, () {
                        Navigator.of(context).pop();
                      }),
                      _buildButton("CONFIRM", Colors.black, Colors.white, () {
                        // TODO: Confirm logic here
                        Navigator.of(context).pop();
                      }),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.brown.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color bgColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
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
