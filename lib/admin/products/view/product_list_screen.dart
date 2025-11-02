import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Product> _products = const [];
  List<Product> _filteredProducts = const [];
  String _searchQuery = '';
  String? _errorMessage;
  bool _isCategoryLoading = true;
  bool _isSubcategoryLoading = false;
  String? _categoryError;
  String? _loadingSubcategoryParentId;
  List<Category> _rootCategories = const [];
  final Map<String, List<Category>> _subcategoryCache = {};
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _loadProducts(showSpinner: true);
    _loadCategories();
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
        _isLoading = false;
        _errorMessage = null;
      });
      _applyFilters();
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
    Set<String>? allowedCategories;
    if (_selectedSubcategoryId != null) {
      allowedCategories = {_selectedSubcategoryId!};
    } else if (_selectedCategoryId != null) {
      final ids = <String>{_selectedCategoryId!};
      final subcategories = _subcategoryCache[_selectedCategoryId!] ?? const [];
      ids.addAll(subcategories.map((category) => category.id));
      allowedCategories = ids;
    }

    return _products.where((product) {
      final matchesSearch =
          normalized.isEmpty || product.name.toLowerCase().contains(normalized);
      final matchesCategory = allowedCategories == null ||
          allowedCategories.contains(product.categoryId);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _searchController.clear();
    _applyFilters();
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

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryError = null;
    });

    try {
      final categories = await _categoryService.getRootCategories();
      if (!mounted) return;
      setState(() {
        _rootCategories = categories;
        _isCategoryLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCategoryLoading = false;
        _categoryError = 'Không thể tải danh mục: $error';
      });
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredProducts = _filterProducts(_searchQuery);
    });
  }

  Future<void> _onCategorySelected(String? categoryId) async {
    if (categoryId == null) {
      setState(() {
        _selectedCategoryId = null;
        _selectedSubcategoryId = null;
      });
      _applyFilters();
      return;
    }

    if (_selectedCategoryId == categoryId && _selectedSubcategoryId == null) {
      _applyFilters();
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryId = null;
    });

    if (!_subcategoryCache.containsKey(categoryId)) {
      setState(() {
        _isSubcategoryLoading = true;
        _loadingSubcategoryParentId = categoryId;
      });
      try {
        final subcategories =
            await _categoryService.getSubcategories(categoryId);
        if (!mounted) return;
        setState(() {
          _subcategoryCache[categoryId] = subcategories;
          _isSubcategoryLoading = false;
          _loadingSubcategoryParentId = null;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isSubcategoryLoading = false;
          _loadingSubcategoryParentId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh mục con: $error')),
        );
      }
    }

    _applyFilters();
  }

  void _onSubcategorySelected(String? subcategoryId) {
    setState(() {
      if (_selectedSubcategoryId == subcategoryId) {
        _selectedSubcategoryId = null;
      } else {
        _selectedSubcategoryId = subcategoryId;
      }
    });
    _applyFilters();
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
          SliverToBoxAdapter(
            child: _CategoryFilterBar(
              isLoading: _isCategoryLoading,
              errorMessage: _categoryError,
              categories: _rootCategories,
              selectedCategoryId: _selectedCategoryId,
              selectedSubcategoryId: _selectedSubcategoryId,
              subcategories: _subcategoryCache,
              isSubcategoryLoading: _isSubcategoryLoading &&
                  _loadingSubcategoryParentId == _selectedCategoryId,
              onCategorySelected: _onCategorySelected,
              onSubcategorySelected: _onSubcategorySelected,
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
                  childAspectRatio: 0.75,
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

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.isLoading,
    required this.errorMessage,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.subcategories,
    required this.isSubcategoryLoading,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Category> categories;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final Map<String, List<Category>> subcategories;
  final bool isSubcategoryLoading;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String?> onSubcategorySelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (errorMessage != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.error),
            ),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedParentId = selectedCategoryId;
    final currentSubcategories = selectedParentId != null
        ? (subcategories[selectedParentId] ?? const <Category>[])
        : const <Category>[];

    final chips = <Widget>[];

    void addChip(Widget chip, {double spacing = 8}) {
      if (chips.isNotEmpty) {
        chips.add(SizedBox(width: spacing));
      }
      chips.add(chip);
    }

    addChip(
      _FilterChip(
        label: 'Default',
        selected: selectedCategoryId == null && selectedSubcategoryId == null,
        onSelected: () => onCategorySelected(null),
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );

    for (final category in categories) {
      addChip(
        _FilterChip(
          label: category.name,
          selected: selectedCategoryId == category.id,
          onSelected: () => onCategorySelected(category.id),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );

      if (category.id == selectedParentId) {
        if (isSubcategoryLoading) {
          addChip(
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            spacing: 3,
          );
        } else if (currentSubcategories.isNotEmpty) {
          addChip(
            _FilterChip(
              label: 'Tất cả',
              selected: selectedSubcategoryId == null,
              onSelected: () => onSubcategorySelected(null),
              colorScheme: colorScheme,
              textTheme: textTheme,
              dense: true,
              isSubcategory: true,
            ),
            spacing: 3,
          );

          for (final subcategory in currentSubcategories) {
            addChip(
              _FilterChip(
                label: subcategory.name,
                selected: selectedSubcategoryId == subcategory.id,
                onSelected: () => onSubcategorySelected(subcategory.id),
                colorScheme: colorScheme,
                textTheme: textTheme,
                dense: true,
                isSubcategory: true,
              ),
              spacing: 3,
            );
          }
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: chips),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.colorScheme,
    required this.textTheme,
    this.dense = false,
    this.isSubcategory = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool dense;
  final bool isSubcategory;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        (isSubcategory ? textTheme.bodySmall : textTheme.bodyMedium) ??
            const TextStyle();
    final baseStyle = textStyle.copyWith(
      fontSize: isSubcategory ? 11 : (dense ? 12 : textStyle.fontSize),
      color: selected
          ? (isSubcategory ? colorScheme.onSecondary : colorScheme.onPrimary)
          : colorScheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    final labelWidget = isSubcategory
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: baseStyle,
            ),
          )
        : Text(label, style: baseStyle);

    final selectedColor =
        isSubcategory ? colorScheme.secondary : colorScheme.primary;
    final unselectedBackground = isSubcategory
        ? colorScheme.secondaryContainer.withValues(alpha: 0.4)
        : colorScheme.surface;
    final unselectedBorder = isSubcategory
        ? colorScheme.secondary.withValues(alpha: 0.5)
        : colorScheme.outlineVariant.withValues(alpha: 0.6);

    final chip = ChoiceChip(
      label: labelWidget,
      selected: selected,
      onSelected: (_) => onSelected(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSubcategory ? 8 : 18),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSubcategory ? 6 : (dense ? 8 : 12),
        vertical: isSubcategory ? 1 : (dense ? 2 : 4),
      ),
      labelStyle: baseStyle,
      selectedColor: selectedColor,
      backgroundColor: selected ? selectedColor : unselectedBackground,
      side: BorderSide(
        color: selected ? selectedColor : unselectedBorder,
      ),
      showCheckmark: !isSubcategory,
    );

    if (!isSubcategory) return chip;

    return chip;
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
    final nameStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final lineHeight = (nameStyle?.fontSize ?? 14) * (nameStyle?.height ?? 1.2);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
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
              top: Radius.circular(18),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
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
                        size: 32,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: lineHeight * 2,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.18),
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
                                size: 10,
                                color: statusColor,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
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
                  const SizedBox(height: 2),
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
