import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme/AppColor.dart';
import 'model/SidebarManager.dart';
import 'widgets/SidebarItem.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  final SidebarManager sidebarManager = SidebarManager();

  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the time and date using Intl
    String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar area
          Container(
            width: 250,
            color: AppColors.sidebarBackground,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar header/logo (enlarged logo)
                Container(
                  height: 120, // Increase the container height if needed
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/logo_dark.png', // Adjust asset path if necessary
                    width: 150, // Increased logo size (from 100 to 150)
                  ),
                ),
                const SizedBox(height: 20),
                // Sidebar menu items
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: sidebarManager.items.length,
                    itemBuilder: (context, index) {
                      return SidebarItem(
                        icon: sidebarManager.items[index].icon,
                        title: sidebarManager.items[index].title,
                        isSelected: index == selectedIndex,
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Log Out item
                SidebarItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  isSelected: false,
                  onTap: () {
                    // Implement log out logic here
                  },
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar
                  Container(
                    color: Colors.white,
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Greeting and user icon
                        Row(
                          children: const [
                            Icon(Icons.person, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Hi, Admin', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        // Real-time Time and Date display
                        Row(
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Content area that displays the selected item
                  Expanded(
                    child: Center(
                      child: Text(
                        'Selected: ${sidebarManager.items[selectedIndex].title}',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
