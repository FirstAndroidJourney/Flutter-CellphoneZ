import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/screens/category/views/categories_list_screen.dart';
import 'package:shop/screens/checkout/views/cart_screen.dart';
import 'package:shop/screens/home/views/home_screen.dart';
import 'package:shop/screens/profile/views/profile_screen.dart';

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
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: cellphoneZRed,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: 'Danh mục',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartProvider.totalItems > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cellphoneZRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartProvider.totalItems}',
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
                label: 'Giỏ hàng',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Tài khoản',
              ),
            ],
          );
        },
      ),
    );
  }
}
