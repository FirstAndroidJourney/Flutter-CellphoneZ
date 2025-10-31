import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/product/views/product_returns_screen.dart';
import 'package:shop/screens/product/views/product_buy_now_screen.dart';
import 'package:shop/components/review_card.dart';
import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  late Future<Product?> _productFuture;
  List<Product> _relatedProducts = [];
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProduct();
    _loadRelatedProducts();
  }

  Future<Product?> _loadProduct() async {
    try {
      return await _productService.getProductById(widget.productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadRelatedProducts() async {
    setState(() {
      _loadingRelated = true;
    });

    try {
      final relatedProducts =
          await _productService.getRelatedProducts(widget.productId);
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

    // Nếu không có sản phẩm liên quan, hiển thị sản phẩm mẫu
    if (_relatedProducts.isEmpty) {
      // Tạo danh sách sản phẩm mẫu
      List<Product> demoProducts = List.generate(
        5,
        (index) => Product(
          id: 'demo-$index',
          name: "Sleeveless Tiered Dobby Swing Dress",
          price: 24.65,
          categoryId: "LIPSY LONDON",
          imageUrl: productDemoImg2,
          isAvailable: true,
        ),
      );

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: demoProducts.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
              left: defaultPadding,
              right: index == demoProducts.length - 1 ? defaultPadding : 0),
          child: ProductCard.fromProduct(
            product: demoProducts[index],
            priceAfterDiscount: index.isEven ? 20.99 : null,
            discountPercent: index.isEven ? 25 : null,
            onPressed: () {},
          ),
        ),
      );
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
                builder: (context) => ProductDetailScreen(
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
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải thông tin sản phẩm'),
                  const SizedBox(height: defaultPadding),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _productFuture = _loadProduct();
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;
          // Xác định có sẵn sàng mua hay không
          final bool isAvailable = product.isAvailable;

          return Scaffold(
            bottomNavigationBar: isAvailable
                ? CartButton(
                    price: product.price,
                    press: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: ProductBuyNowScreen(
                          productId: product.id,
                          price: product.price,
                          title: product.name,
                          imageUrl: product.imageUrl,
                        ),
                      );
                    },
                  )
                : NotifyMeCard(
                    isNotify: false,
                    onChanged: (value) {},
                  ),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Hình ảnh sản phẩm
                  SliverToBoxAdapter(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: product.imageUrl != null
                          ? ProductImages(
                              images: [product.imageUrl!],
                            )
                          : ProductImages(
                              images: [productDemoImg1, productDemoImg2],
                            ),
                    ),
                  ),

                  // Thông tin sản phẩm
                  SliverToBoxAdapter(
                    child: ProductInfo(
                      brand: product.categoryId,
                      title: product.name,
                      isAvailable: isAvailable,
                      description: product.description ??
                          "Không có mô tả chi tiết cho sản phẩm này.",
                      rating: 4.5,
                      numOfReviews: 120,
                    ),
                  ),

                  // Các mục chi tiết sản phẩm
                  SliverToBoxAdapter(
                    child: ProductListTile(
                      svgSrc: "assets/icons/Product.svg",
                      title: "Chi tiết sản phẩm",
                      press: () {
                        customModalBottomSheet(
                          context,
                          height: MediaQuery.of(context).size.height * 0.92,
                          child: const BuyFullKit(
                              images: ["assets/screens/Product detail.png"]),
                        );
                      },
                    ),
                  ),

                  // Chính sách đổi trả
                  SliverToBoxAdapter(
                    child: ProductListTile(
                      svgSrc: "assets/icons/Return.svg",
                      title: "Chính sách đổi trả",
                      isShowBottomBorder: true,
                      press: () {
                        customModalBottomSheet(
                          context,
                          height: MediaQuery.of(context).size.height * 0.92,
                          child: const ProductReturnsScreen(),
                        );
                      },
                    ),
                  ),

                  // Đánh giá sản phẩm
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

                  // Link đến trang đánh giá chi tiết
                  SliverToBoxAdapter(
                    child: ProductListTile(
                      svgSrc: "assets/icons/Chat.svg",
                      title: "Đánh giá",
                      isShowBottomBorder: true,
                      press: () {
                        Navigator.pushNamed(context, productReviewsScreenRoute);
                      },
                    ),
                  ),

                  // Sản phẩm liên quan
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Text(
                        "Có thể bạn cũng thích",
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
        },
      ),
    );
  }
}
