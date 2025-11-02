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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final width = maxWidth >= 520 ? 520.0 : maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: width),
                  child: ProductForm(product: product),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
