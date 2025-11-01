import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category.dart';
import 'package:shop/screens/category/views/category_screen.dart';
import 'package:shop/services/category_service.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<Category> _rootCategories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRootCategories();
  }

  Future<void> _loadRootCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Loading root categories...');
      final categories = await _categoryService.getRootCategories();
      print('✅ Loaded ${categories.length} root categories');

      for (var cat in categories) {
        print('  📁 ${cat.name} (id: ${cat.id}, parent: ${cat.parentId})');
      }

      if (mounted) {
        setState(() {
          _rootCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading root categories: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải danh mục: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục sản phẩm'),
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
              onPressed: _loadRootCategories,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_rootCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: defaultPadding),
            Text(
              'Chưa có danh mục nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
      ),
      itemCount: _rootCategories.length,
      itemBuilder: (context, index) {
        final category = _rootCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: cellphoneZRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                size: 36,
                color: cellphoneZRed,
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('điện thoại') || name.contains('phone')) {
      return Icons.smartphone;
    } else if (name.contains('laptop') || name.contains('máy tính')) {
      return Icons.laptop;
    } else if (name.contains('tivi') || name.contains('tv')) {
      return Icons.tv;
    } else if (name.contains('phụ kiện') || name.contains('accessory')) {
      return Icons.headphones;
    } else if (name.contains('tablet') || name.contains('máy tính bảng')) {
      return Icons.tablet;
    } else if (name.contains('đồng hồ') || name.contains('watch')) {
      return Icons.watch;
    }
    return Icons.category;
  }
}
