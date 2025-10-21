import 'package:flutter/material.dart';
import 'package:shop/components/product/products_grid.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/services/product_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    Key? key,
    this.categoryId,
    this.title,
  }) : super(key: key);

  final String? categoryId;
  final String? title;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = false;
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
        _products = await _productService.getAllProducts();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Danh sách sản phẩm'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              'Hiển thị ${_products.length} sản phẩm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ProductsGrid(products: _products),
        ],
      ),
    );
  }
}
