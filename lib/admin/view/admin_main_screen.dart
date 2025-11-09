import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'package:shop/admin/category/view/category_management.dart';
import 'package:shop/admin/products/view/product_list_screen.dart';
import 'package:shop/constants.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _selectedIndex;
  late final List<Widget> _screens;
  static const _navItems = [
    _AdminNavItem(
      icon: Icons.inventory_2_outlined,
      label: 'Sản phẩm',
    ),
    _AdminNavItem(
      icon: Icons.category_outlined,
      label: 'Danh mục',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = const [
      ProductListScreen(),
      CategoryManagement(),
    ];
    _selectedIndex = _normalizeIndex(widget.initialIndex);
  }

  int _normalizeIndex(int index) {
    if (index < 0) return 0;
    if (index >= _screens.length) return _screens.length - 1;
    return index;
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final Color iconColor = isActive ? Colors.white : Colors.black87;

    return SizedBox(
      height: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(
      _navItems.length,
      (index) {
        final navItem = _navItems[index];
        return _buildNavItem(
          icon: navItem.icon,
          label: navItem.label,
          isActive: _selectedIndex == index,
        );
      },
    );

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        items: items,
        color: Colors.white,
        buttonBackgroundColor: cellphoneZRed,
        backgroundColor: Colors.transparent,
        height: 58,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
