import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/pages/customer/BorrowHistoryPage.dart';
import 'package:bookworm/pages/customer/RoomBookingHistoryPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:bookworm/pages/Dashboard.dart';
import 'package:bookworm/pages/librarian/book_management/BookManagement.dart';
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
  String? _avatarBase64;
  final SidebarManager _sidebar = SidebarManager();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

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
            title: 'Book Borrowing History',
            icon: Icons.history,
            page: BorrowHistoryPage(userId: _userId!), // ✅ truyền đúng userId
          ),
          NavItem(
            title: 'Room Booking History',
            icon: Icons.history,
            page: RoomBookingHistoryPage(userId: _userId!),
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
  void showEditProfileDialog(BuildContext context) async {
    if (_userId == null) return;

    try {
      final user = await fetchUserById(_userId!);
      _nameCtl.text = user['name'] ?? '';
      _emailCtl.text = user['email'] ?? '';
      _phoneCtl.text = user['phone'] ?? '';
      _avatarBase64 = user['avatar'];

      showDialog(
        context: context,
        builder: (_) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Container(
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

                        // Avatar selector (StatefulBuilder-aware)
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setStateDialog(() {
                                _avatarBase64 = base64Encode(bytes);
                              });
                            }
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.brown.shade300,
                              image: _avatarBase64 != null
                                  ? DecorationImage(
                                image: MemoryImage(base64Decode(_avatarBase64!)),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: _avatarBase64 == null
                                ? const Icon(Icons.person, size: 48, color: Colors.white)
                                : null,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildTextField("Name", _nameCtl),
                        _buildTextField("Email", _emailCtl),
                        _buildTextField("Phone", _phoneCtl),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildButton("CANCEL", Colors.grey.shade300, Colors.black, () {
                              Navigator.of(context).pop();
                            }),
                            _buildButton("CONFIRM", Colors.black, Colors.white, () async {
                              try {
                                await updateUserInfo(_userId!, {
                                  'name': _nameCtl.text,
                                  'phone': _phoneCtl.text,
                                  'avatar': _avatarBase64,
                                });

                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('userName', _nameCtl.text);
                                await prefs.setString('userRole', _userRole ?? 'customer');

                                setState(() {
                                  _userName = _nameCtl.text;
                                });

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Profile updated")),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Update failed: $e")),
                                );
                              }
                            }),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    bool isEmail = label.toLowerCase() == "email";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        readOnly: isEmail,
        controller: controller,
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

  Future<Map<String, dynamic>> fetchUserById(String userId) async {
    final res = await http.get(Uri.parse('http://localhost:3000/api/users/$userId'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch user');
  }

  Future<void> updateUserInfo(String userId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('http://localhost:3000/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (res.statusCode != 200) throw Exception('Update failed');
  }
}
