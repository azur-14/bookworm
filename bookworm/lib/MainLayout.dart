import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/UserManagement.dart';
import 'package:bookworm/BookManagement.dart';
import 'package:bookworm/RoomManagement.dart';
import 'package:bookworm/Dashboard.dart';
import 'package:bookworm/Login.dart';
import 'package:bookworm/widgets/TopBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/SidebarManager.dart';
import 'package:flutter/material.dart';

class NavItem {
  final String title;
  final IconData icon;
  final Widget page;

  NavItem({required this.title, required this.icon, required this.page});
}

class MainLayout extends StatefulWidget {
  final String userName;
  final String userRole;
  const MainLayout({Key? key, required this.userName, required this.userRole})
      : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Navigation items for the Drawer.
  final List<NavItem> navItems = [
    NavItem(title: 'Dashboard', icon: Icons.dashboard, page: const DashboardPage()),
    NavItem(title: 'Books', icon: Icons.menu_book, page: const BookManagementPage()),
    NavItem(title: 'Users', icon: Icons.people, page: const UserManagementPage()),
    NavItem(title: 'Rooms', icon: Icons.store, page: const RoomManagementPage()),
  ];

  // Track which nav item is selected.
  int _selectedIndex = 0;
  final SidebarManager _sidebar = SidebarManager();

  /// Returns the body corresponding to the selected navigation item.
  Widget _body() {
    return navItems[_selectedIndex].page;
  }

  /// Called when a drawer item is tapped.
  void _onItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // close the drawer.
  }

  /// Builds the Drawer using the existing SidebarManager.
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF594A47), // Keep the original sidebar color.
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer header with logo.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/logo_dark.png', // Adjust asset path as needed.
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 8),
            // Sidebar items: using the original SidebarManager.
            ..._sidebar.buildSidebarItems(
              selectedIndex: _selectedIndex,
              onItemTap: _onItemTap,
            ),
            const Spacer(),
            // Logout.
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

  /// Builds the AppBar title with increased prominence for white text.
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
            color: Colors.white, // White text for prominence.
          ),
        ),
        const Spacer(),
        // User information.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(
              widget.userName,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            AutoSizeText(
              widget.userRole,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF594A47),
        title: _buildAppBarTitle(),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              // Set icon color to white
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: _body(),
    );
  }
}
