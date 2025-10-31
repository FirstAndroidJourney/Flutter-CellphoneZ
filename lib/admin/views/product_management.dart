
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop/components/admin/product_form_dialog.dart';
import 'package:shop/models/category.dart';
import 'package:shop/models/product.dart';
import 'package:shop/services/category_service.dart';
import 'package:shop/services/product_service.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  bool _isProcessing = false;
  List<Product> _products = [];
  List<CategoryOption> _categories = [];
  String? _errorMessage;
  String? _selectedCategoryId;
  bool? _availabilityFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _categoryService.getAllCategories(),
      ]);

      final products = results[0] as List<Product>;
      final categories = results[1] as List<Category>;

      setState(() {
        _products = products;
        _categories = categories
            .map((category) => CategoryOption(
                  id: category.id,
                  name: category.name,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products: $e';
      });
    }
  }

  void _handleSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _applyFilters);
  }

  Future<void> _applyFilters() async {
    final searchTerm = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Product> products;

      if (searchTerm.isNotEmpty) {
        products = await _productService.searchProducts(searchTerm);
      } else if (_selectedCategoryId != null) {
        products = await _productService
            .getProductsByCategory(_selectedCategoryId!);
      } else {
        products = await _productService.getAllProducts();
      }

      if (_availabilityFilter != null) {
        products = products
            .where((product) => product.isAvailable == _availabilityFilter)
            .toList();
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to apply filters: $e';
      });
    }
  }

  Future<void> _handleCreateProduct() async {
    await ProductFormDialog.show(
      context,
      categories: _categories,
      onSubmit: _submitProduct,
    );
    await _applyFilters();
  }

  Future<void> _handleEditProduct(Product product) async {
    await ProductFormDialog.show(
      context,
      product: product,
      categories: _categories,
      onSubmit: _submitProduct,
    );
    await _applyFilters();
  }

  Future<void> _submitProduct(ProductFormData data) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (data.id == null) {
        await _productService.createProduct(
          name: data.name,
          price: data.price,
          categoryId: data.categoryId,
          description: data.description,
          imageUrl: data.imageUrl,
          localImagePath: data.localImagePath,
        );
      } else {
        await _productService.updateProduct(
          data.id!,
          name: data.name,
          price: data.price,
          categoryId: data.categoryId,
          description: data.description,
          imageUrl: data.imageUrl,
          isAvailable: data.isAvailable,
          localImagePath: data.localImagePath,
          previousImageUrl: data.previousImageUrl,
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _productService.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product "${product.name}" deleted')),
        );
      }
      await _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(Product product) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await _productService.updateProduct(
        product.id,
        isAvailable: !product.isAvailable,
      );
      await _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(child: _buildProductList()),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _handleCreateProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search products...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _applyFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  initialValue: _availabilityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Availability',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Unavailable'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _availabilityFilter = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return const Center(
        child: Text('No products found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _applyFilters,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _buildLeadingImage(product),
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: \$${product.price.toStringAsFixed(2)}'),
                  Text('Category: ${_resolveCategoryName(product.categoryId)}'),
                  Text(
                    product.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: product.isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              trailing: _buildActions(product),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: _products.length,
      ),
    );
  }

  Widget _buildLeadingImage(Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        product.imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Widget _buildActions(Product product) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await _handleEditProduct(product);
            break;
          case 'toggle':
            await _toggleAvailability(product);
            break;
          case 'delete':
            await _handleDeleteProduct(product);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              product.isAvailable ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(product.isAvailable ? 'Mark unavailable' : 'Mark available'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }

  String _resolveCategoryName(String categoryId) {
    return _categories
        .firstWhere(
          (category) => category.id == categoryId,
          orElse: () => CategoryOption(id: categoryId, name: 'Unknown'),
        )
        .name;
  }
}
