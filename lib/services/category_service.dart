import 'package:shop/models/category.dart';
import 'package:shop/repository/category_repository.dart';

class CategoryService {
  final CategoryRepository _repository = CategoryRepository();

  // Get featured/popular categories
  Future<List<Category>> getFeaturedCategories() async {
    try {
      final categories = await _repository.getFeaturedCategories();
      return categories;
    } catch (e) {
      print('Error in getFeaturedCategories: $e');
      throw Exception('Failed to fetch featured categories: $e');
    }
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    return await _repository.getAllCategories();
  }

  // Get root categories
  Future<List<Category>> getRootCategories() async {
    try {
      print('📞 CategoryService: calling getRootCategories...');
      final result = await _repository.getRootCategories();
      print('✅ CategoryService: got ${result.length} root categories');
      return result;
    } catch (e, stackTrace) {
      print('❌ CategoryService error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  // Get subcategories by parent ID
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      print('📞 CategoryService: calling getSubcategories for $parentId...');
      final result = await _repository.getSubcategories(parentId);
      print('✅ CategoryService: got ${result.length} subcategories');
      return result;
    } catch (e, stackTrace) {
      print('❌ CategoryService error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  // Get category tree with root categories and their children
  Future<List<CategoryWithChildren>> getCategoryTree() async {
    return await _repository.getCategoryTree();
  }

  // Get category by ID
  Future<Category?> getCategoryById(String id) async {
    return await _repository.getCategoryById(id);
  }

  // ==================== CRUD OPERATIONS ====================

  /// Create a new category
  /// [name] - Category name
  /// [parentId] - Optional parent category ID (null for root categories)
  /// [isPopular] - Mark as featured/popular category
  Future<Category> createCategory(
    String name, {
    String? parentId,
    bool isPopular = false,
  }) async {
    try {
      print('📝 Creating category: $name (parent: ${parentId ?? "root"})');
      final newCategory = CategoryCreateRequest(
          name: name, parentId: parentId, isPopular: isPopular);

      final created = await _repository.createCategory(newCategory);
      print('✅ Category created with ID: ${created.id}');
      return created;
    } catch (e, stackTrace) {
      print('❌ Error creating category: $e');
      print('Stack: $stackTrace');
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category
  /// [id] - Category ID to update
  /// [name] - New category name
  /// [isPopular] - Update featured status
  Future<Category> updateCategory(
    String id,
    String name, {
    bool? isPopular,
  }) async {
    try {
      print('📝 Updating category $id to: $name');

      // Fetch existing category to preserve other fields
      final existing = await _repository.getCategoryById(id);
      if (existing == null) {
        throw Exception('Category not found');
      }

      final updated = Category(
          id: id,
          name: name,
          parentId: existing.parentId,
          isPopular: isPopular ?? existing.isPopular);

      final result = await _repository.updateCategory(id, updated);
      print('✅ Category updated successfully');
      return result;
    } catch (e, stackTrace) {
      print('❌ Error updating category: $e');
      print('Stack: $stackTrace');
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  /// Note: This will fail if the category has subcategories or products
  /// Consider implementing cascade delete or preventing deletion
  Future<void> deleteCategory(String id) async {
    try {
      print('🗑️ Deleting category: $id');

      // Optional: Check if category has children
      final subcategories = await _repository.getSubcategories(id);
      if (subcategories.isNotEmpty) {
        throw Exception(
            'Cannot delete category with ${subcategories.length} subcategories. '
            'Please delete subcategories first.');
      }

      await _repository.deleteCategory(id);
      print('✅ Category deleted successfully');
    } catch (e, stackTrace) {
      print('❌ Error deleting category: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Move a category to a different parent
  Future<Category> moveCategory(String id, String? newParentId) async {
    try {
      print('🔄 Moving category $id to parent: ${newParentId ?? "root"}');

      final existing = await _repository.getCategoryById(id);
      if (existing == null) {
        throw Exception('Category not found');
      }

      // Prevent moving to itself or its own children
      if (newParentId == id) {
        throw Exception('Cannot move category to itself');
      }

      final updated = Category(
          id: id,
          name: existing.name,
          parentId: newParentId,
          isPopular: existing.isPopular);

      final result = await _repository.updateCategory(id, updated);
      print('✅ Category moved successfully');
      return result;
    } catch (e, stackTrace) {
      print('❌ Error moving category: $e');
      print('Stack: $stackTrace');
      throw Exception('Failed to move category: $e');
    }
  }

  /// Toggle featured/popular status
  Future<Category> togglePopular(String id) async {
    try {
      final existing = await _repository.getCategoryById(id);
      if (existing == null) {
        throw Exception('Category not found');
      }

      final updated = Category(
          id: id,
          name: existing.name,
          parentId: existing.parentId,
          isPopular: !existing.isPopular);

      return await _repository.updateCategory(id, updated);
    } catch (e) {
      throw Exception('Failed to toggle popular status: $e');
    }
  }

  // ==================== UI CONVERSION ====================

  /// Convert database Category model to UI CategoryModel for backwards compatibility
  CategoryModel convertToUiModel(
      Category category, List<Category> subcategories) {
    return CategoryModel(
      id: category.id,
      title: category.name,
      svgSrc: _getSvgSrcForCategory(category.name),
      subCategories: subcategories
          .map((sub) => CategoryModel(
                id: sub.id,
                title: sub.name,
                svgSrc: _getSvgSrcForCategory(sub.name),
              ))
          .toList(),
    );
  }

  /// Helper method to get appropriate SVG icon for a category
  String _getSvgSrcForCategory(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('sale') ||
        name.contains('discount') ||
        name.contains('khuyến mãi')) {
      return "assets/icons/Sale.svg";
    } else if (name.contains('man') ||
        name.contains('woman') ||
        name.contains("men") ||
        name.contains("women") ||
        name.contains('nam') ||
        name.contains('nữ')) {
      return "assets/icons/Man&Woman.svg";
    } else if (name.contains('kid') ||
        name.contains('child') ||
        name.contains('trẻ em')) {
      return "assets/icons/Child.svg";
    } else if (name.contains('accessory') ||
        name.contains('accessories') ||
        name.contains('phụ kiện')) {
      return "assets/icons/Accessories.svg";
    } else if (name.contains('phone') || name.contains('điện thoại')) {
      return "assets/icons/Phone.svg";
    } else if (name.contains('laptop') || name.contains('máy tính')) {
      return "assets/icons/Laptop.svg";
    } else if (name.contains('tablet') || name.contains('máy tính bảng')) {
      return "assets/icons/Tablet.svg";
    } else if (name.contains('watch') || name.contains('đồng hồ')) {
      return "assets/icons/Watch.svg";
    }

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
