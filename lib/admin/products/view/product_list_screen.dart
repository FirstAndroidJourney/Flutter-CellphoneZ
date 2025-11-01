import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Product> _products = const [];
  List<Product> _filteredProducts = const [];
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts(showSpinner: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _filteredProducts = _filterProducts(_searchQuery);
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

  int get _totalProducts => _products.length;

  int get _availableProducts =>
      _products.where((product) => product.isAvailable).length;

  int get _unavailableProducts => _totalProducts - _availableProducts;

  double get _totalInventoryValue => _products.fold(
        0,
        (previousValue, product) => previousValue + product.price,
      );

  List<Product> _filterProducts(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<Product>.from(_products);
    }
    return _products
        .where(
          (product) => product.name.toLowerCase().contains(normalized),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filteredProducts = _filterProducts(value);
    });
  }

  void _clearSearch() {
    if (_searchQuery.isEmpty) return;
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filteredProducts = List<Product>.from(_products);
    });
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
      final message =
          shouldEnable ? 'Đã mở bán lại sản phẩm' : 'Đã ngừng bán sản phẩm';
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
    final Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = _ErrorView(
        message: _errorMessage!,
        onRetry: () => _loadProducts(showSpinner: true),
      );
    } else {
      content = _buildDashboardContent(context);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                'assets/logo/CellphoneZ.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quản lý sản phẩm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadProducts(showSpinner: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
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
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final hasBaseProducts = _products.isNotEmpty;
    final hasVisibleProducts = _filteredProducts.isNotEmpty;
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: _StatsSection(
            totalProducts: _totalProducts,
            availableProducts: _availableProducts,
            unavailableProducts: _unavailableProducts,
            totalInventoryValue: _totalInventoryValue,
          )),
          SliverToBoxAdapter(
            child: _SearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          if (!hasBaseProducts)
            SliverFillRemaining(
              hasScrollBody: false,
              child:
                  _EmptyView(onReload: () => _loadProducts(showSpinner: true)),
            )
          else if (!hasVisibleProducts && hasSearchQuery)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchEmptyView(
                query: _searchQuery.trim(),
                onClear: _clearSearch,
              ),
            )
          else if (!hasVisibleProducts)
            SliverFillRemaining(
              hasScrollBody: false,
              child:
                  _EmptyView(onReload: () => _loadProducts(showSpinner: true)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return _ProductTile(
                      product: product,
                      actionsEnabled: !_isProcessing,
                      onEdit: () => _openForm(product: product),
                      onToggleAvailability: () => _changeAvailability(product),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.totalProducts,
    required this.availableProducts,
    required this.unavailableProducts,
    required this.totalInventoryValue,
  });

  final int totalProducts;
  final int availableProducts;
  final int unavailableProducts;
  final double totalInventoryValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final totalValueLabel = currency.format(totalInventoryValue);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Tổng sản phẩm',
                        value: totalProducts.toString(),
                        iconColor: colorScheme.primary,
                        width: 220,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Đang bán',
                        value: availableProducts.toString(),
                        iconColor: colorScheme.secondary,
                        width: 220,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.pause_circle_outline,
                        label: 'Tạm ngưng',
                        value: unavailableProducts.toString(),
                        iconColor: colorScheme.error,
                        width: 220,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StatCard(
                  icon: Icons.payments_outlined,
                  label: 'Tổng giá niêm yết',
                  value: totalValueLabel,
                  iconColor: colorScheme.tertiary,
                  isFullWidth: true,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Tổng sản phẩm',
                      value: totalProducts.toString(),
                      iconColor: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.store_mall_directory_outlined,
                      label: 'Đang bán',
                      value: availableProducts.toString(),
                      iconColor: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pause_circle_outline,
                      label: 'Tạm ngưng',
                      value: unavailableProducts.toString(),
                      iconColor: colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatCard(
                icon: Icons.payments_outlined,
                label: 'Tổng giá niêm yết',
                value: totalValueLabel,
                iconColor: colorScheme.tertiary,
                isFullWidth: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isFullWidth = false,
    this.width,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isFullWidth;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: isFullWidth ? double.infinity : width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm theo tên',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Xoá tìm kiếm',
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm cho "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử điều chỉnh từ khoá hoặc xoá tìm kiếm để xem tất cả sản phẩm.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Xoá tìm kiếm'),
            ),
          ],
        ),
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

  static final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = product.imageUrl;
    final isAvailable = product.isAvailable;
    final priceText = _priceFormatter.format(product.price);
    final statusColor = isAvailable ? colorScheme.primary : colorScheme.error;
    final statusLabel = isAvailable ? 'Đang bán' : 'Ngừng bán';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    priceText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Chỉnh sửa',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: actionsEnabled ? onEdit : null,
                      ),
                      IconButton(
                        tooltip: isAvailable ? 'Ngừng bán' : 'Mở bán lại',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isAvailable
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: actionsEnabled
                              ? statusColor
                              : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: actionsEnabled ? onToggleAvailability : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
