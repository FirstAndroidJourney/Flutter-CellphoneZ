import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/services/auth_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/order_calculation_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AuthService _authService = AuthService();
  // Track selected items
  Set<String> selectedItems = {};

  // Format price to VND
  String formatVND(double price) {
    final priceInt = price.toInt();
    return '${priceInt.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }

  // Calculate total of selected items
  double getSelectedTotal(List items) {
    double total = 0;
    for (var entry in items) {
      if (selectedItems.contains(entry.cartItem.id)) {
        final price = entry.product?.price ?? 0.0;
        final quantity = entry.cartItem.quantity;
        total += price * quantity;
      }
    }
    return total;
  }

  // Show login dialog
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: cellphoneZRed,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Yêu cầu đăng nhập'),
            ],
          ),
          content: const Text(
            'Bạn cần đăng nhập để xem giỏ hàng và thanh toán.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Để sau',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, logInScreenRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cellphoneZRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }

  // Handle checkout button
  void _handleCheckout(CartProvider cartProvider) {
    // Check authentication
    if (!_authService.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm để thanh toán'),
          backgroundColor: cellphoneZRed,
        ),
      );
      return;
    }

    // Get selected cart items
    final selectedCartItems = cartProvider.items
        .where((entry) => selectedItems.contains(entry.cartItem.id))
        .map((entry) => entry.cartItem)
        .toList();

    // Calculate order summary
    final orderSummary = OrderCalculationService().calculateOrder(
      items: selectedCartItems,
      deliveryLocation: '', // Sẽ chọn ở payment screen
    );

    // Navigate to payment screen
    Navigator.pushNamed(
      context,
      paymentScreenRoute,
      arguments: {
        'orderSummary': orderSummary,
        'deliveryAddress': '',
        'items': selectedCartItems,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Check auth when screen loads
    if (!_authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final selectedTotal = getSelectedTotal(cartProvider.items);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: cellphoneZRed,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Giỏ hàng'),
          ),
          body: cartProvider.loading
              ? const Center(child: CircularProgressIndicator())
              : cartProvider.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: defaultPadding),
                          Text(
                            'Giỏ hàng trống',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => cartProvider.loadCart(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(defaultPadding),
                        itemCount: cartProvider.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: defaultPadding / 2),
                        itemBuilder: (context, index) {
                          final entry = cartProvider.items[index];
                          final cartItem = entry.cartItem;
                          final product = entry.product;
                          final imageUrl = product?.imageUrl ?? productDemoImg1;
                          final title = product?.name ?? 'Product';
                          final price = product?.price ?? 0.0;
                          final isSelected =
                              selectedItems.contains(cartItem.id);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(defaultBorderRadious)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(defaultPadding / 2),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: cellphoneZRed,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedItems.add(cartItem.id);
                                        } else {
                                          selectedItems.remove(cartItem.id);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 86,
                                    height: 86,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: NetworkImageWithLoader(imageUrl),
                                    ),
                                  ),
                                  const SizedBox(width: defaultPadding / 2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatVND(price),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: cellphoneZRed,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            SizedBox(
                                              height: 36,
                                              width: 36,
                                              child: OutlinedButton(
                                                onPressed: cartItem.quantity > 1
                                                    ? () => cartProvider
                                                        .updateQuantity(
                                                            cartItem.id,
                                                            cartItem.quantity -
                                                                1)
                                                    : null,
                                                style: OutlinedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  side: const BorderSide(
                                                      color: cellphoneZRed),
                                                  foregroundColor:
                                                      cellphoneZRed,
                                                ),
                                                child: const Icon(Icons.remove,
                                                    size: 18),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Text(
                                                cartItem.quantity.toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 36,
                                              width: 36,
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    cartProvider.updateQuantity(
                                                        cartItem.id,
                                                        cartItem.quantity + 1),
                                                style: OutlinedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  side: const BorderSide(
                                                      color: cellphoneZRed),
                                                  foregroundColor:
                                                      cellphoneZRed,
                                                ),
                                                child: const Icon(Icons.add,
                                                    size: 18),
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () => cartProvider
                                                  .removeItem(cartItem.id),
                                              icon: const Icon(
                                                  Icons.delete_outline),
                                              color: cellphoneZRed,
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          bottomNavigationBar: cartProvider.items.isEmpty
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Select All Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: selectedItems.length ==
                                        cartProvider.items.length &&
                                    cartProvider.items.isNotEmpty,
                                activeColor: cellphoneZRed,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      // Select all
                                      selectedItems = cartProvider.items
                                          .map((e) => e.cartItem.id)
                                          .toSet();
                                    } else {
                                      // Deselect all
                                      selectedItems.clear();
                                    }
                                  });
                                },
                              ),
                              Text(
                                'Chọn tất cả (${selectedItems.length}/${cartProvider.items.length})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Tổng thanh toán',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    formatVND(selectedTotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: cellphoneZRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          // Checkout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: selectedItems.isEmpty
                                  ? null
                                  : () => _handleCheckout(cartProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cellphoneZRed,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[600],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                selectedItems.isEmpty
                                    ? 'Vui lòng chọn sản phẩm'
                                    : 'Thanh toán (${selectedItems.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
