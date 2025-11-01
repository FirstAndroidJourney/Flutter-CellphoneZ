import 'package:flutter/material.dart';

import '../../../models/product.dart';
import 'widgets/product_form.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ProductForm(product: product),
            ),
          ),
        ),
      ),
    );
  }
}
