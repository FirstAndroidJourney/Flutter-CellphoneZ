import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category.dart';
import 'package:shop/repository/category_repository.dart';
import 'package:shop/screens/shop/blocs/product_list_bloc.dart';
import 'package:shop/screens/shop/blocs/product_list_event.dart';

class CategoryFilter extends StatefulWidget {
  const CategoryFilter({Key? key}) : super(key: key);

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  final CategoryRepository _categoryRepository = GetIt.I<CategoryRepository>();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    // Dispatch event to BLoC
    context.read<ProductListBloc>().add(FilterByCategory(categoryId));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        itemCount: _categories.length + 1, // +1 for "All Products"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Products" chip
            return _buildCategoryChip(
              label: 'Tất cả',
              isSelected: _selectedCategoryId == null,
              onTap: () => _onCategorySelected(null),
            );
          }

          final category = _categories[index - 1];
          return _buildCategoryChip(
            label: category.name,
            isSelected: _selectedCategoryId == category.id,
            onTap: () => _onCategorySelected(category.id),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: defaultPadding / 2),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding / 2,
        ),
      ),
    );
  }
}
