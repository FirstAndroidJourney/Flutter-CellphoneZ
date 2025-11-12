import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/app_animated_switcher.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/screens/category/views/categories_list_screen.dart';
import 'package:shop/screens/checkout/views/cart_screen.dart';
import 'package:shop/screens/home/views/home_screen.dart';
import 'package:shop/screens/profile/views/profile_screen.dart';
import 'package:shop/screens/store_locator/views/store_locator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesListScreen(),
    const StoreLocatorScreen(
      enableSelection: false,
      title: 'Cửa hàng CellphoneZ',
    ),
    const CartScreen(),
    const ProfileScreen(),
  ];

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    int badgeCount = 0,
  }) {
    final Color iconColor = isActive ? Colors.white : Colors.black87;

    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cellphoneZRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 6,
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
    return Scaffold(
      extendBody: true,
      body: AppAnimatedSwitcher(
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final navItems = [
            _buildNavItem(
              icon: Icons.home,
              label: 'Trang chủ',
              isActive: _selectedIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.category,
              label: 'Danh mục',
              isActive: _selectedIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.storefront,
              label: 'Cửa hàng',
              isActive: _selectedIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.shopping_cart,
              label: 'Giỏ hàng',
              isActive: _selectedIndex == 3,
              badgeCount: cartProvider.totalItems,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Tài khoản',
              isActive: _selectedIndex == 4,
            ),
          ];

          return CurvedNavigationBar(
            index: _selectedIndex,
            items: navItems,
            color: ivoryWhiteColor,
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
          );
        },
      ),
    );
  }
}
