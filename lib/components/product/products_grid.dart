import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/services/product_service.dart';
import 'product_card.dart';

class ProductsGrid extends StatelessWidget {
  const ProductsGrid({
    Key? key,
    required this.products,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
  }) : super(key: key);

  final List<Product> products;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: defaultPadding,
        crossAxisSpacing: defaultPadding,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard.fromProduct(
          product: product,
          onPressed: () {
            // Xử lý khi người dùng nhấp vào sản phẩm
            Navigator.pushNamed(
              context,
              '/product-details',
              arguments: product,
            );
          },
        );
      },
    );
  }
}

/// Widget để tải và hiển thị danh sách sản phẩm từ repository
class ProductsGridFromService extends StatefulWidget {
  const ProductsGridFromService({
    Key? key,
    this.categoryId,
    this.limit = 10,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
  }) : super(key: key);

  final String? categoryId;
  final int limit;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  State<ProductsGridFromService> createState() =>
      _ProductsGridFromServiceState();
}

class _ProductsGridFromServiceState extends State<ProductsGridFromService> {
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  List<Product> _products = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.categoryId != null) {
        _products =
            await _productService.getProductsByCategory(widget.categoryId!);
      } else {
        _products =
            await _productService.getFeaturedProducts(limit: widget.limit);
      }
    } catch (e) {
      _errorMessage = 'Không thể tải sản phẩm: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('Không có sản phẩm nào'),
      );
    }

    return ProductsGrid(
      products: _products,
      crossAxisCount: widget.crossAxisCount,
      childAspectRatio: widget.childAspectRatio,
    );
  }
}

/// Ví dụ về cách sử dụng:
///
/// ```dart
/// // Hiển thị danh sách sản phẩm từ một danh sách có sẵn
/// ProductsGrid(products: listOfProducts)
/// 
/// // Hoặc tải và hiển thị sản phẩm từ repository
/// ProductsGridFromService(
///   categoryId: 'category123',
///   limit: 20,
/// )
/// ```