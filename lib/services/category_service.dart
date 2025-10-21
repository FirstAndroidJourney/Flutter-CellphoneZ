import 'package:shop/models/category.dart';
import 'package:shop/repository/category_repository.dart';

class CategoryService {
  final CategoryRepository _repository = CategoryRepository();

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    return await _repository.getAllCategories();
  }

  // Get root categories
  Future<List<Category>> getRootCategories() async {
    return await _repository.getRootCategories();
  }

  // Get subcategories by parent ID
  Future<List<Category>> getSubcategories(String parentId) async {
    return await _repository.getSubcategories(parentId);
  }

  // Get category tree with root categories and their children
  Future<List<CategoryWithChildren>> getCategoryTree() async {
    return await _repository.getCategoryTree();
  }

  // Get category by ID
  Future<Category?> getCategoryById(String id) async {
    return await _repository.getCategoryById(id);
  }

  // Convert database Category model to UI CategoryModel for backwards compatibility
  CategoryModel convertToUiModel(
      Category category, List<Category> subcategories) {
    return CategoryModel(
      id: category.id,
      title: category.name,
      // Default SVG source based on category name or assign based on some convention
      svgSrc: _getSvgSrcForCategory(category.name),
      subCategories: subcategories
          .map((sub) => CategoryModel(
                id: sub.id,
                title: sub.name,
              ))
          .toList(),
    );
  }

  // Helper method to get appropriate SVG icon for a category
  String _getSvgSrcForCategory(String categoryName) {
    // Simple mapping based on category name
    // You may want to store this info in the database instead for a production app
    final name = categoryName.toLowerCase();

    if (name.contains('sale') || name.contains('discount')) {
      return "assets/icons/Sale.svg";
    } else if (name.contains('man') ||
        name.contains('woman') ||
        name.contains("men") ||
        name.contains("women")) {
      return "assets/icons/Man&Woman.svg";
    } else if (name.contains('kid') || name.contains('child')) {
      return "assets/icons/Child.svg";
    } else if (name.contains('accessory') || name.contains('accessories')) {
      return "assets/icons/Accessories.svg";
    }
    // Default icon
    return "assets/icons/Category.svg";
  }
}

// UI-friendly model that matches the current UI expectations
class CategoryModel {
  final String id;
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.id,
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}
