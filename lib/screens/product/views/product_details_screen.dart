import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/screens/product/views/location_permission_store_availability_screen.dart';
import 'package:shop/screens/product/views/size_guide_screen.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/screens/product/views/product_returns_screen.dart';

import 'package:shop/route/screen_export.dart';

import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';
import '../../../components/review_card.dart';
import 'product_buy_now_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    this.isProductAvailable = true,
    this.productId,
  });

  final bool isProductAvailable;
  final String? productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _relatedProducts = [];
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  Future<void> _loadRelatedProducts() async {
    // Nếu không có productId, sử dụng sản phẩm mẫu
    if (widget.productId == null) {
      return;
    }

    setState(() {
      _loadingRelated = true;
    });

    try {
      final relatedProducts =
          await _productService.getRelatedProducts(widget.productId!);
      if (mounted) {
        setState(() {
          _relatedProducts = relatedProducts;
          _loadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRelated = false;
        });
      }
    }
  }

  Widget _buildRelatedProducts() {
    if (_loadingRelated) {
      return const Center(child: CircularProgressIndicator());
    }

    // Hiển thị sản phẩm liên quan từ API
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _relatedProducts.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
            left: defaultPadding,
            right: index == _relatedProducts.length - 1 ? defaultPadding : 0),
        child: ProductCard.fromProduct(
          product: _relatedProducts[index],
          onPressed: () {
            // Điều hướng đến chi tiết sản phẩm
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  productId: _relatedProducts[index].id,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.isProductAvailable
          ? CartButton(
              price: 140,
              press: () {
                customModalBottomSheet(
                  context,
                  height: MediaQuery.of(context).size.height * 0.92,
                  child: ProductBuyNowScreen(
                    productId: widget.productId ?? '',
                    price: 140,
                  ),
                );
              },
            )
          :

          /// If product is not available then show [NotifyMeCard]
          NotifyMeCard(
              isNotify: false,
              onChanged: (value) {},
            ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floating: true,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ],
            ),
            const ProductImages(
              images: [productDemoImg1, productDemoImg2, productDemoImg3],
            ),
            ProductInfo(
              brand: "LIPSY LONDON",
              title: "Sleeveless Ruffle",
              isAvailable: widget.isProductAvailable,
              description:
                  "A cool gray cap in soft corduroy. Watch me.' By buying cotton products from Lindex, you're supporting more responsibly...",
              rating: 4.4,
              numOfReviews: 126,
            ),
            ProductListTile(
              svgSrc: "assets/icons/Product.svg",
              title: "Product Details",
              press: () {
                customModalBottomSheet(
                  context,
                  height: MediaQuery.of(context).size.height * 0.92,
                  child: const BuyFullKit(
                      images: ["assets/screens/Product detail.png"]),
                );
              },
            ),
            ProductListTile(
              svgSrc: "assets/icons/Delivery.svg",
              title: "Shipping Information",
              press: () {
                customModalBottomSheet(
                  context,
                  height: MediaQuery.of(context).size.height * 0.92,
                  child: const BuyFullKit(
                    images: ["assets/screens/Shipping information.png"],
                  ),
                );
              },
            ),
            ProductListTile(
              svgSrc: "assets/icons/Return.svg",
              title: "Returns",
              isShowBottomBorder: true,
              press: () {
                customModalBottomSheet(
                  context,
                  height: MediaQuery.of(context).size.height * 0.92,
                  child: const ProductReturnsScreen(),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: ReviewCard(
                  rating: 4.3,
                  numOfReviews: 128,
                  numOfFiveStar: 80,
                  numOfFourStar: 30,
                  numOfThreeStar: 5,
                  numOfTwoStar: 4,
                  numOfOneStar: 1,
                ),
              ),
            ),
            ProductListTile(
              svgSrc: "assets/icons/Chat.svg",
              title: "Reviews",
              isShowBottomBorder: true,
              press: () {
                Navigator.pushNamed(context, productReviewsScreenRoute);
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              sliver: SliverToBoxAdapter(
                child: ProductListTile(
                  title: "Size guide",
                  svgSrc: "assets/icons/Sizeguid.svg",
                  isShowBottomBorder: true,
                  press: () {
                    customModalBottomSheet(
                      context,
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: const SizeGuideScreen(),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              sliver: SliverToBoxAdapter(
                child: ProductListTile(
                  title: "Check stores",
                  svgSrc: "assets/icons/Stores.svg",
                  isShowBottomBorder: true,
                  press: () {
                    customModalBottomSheet(
                      context,
                      height: MediaQuery.of(context).size.height * 0.92,
                      child: const LocationPermissonStoreAvailabilityScreen(),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "You may also like",
                  style: Theme.of(context).textTheme.titleSmall!,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: _buildRelatedProducts(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding),
            )
          ],
        ),
      ),
    );
  }
}
