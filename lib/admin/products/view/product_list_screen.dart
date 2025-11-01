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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 24,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(6, 6),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(-6, -6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/logo/CellphoneZ.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Quản lý sản phẩm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadProducts(showSpinner: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
              foregroundColor: colorScheme.primary,
            ),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackCards = constraints.maxWidth < 720;
          final children = [
            _StatCard(
              icon: Icons.inventory_2_outlined,
              label: 'Tổng sản phẩm',
              value: totalProducts.toString(),
              iconColor: colorScheme.primary,
            ),
            _StatCard(
              icon: Icons.store_mall_directory_outlined,
              label: 'Đang bán',
              value: availableProducts.toString(),
              iconColor: colorScheme.secondary,
            ),
            _StatCard(
              icon: Icons.pause_circle_outline,
              label: 'Tạm ngưng',
              value: unavailableProducts.toString(),
              iconColor: colorScheme.error,
            ),
          ];

          if (stackCards) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 12),
                ],
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
                  for (int i = 0; i < children.length; i++) ...[
                    Expanded(child: children[i]),
                    if (i != children.length - 1) const SizedBox(width: 16),
                  ],
                ],
              ),
              const SizedBox(height: 12),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = colorScheme.surface;

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(6, 6),
            blurRadius: 18,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(-5, -5),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
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
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              offset: const Offset(8, 8),
              blurRadius: 24,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              offset: const Offset(-6, -6),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            cursorColor: colorScheme.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xoá tìm kiếm',
                    )
                  : null,
              hintText: 'Tìm kiếm sản phẩm theo tên',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
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
    final colorScheme = theme.colorScheme;
    final color = colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(8, 8),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.85),
                offset: const Offset(-6, -6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy sản phẩm cho "$query"',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(6, 6),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(-6, -6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 36,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.check_circle_outline
                                    : Icons.pause_circle_outline,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TileActionButton(
                        tooltip: 'Chỉnh sửa',
                        icon: Icons.edit_outlined,
                        color: colorScheme.primary,
                        onPressed: actionsEnabled ? onEdit : null,
                      ),
                      const SizedBox(width: 4),
                      _TileActionButton(
                        tooltip: isAvailable ? 'Ngừng bán' : 'Mở bán lại',
                        icon: isAvailable
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: statusColor,
                        onPressed: actionsEnabled ? onToggleAvailability : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileActionButton extends StatelessWidget {
  const _TileActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final background = isEnabled
        ? color.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);
    final foreground = isEnabled
        ? color
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      splashRadius: 18,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(8, 8),
              blurRadius: 24,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              offset: const Offset(-6, -6),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Chưa có sản phẩm nào',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(8, 8),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.85),
                offset: const Offset(-6, -6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
