import 'package:flutter/material.dart';
import 'model/SidebarManager.dart';
import 'BookManagement.dart';
import 'RoomManagement.dart';
import 'widgets/TopBar.dart';
import 'package:intl/intl.dart';

class MainLayout extends StatefulWidget {
  final String userName;
  final String userRole;
  const MainLayout({Key? key, required this.userName, required this.userRole}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selected = 'Rooms';
  final SidebarManager _sidebar = SidebarManager();

  Widget _body() {
    switch (_selected) {
      case 'Books':
        return const BookManagementPage();
      case 'Rooms':
      default:
        return const RoomManagementPage();
    }
  }

  void _onTap(int idx) {
    setState(() {
      if (idx == 2) _selected = 'Books';
      else if (idx == 4) _selected = 'Rooms';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // Sidebar
        Container(
          width: 250,
          color: const Color(0xFF594A47),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Logo + Title ---
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo_dark.png',  // your logo file
                      width: 150,
                      height: 150,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Menu Items ---
              ..._sidebar.buildSidebarItems(
                selectedIndex: _selected == 'Books' ? 2 : 4,
                onItemTap: _onTap,
              ),

              const Spacer(),

              // --- Logout ---
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                onTap: () {/* logout */},
              ),
            ],
          ),
        ),

        // Main area
        Expanded(
          child: Column(
            children: [
              TopBar(
                userName: widget.userName,
                userRole: widget.userRole,
                formattedTime: DateFormat('hh:mm a').format(DateTime.now()),
                formattedDate: DateFormat('MMM dd, yyyy').format(DateTime.now()),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ]),
    );
  }
}
