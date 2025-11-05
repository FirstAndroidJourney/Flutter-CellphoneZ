import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category.dart';
import 'package:shop/models/product.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/category/views/category_products_screen.dart';
import 'package:shop/services/product_service.dart';

class CategoryProductsSection extends StatefulWidget {
  final Category category;

  const CategoryProductsSection({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsSection> createState() =>
      _CategoryProductsSectionState();
}

class _CategoryProductsSectionState extends State<CategoryProductsSection> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products =
          await _productService.getProductsByParentCategory(widget.category.id);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryId: widget.category.id,
                        categoryName: widget.category.name,
                      ),
                    ),
                  );
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        SizedBox(
          height: 250,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: defaultPadding,
                        right:
                            index == _products.length - 1 ? defaultPadding : 0,
                      ),
                      child: ProductCard.fromProduct(
                        product: product,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            productDetailScreenRoute,
                            arguments: product.id,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
