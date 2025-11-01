import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';


import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/unit_price.dart';

import 'package:shop/services/cart_service.dart';

class ProductBuyNowScreen extends StatefulWidget {
  const ProductBuyNowScreen({
    super.key,
    required this.productId,
    required this.price,
    this.title,
    this.imageUrl,
  });

  final String productId;
  final double price;
  final String? title;
  final String? imageUrl; 

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  void _increment() {
    setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CartButton(
        price: widget.price, // Dùng giá được truyền vào
        title: _isAdding ? "Adding..." : "Add to cart",
        subTitle: "Total price",
        press: () async {
          if (_isAdding) return;
          setState(() => _isAdding = true);
          try {
            // ----- Cách 1: Dùng CartService trực tiếp (như code của bạn) -----
            final cartService = CartService();
            await cartService.addToCart(
              productId: widget.productId,
              quantity: _quantity,
            );

            // ----- Cách 2: Dùng CartProvider (Nếu bạn đã setup) -----
            // await context.read<CartProvider>().addToCart(
            //       productId: widget.productId,
            //       quantity: _quantity,
            //     );
            
            // --------------------------------------------------------

            // Ẩn modal "BuyNow" trước khi hiển thị "AddedToCart"
            // Navigator.of(context).pop(); // Bỏ comment dòng này nếu cần
            
            customModalBottomSheet(
              context,
              isDismissible: false,
              child: const AddedToCartMessageScreen(),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể thêm vào giỏ: $e')),
            );
          } finally {
            if (mounted) setState(() => _isAdding = false);
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  widget.title ?? "Product", // Dùng title được truyền vào
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter( // <-- SỬA 3: Bỏ `const`
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      child: NetworkImageWithLoader(
                        widget.imageUrl ?? productDemoImg1, 
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: UnitPrice(
                            price: widget.price, // Dùng giá được truyền vào
                            priceAfterDiscount: null,
                          ),
                        ),
                        ProductQuantity(
                          numOfItem: _quantity,
                          onIncrement: _increment,
                          onDecrement: _decrement,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                // SliverToBoxAdapter(
                //   child: SelectedColors(
                //     colors: const [
                //       Color(0xFFEA6262),
                //       Color(0xFFB1CC63),
                //       Color(0xFFFFBF5F),
                //       Color(0xFF9FE1DD),
                //       Color(0xFFC482DB),
                //     ],
                //     selectedColorIndex: 2,
                //     press: (value) {},
                //   ),
                // ),
                // SliverToBoxAdapter(
                //   child: SelectedSize(
                //     sizes: const ["S", "M", "L", "XL", "XXL"],
                //     selectedIndex: 1,
                //     press: (value) {},
                //   ),
                // ),
                // SliverPadding(
                //   padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                //   sliver: SliverToBoxAdapter( // <-- SỬA 5: Thêm SliverToBoxAdapter
                //     child: ProductListTile(
                //       title: "Size guide",
                //       svgSrc: "assets/icons/Sizeguid.svg",
                //       isShowBottomBorder: true,
                //       press: () {
                //         customModalBottomSheet(
                //           context,
                //           height: MediaQuery.of(context).size.height * 0.9,
                //           child: const SizeGuideScreen(),
                //         );
                //       },
                //     ),
                //   ),
                // ),
                // SliverPadding(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: defaultPadding),
                //   sliver: SliverToBoxAdapter(
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const SizedBox(height: defaultPadding / 2),
                //         Text(
                //           "Store pickup availability",
                //           style: Theme.of(context).textTheme.titleSmall,
                //         ),
                //         const SizedBox(height: defaultPadding / 2),
                //         const Text(
                //             "Select a size to check store availability and In-Store pickup options.")
                //       ],
                //     ),
                //   ),
                // ),
                // SliverPadding(
                //   padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                //   sliver: SliverToBoxAdapter( // <-- SỬA 6: Thêm SliverToBoxAdapter
                //     child: ProductListTile(
                //       title: "Check stores",
                //       svgSrc: "assets/icons/Stores.svg",
                //       isShowBottomBorder: true,
                //       press: () {
                //         customModalBottomSheet(
                //           context,
                //           height: MediaQuery.of(context).size.height * 0.92,
                //           child: const LocationPermissonStoreAvailabilityScreen(),
                //         );
                //       },
                //     ),
                //   ),
                // ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding))
              ],
            ),
          )
        ],
      ),
    );
  }
}