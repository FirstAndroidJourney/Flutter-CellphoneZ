import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../products/bloc/product_admin_bloc.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProductAdminBloc(ProductService())..add(const ProductAdminStarted()),
      child: const _ProductListView(),
    );
  }
}

class _ProductListView extends StatefulWidget {
  const _ProductListView();

  @override
  State<_ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<_ProductListView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductAdminBloc, ProductAdminState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus ||
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final route = ModalRoute.of(context);
        final isCurrentRoute = route?.isCurrent ?? true;

        if (!isCurrentRoute) {
          return;
        }

        if (state.formStatus == ProductAdminFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context
              .read<ProductAdminBloc>()
              .add(const ProductAdminFormReset());
        } else if (state.formStatus == ProductAdminFormStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
          context
              .read<ProductAdminBloc>()
              .add(const ProductAdminFormReset());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý sản phẩm'),
          actions: [
            IconButton(
              onPressed: () => context
                  .read<ProductAdminBloc>()
                  .add(const ProductAdminRefreshed()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context),
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<ProductAdminBloc, ProductAdminState>(
          builder: (context, state) {
            switch (state.status) {
              case ProductAdminStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ProductAdminStatus.failure:
                return _ErrorView(
                  message: state.errorMessage ??
                      'Không thể tải danh sách sản phẩm.',
                  onRetry: () => context
                      .read<ProductAdminBloc>()
                      .add(const ProductAdminStarted()),
                );
              case ProductAdminStatus.success:
                return _ProductList(
                  products: state.products,
                  onEdit: (product) => _openForm(context, product: product),
                  onDelete: _confirmDelete,
                );
              case ProductAdminStatus.initial:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    debugPrint(
      '[ProductList] _openForm start | productId=${product?.id ?? 'new'}',
    );
    final bloc = context.read<ProductAdminBloc>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await navigator.push<String?>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ProductFormScreen(product: product),
        ),
      ),
    );

    if (!mounted) return;

    debugPrint(
      '[ProductList] _openForm result | productId=${product?.id ?? 'new'} | result="$result"',
    );

    if (result != null && result.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(result)));
      bloc.add(const ProductAdminFormReset());
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final bloc = context.read<ProductAdminBloc>();
    final isAvailable = product.isAvailable;
    final title =
        isAvailable ? 'Ngừng bán sản phẩm' : 'Mở bán lại sản phẩm';
    final content = isAvailable
        ? 'Bạn có chắc muốn ngừng bán "${product.name}" không?'
        : 'Bạn có muốn mở bán lại "${product.name}" không?';
    final confirmLabel = isAvailable ? 'Ngừng bán' : 'Mở bán lại';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(ProductAdminDeleteRequested(product));
    }
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Product> products;
  final Future<void> Function(Product) onEdit;
  final Future<void> Function(Product) onDelete;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductAdminBloc>().add(const ProductAdminRefreshed());
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductTile(
            product: product,
            onEdit: () => onEdit(product),
            onDelete: () => onDelete(product),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: products.length,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final isAvailable = product.isAvailable;

    return ListTile(
      leading: imageUrl != null && imageUrl.isNotEmpty
          ? SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_not_supported),
            ),
      title: Text(product.name),
      subtitle: Text(
        '${product.price.toStringAsFixed(2)} đ • ${isAvailable ? 'Đang bán' : 'Ngừng bán'}',
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: const Icon(Icons.edit),
            onPressed: () {
              debugPrint(
                '[ProductList] Edit tapped | productId=${product.id}',
              );
              onEdit();
            },
          ),
          IconButton(
            tooltip: isAvailable ? 'Ngừng bán' : 'Mở bán lại',
            icon: Icon(
              isAvailable ? Icons.delete_outline : Icons.restore,
              color: isAvailable
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48),
          const SizedBox(height: 8),
          const Text('Chưa có sản phẩm nào'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context
                .read<ProductAdminBloc>()
                .add(const ProductAdminStarted()),
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
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
            const SizedBox(height: 8),
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
