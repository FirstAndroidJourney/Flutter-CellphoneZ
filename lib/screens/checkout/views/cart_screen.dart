import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';
import '../../../models/cart_item.dart';
import '../../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartItem> _cartItems = [];
  final CartService _cartService = CartService();
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final items = await _cartService.getCurrentUserCartItems();
      setState(() {
        _cartItems.clear();
        if (items.isEmpty) {
          // Nếu giỏ hàng thật sự rỗng, thêm 1-2 món demo để demo giao diện
          _cartItems.addAll([
            CartItem(
              id: 'demo-1',
              userId: 'demo',
              productId: 'p-001',
              quantity: 1,
              unitPrice: 499000.0,
              productName: 'Tai nghe không dây',
              productImage: null,
              isSelected: true,
            ),
            CartItem(
              id: 'demo-2',
              userId: 'demo',
              productId: 'p-002',
              quantity: 2,
              unitPrice: 1290000.0,
              productName: 'Ốp lưng điện thoại',
              productImage: null,
              isSelected: true,
            ),
          ]);
        } else {
          _cartItems.addAll(items);
        }
        _calculateTotal();
      });
    } catch (_) {
      // If fetching fails (e.g., not authenticated) or cart is empty,
      // insert 1-2 demo items for a demo flow (Vietnamese, VND)
      setState(() {
        _cartItems.clear();
        _cartItems.addAll([
          CartItem(
            id: 'demo-1',
            userId: 'demo',
            productId: 'p-001',
            quantity: 1,
            unitPrice: 499000.0,
            productName: 'Tai nghe không dây',
            productImage: null,
            isSelected: true,
          ),
          CartItem(
            id: 'demo-2',
            userId: 'demo',
            productId: 'p-002',
            quantity: 2,
            unitPrice: 1290000.0,
            productName: 'Ốp lưng điện thoại',
            productImage: null,
            isSelected: true,
          ),
        ]);
        _calculateTotal();
      });
    }
  }

  void _toggleItemSelection(int index) {
    setState(() {
      _cartItems[index] = _cartItems[index].copyWith(
        isSelected: !_cartItems[index].isSelected,
      );
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalPrice = _cartItems
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String _formatVnd(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price.round())}đ';
  }

  void _proceedToCheckout() {
    final selectedItems = _cartItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm để thanh toán'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItems: selectedItems),
      ),
    ).then((_) {
      _loadCartItems(); // Refresh cart when returning from checkout
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Text('Giỏ hàng trống'),
            )
          : ListView.separated(
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.isSelected,
                    onChanged: (_) => _toggleItemSelection(index),
                  ),
                  title: Text(item.productName),
                  subtitle: Text('Số lượng: ${item.quantity}'),
                  trailing: Text(
                    _formatVnd(item.totalPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatVnd(_totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Tiếp tục thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
