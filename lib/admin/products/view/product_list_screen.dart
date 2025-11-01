import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Product> _products = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts(showSpinner: true);
  }

  Future<void> _loadProducts({bool showSpinner = false}) async {
    if (!mounted) return;

    setState(() {
      if (showSpinner) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final products = await _productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách sản phẩm: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({Product? product}) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );

    if (!mounted || message == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    await _loadProducts(showSpinner: true);
  }

  Future<void> _changeAvailability(Product product) async {
    if (_isProcessing) {
      return;
    }

    final shouldEnable = !product.isAvailable;
    final title = shouldEnable ? 'Mở bán sản phẩm' : 'Ngừng bán sản phẩm';
    final confirmLabel = shouldEnable ? 'Mở bán' : 'Ngừng bán';
    final content = shouldEnable
        ? 'Bạn có chắc muốn mở bán lại sản phẩm "${product.name}"?'
        : 'Bạn có chắc muốn ngừng bán sản phẩm "${product.name}"?';

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
              backgroundColor: shouldEnable
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _productService.updateProductAvailability(product, shouldEnable);
      if (!mounted) return;
      await _loadProducts();
      if (!mounted) return;
      final message = shouldEnable
          ? 'Đã mở bán lại sản phẩm'
          : 'Đã ngừng bán sản phẩm';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật sản phẩm: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = _ErrorView(
        message: _errorMessage!,
        onRetry: () => _loadProducts(showSpinner: true),
      );
    } else if (_products.isEmpty) {
      body = _EmptyView(onReload: () => _loadProducts(showSpinner: true));
    } else {
      body = RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = _products[index];
            return _ProductTile(
              product: product,
              actionsEnabled: !_isProcessing,
              onEdit: () => _openForm(product: product),
              onToggleAvailability: () => _changeAvailability(product),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            onPressed: () => _loadProducts(showSpinner: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isProcessing) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.actionsEnabled,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  final Product product;
  final bool actionsEnabled;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            onPressed: actionsEnabled ? onEdit : null,
          ),
          IconButton(
            tooltip: isAvailable ? 'Ngừng bán' : 'Mở bán lại',
            icon: Icon(
              isAvailable ? Icons.delete_outline : Icons.restore,
              color: isAvailable
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: actionsEnabled ? onToggleAvailability : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onReload});

  final VoidCallback onReload;

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
            onPressed: onReload,
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
