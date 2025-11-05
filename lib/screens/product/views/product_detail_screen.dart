import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/buy_full_ui_kit.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/services/auth_service.dart';
import 'package:shop/services/order_calculation_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/models/cart_item.dart';
import 'package:shop/screens/product/views/product_returns_screen.dart';
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
  final AuthService _authService = AuthService();
  late Future<Product?> _productFuture;
  List<Product> _relatedProducts = [];
  bool _loadingRelated = false;
  bool _isAddingToCart = false;

  // Format price to VND
  String formatVND(double price) {
    final priceInt = price.toInt();
    return '${priceInt.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
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
              const Icon(
                Icons.lock_outline,
                color: cellphoneZRed,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Yêu cầu đăng nhập'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bạn cần đăng nhập để:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildBenefitItem('Thêm sản phẩm vào giỏ hàng'),
              _buildBenefitItem('Mua sản phẩm'),
              const SizedBox(height: 16),
              const Text(
                'Bạn có muốn đăng nhập ngay bây giờ?',
                style: TextStyle(fontSize: 14),
              ),
            ],
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Add to cart with auth check
  Future<void> _handleAddToCart(String productId) async {
    // Check authentication first
    if (!_authService.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.addToCart(productId, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào giỏ hàng'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: cellphoneZRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  // Buy now with auth check
  Future<void> _handleBuyNow(Product product) async {
    // Check authentication first
    if (!_authService.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    try {
      // Lấy thông tin sản phẩm hiện tại
      final product = await _productFuture;
      if (product == null) {
        throw Exception('Không tìm thấy thông tin sản phẩm');
      }

      // Tạo CartItem tạm thời cho sản phẩm này (không có ID từ DB)
      final tempCartItem = CartItem(
        id: '', // Empty ID để biết đây là buy now, không phải từ cart
        userId: _authService.currentUser?.id ?? '',
        productId: product.id,
        quantity: 1,
        unitPrice: product.price,
        productName: product.name,
        productImage: product.imageUrl,
      );

      // Tính toán đơn hàng
      final orderSummary = OrderCalculationService().calculateOrder(
        items: [tempCartItem],
        deliveryLocation: '', // Sẽ chọn sau ở màn thanh toán
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          paymentScreenRoute,
          arguments: {
            'orderSummary': orderSummary,
            'deliveryAddress': '',
            'items': [tempCartItem],
            'isBuyNow': true, // Flag để biết đây là mua ngay, không từ cart
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: cellphoneZRed,
        ),
      );
    }
  }

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

    if (_relatedProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'Không có sản phẩm liên quan',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ],
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
          right: index == _relatedProducts.length - 1 ? defaultPadding : 0,
        ),
        child: SizedBox(
          width: 160,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cellphoneZRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset("assets/icons/Bookmark.svg",
                color: Colors.white),
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
            backgroundColor: Colors.grey[50],
            bottomNavigationBar: isAvailable
                ? Container(
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price section - Fixed width to prevent wrapping
                            SizedBox(
                              width: 110,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Giá',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatVND(product.price),
                                      style: const TextStyle(
                                        color: cellphoneZRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Add to Cart button
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isAddingToCart
                                    ? null
                                    : () => _handleAddToCart(product.id),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(color: cellphoneZRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isAddingToCart
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cellphoneZRed,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: cellphoneZRed,
                                        size: 22,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Buy Now button - Takes remaining space
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _handleBuyNow(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cellphoneZRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Mua ngay',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          : const ProductImages(
                              images: [productDemoImg1, productDemoImg2],
                            ),
                    ),
                  ),

                  // Thông tin sản phẩm
                  ProductInfo(
                    brand: product.categoryId,
                    title: product.name,
                    isAvailable: isAvailable,
                    description: product.description ??
                        "Không có mô tả chi tiết cho sản phẩm này.",
                    rating: 4.5,
                    numOfReviews: 120,
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
