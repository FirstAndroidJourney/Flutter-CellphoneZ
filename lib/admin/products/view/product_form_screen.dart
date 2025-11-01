import 'dart:math' as math;

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
            const maxWidth = 520.0;
            final double width;
            if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
              width = math.min(constraints.maxWidth, maxWidth);
            } else {
              width = maxWidth;
            }

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ProductForm(product: product),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
