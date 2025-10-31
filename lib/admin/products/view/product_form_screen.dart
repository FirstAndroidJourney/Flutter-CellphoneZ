import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../products/bloc/product_admin_bloc.dart';
import '../../products/bloc/product_selection_cubit.dart';
import 'widgets/product_form.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final ProductService _productService = ProductService();

  Product? _product;
  String? _errorMessage;
  bool _loading = false;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final selectionCubit = context.read<ProductSelectionCubit>();
    final selectedId = selectionCubit.state;

    setState(() {
      _productId = selectedId;
      _loading = selectedId != null;
      _errorMessage = null;
    });

    if (selectedId == null) {
      debugPrint('[ProductFormScreen] creating new product');
      _product = null;
      _loading = false;
      return;
    }

    debugPrint('[ProductFormScreen] fetching product | productId=$selectedId');
    try {
      final product = await _productService.getProductById(selectedId);
      if (!mounted) return;
      if (product == null) {
        setState(() {
          _product = null;
          _loading = false;
          _errorMessage = 'Không tìm thấy sản phẩm';
        });
      } else {
        setState(() {
          _product = product;
          _loading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('[ProductFormScreen] fetch error: $error');
      setState(() {
        _loading = false;
        _errorMessage = 'Không thể tải sản phẩm: $error';
      });
    }
  }

  @override
  void dispose() {
    // Ensure selection is cleared when screen is disposed
    context.read<ProductSelectionCubit>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductAdminBloc, ProductAdminState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == ProductAdminFormStatus.success) {
          debugPrint(
            '[ProductFormScreen] form success | productId=${_productId ?? 'new'} | message=${state.successMessage}',
          );
          Navigator.of(context).maybePop(state.successMessage);
        } else if (state.formStatus == ProductAdminFormStatus.failure &&
            state.errorMessage != null) {
          debugPrint(
            '[ProductFormScreen] form failure | productId=${_productId ?? 'new'} | error=${state.errorMessage}',
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
            _productId == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadProduct,
      );
    }

    if (_productId != null && _product == null) {
      return _ErrorState(
        message: 'Sản phẩm đã bị xoá hoặc không tồn tại.',
        onRetry: _loadProduct,
      );
    }

    return LayoutBuilder(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ProductForm(product: _product),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
