import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<CartItemWithProduct> _items = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final items = await _cartService.getCartItemsWithProducts();
      final total = await _cartService.getCartTotal();
      if (mounted) {
        setState(() {
          _items = items;
          _total = total;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể tải giỏ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQty) async {
    try {
      await _cartService.updateQuantity(cartItemId, newQty);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không cập nhật được: $e')));
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không xóa được: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'Giỏ hàng trống',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCart,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(defaultPadding),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: defaultPadding / 2),
                    itemBuilder: (context, index) {
                      final entry = _items[index];
                      final cartItem = entry.cartItem;
                      final product = entry.product;
                      final imageUrl = product?.imageUrl ?? productDemoImg1;
                      final title = product?.name ?? 'Product';
                      final price = product?.price ?? 0.0;

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                              Radius.circular(defaultBorderRadious)),
                          border: Border.all(
                              color: Theme.of(context).dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(defaultPadding / 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 86,
                                height: 86,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      NetworkImageWithLoader(imageUrl),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 6),
                                    Text(
                                      "\$${price.toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: OutlinedButton(
                                            onPressed: cartItem.quantity > 1
                                                ? () => _updateQuantity(
                                                    cartItem.id,
                                                    cartItem.quantity - 1)
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Icon(Icons.remove,
                                                size: 18),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                            cartItem.quantity.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: OutlinedButton(
                                            onPressed: () => _updateQuantity(
                                                cartItem.id,
                                                cartItem.quantity + 1),
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Icon(Icons.add,
                                                size: 18),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () =>
                                              _removeItem(cartItem.id),
                                          icon: const Icon(Icons.delete_outline),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding, vertical: defaultBorderRadious / 2),
          child: CartButton(
            price: _total,
            title: 'Checkout',
            subTitle: 'Total price',
            press: () {
              // TODO: chuyển đến trang checkout / payment
            },
          ),
        ),
      ),
    );
  }
}