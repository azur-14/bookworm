import 'package:flutter/material.dart';
import '../widgets/SidebarItem.dart';

class SidebarItemData {
  final IconData icon;
  final String title;

  SidebarItemData({required this.icon, required this.title});
}

class SidebarManager {
  // A list of sidebar menu items
  final List<SidebarItemData> items = [
    SidebarItemData(icon: Icons.dashboard, title: 'Dashboard'),
    SidebarItemData(icon: Icons.menu_book, title: 'Books'),
    SidebarItemData(icon: Icons.people, title: 'Users'),
    SidebarItemData(icon: Icons.store, title: 'Rooms'),
  ];

  /// Builds a list of sidebar item widgets based on the current selected index.
  List<Widget> buildSidebarItems({
    required int selectedIndex,
    required Function(int) onItemTap,
  }) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return SidebarItem(
        icon: item.icon,
        title: item.title,
        isSelected: index == selectedIndex,
        onTap: () => onItemTap(index),
      );
    }).toList();
  }
}
