import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category.dart';
import 'package:shop/models/product.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/category_service.dart';
import 'package:shop/services/product_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<Category> _subcategories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _selectedSubcategoryId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Loading data for category: ${widget.categoryId}');

      // Lấy danh mục con
      final subcategories =
          await _categoryService.getSubcategories(widget.categoryId);
      print('✅ Found ${subcategories.length} subcategories');

      // Lấy tất cả sản phẩm của danh mục cha (bao gồm cả sản phẩm của danh mục con)
      final products =
          await _productService.getProductsByParentCategory(widget.categoryId);
      print('✅ Found ${products.length} products');

      if (mounted) {
        setState(() {
          _subcategories = subcategories;
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading category data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterBySubcategory(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
      if (subcategoryId == null) {
        // Hiển thị tất cả
        _filteredProducts = _allProducts;
      } else {
        // Lọc theo danh mục con
        _filteredProducts = _allProducts
            .where((product) => product.categoryId == subcategoryId)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: defaultPadding),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Hiển thị danh mục con nếu có
        if (_subcategories.isNotEmpty) _buildSubcategoryFilter(),

        // Hiển thị sản phẩm
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: defaultPadding),
                      Text(
                        'Không có sản phẩm nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(defaultPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: defaultPadding,
                    mainAxisSpacing: defaultPadding,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(
                      product: product,
                      press: () {
                        Navigator.pushNamed(
                          context,
                          productDetailScreenRoute,
                          arguments: product.id,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh mục con',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: defaultPadding / 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chip "Tất cả"
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedSubcategoryId == null,
                    onSelected: (selected) {
                      if (selected) {
                        _filterBySubcategory(null);
                      }
                    },
                    selectedColor: cellphoneZRed.withOpacity(0.2),
                    checkmarkColor: cellphoneZRed,
                  ),
                ),
                // Các chip danh mục con
                ..._subcategories.map((subcategory) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(subcategory.name),
                      selected: _selectedSubcategoryId == subcategory.id,
                      onSelected: (selected) {
                        if (selected) {
                          _filterBySubcategory(subcategory.id);
                        }
                      },
                      selectedColor: cellphoneZRed.withOpacity(0.2),
                      checkmarkColor: cellphoneZRed,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
