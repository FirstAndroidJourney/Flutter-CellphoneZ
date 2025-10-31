import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/product.dart';
import '../../products/bloc/product_admin_bloc.dart';
import 'widgets/product_form.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[ProductFormScreen] build | productId=${product?.id ?? 'new'}',
    );
    return BlocListener<ProductAdminBloc, ProductAdminState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == ProductAdminFormStatus.success) {
          debugPrint(
            '[ProductFormScreen] form success | productId=${product?.id ?? 'new'} | message=${state.successMessage}',
          );
          Navigator.of(context).maybePop(state.successMessage);
        } else if (state.formStatus == ProductAdminFormStatus.failure &&
            state.errorMessage != null) {
          debugPrint(
            '[ProductFormScreen] form failure | productId=${product?.id ?? 'new'} | error=${state.errorMessage}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
          ),
        ),
        body: SafeArea(
          child: ProductForm(product: product),
        ),
      ),
    );
  }
}
