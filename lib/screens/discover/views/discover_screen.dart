import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/category_service.dart';
import 'package:shop/screens/search/views/components/search_form.dart';

import 'components/expansion_category.dart';
import 'components/discover_categories_skeleton.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get category tree from repository via service
      final categoryTree = await _categoryService.getCategoryTree();

      // Convert to UI models
      final uiCategories = categoryTree.map((categoryWithChildren) {
        return _categoryService.convertToUiModel(
            categoryWithChildren.category, categoryWithChildren.children);
      }).toList();

      setState(() {
        _categories = uiCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories: $e';
      });
      // For development - print the error to console
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: SearchForm(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Categories",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!_isLoading && _errorMessage != null)
                    IconButton(
                      icon: Icon(Icons.refresh, size: 20),
                      onPressed: _loadCategories,
                      tooltip: 'Retry',
                    ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: DiscoverCategoriesSkeleton(),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _categories.isEmpty
                      ? Center(child: Text('No categories found'))
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) => ExpansionCategory(
                            svgSrc: _categories[index].svgSrc ??
                                "assets/icons/Category.svg",
                            title: _categories[index].title,
                            subCategory: _categories[index].subCategories ?? [],
                            categoryId: _categories[index].id,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
