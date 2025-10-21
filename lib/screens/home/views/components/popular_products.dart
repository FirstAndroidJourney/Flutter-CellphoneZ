import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';
import 'package:shop/models/product.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/product_service.dart';

import '../../../../constants.dart';

class PopularProducts extends StatefulWidget {
  const PopularProducts({
    super.key,
  });

  @override
  State<PopularProducts> createState() => _PopularProductsState();
}

class _PopularProductsState extends State<PopularProducts> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _popularProductsFuture;

  @override
  void initState() {
    super.initState();
    _popularProductsFuture = _loadPopularProducts();
  }

  Future<List<Product>> _loadPopularProducts() async {
    try {
      debugPrint('Loading popular products...');
      // Lấy danh sách sản phẩm nổi bật từ ProductService
      var popularProducts =
          await _productService.getFeaturedProducts(limit: 10);
      debugPrint('Loaded ${popularProducts.length} popular products.');
      return popularProducts;
    } catch (e) {
      // Xử lý lỗi và hiển thị thông báo
      debugPrint('Error loading popular products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Popular products",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        FutureBuilder<List<Product>>(
          future: _popularProductsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Hiển thị skeleton loader khi đang tải
              return const ProductsSkelton();
            } else if (snapshot.hasError) {
              // Hiển thị thông báo lỗi
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Hiển thị thông báo khi không có dữ liệu
              return const Center(child: Text('No products available'));
            }

            // Lấy danh sách sản phẩm từ kết quả
            final products = snapshot.data!;

            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == products.length - 1 ? defaultPadding : 0,
                  ),
                  child: ProductCard.fromProduct(
                    product: products[index],
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        productDetailScreenRoute,
                        arguments: products[index].id,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
