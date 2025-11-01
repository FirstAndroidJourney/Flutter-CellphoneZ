import 'package:flutter/widgets.dart';

import '../models/category.dart';
import 'base_repository.dart';

class CategoryRepository extends BaseRepository {
  @override
  String get tableName => categoriesSchema.table;

  // Get featured categories (is_popular = true)
  Future<List<Category>> getFeaturedCategories() async {
    try {
      final response =
          await client.from(tableName).select().eq('is_popular', true);

      debugPrint('Fetched featured categories: $response');
      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching featured categories: $e');
      throw Exception('Failed to fetch featured categories: $e');
    }
  }

  // Get all categories as Category objects
  Future<List<Category>> getAllCategories() async {
    try {
      final data = await getAll();
      debugPrint('Fetched categories: ${data.length} items');
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? Category.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // Create new category
  Future<Category> createCategory(CategoryCreateRequest category) async {
    try {
      debugPrint('Creating category: ${category.toJson()}');
      final data = await create(category.toJson());
      return Category.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  Future<Category> updateCategory(String id, Category category) async {
    try {
      final data = await update(id, category.toJson());
      return Category.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Get root categories (parentId is null)
  Future<List<Category>> getRootCategories() async {
    try {
      debugPrint('🔄 Fetching root categories (parent_id = null)...');

      // Gọi trực tiếp từ Supabase thay vì getAll() nếu muốn hiệu năng cao hơn
      final response = await client
          .from(tableName)
          .select()
          .isFilter('parent_id', null); // 🔥 lọc trực tiếp ở DB

      final List data = response as List;
      debugPrint('📊 Found ${data.length} root categories');

      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getRootCategories: $e');
      debugPrint('$stackTrace');
      throw Exception('Failed to fetch root categories: $e');
    }
  }

  // Get subcategories by parent ID
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      debugPrint('🔄 Querying subcategories for parent: $parentId');
      final response =
          await client.from(tableName).select().eq('parent_id', parentId);

      debugPrint('✅ Subcategories response: $response');
      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('📊 Found ${data.length} subcategories');
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getSubcategories: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch subcategories: $e');
    }
  }

  // Get category tree (root categories with their subcategories)
  Future<List<CategoryWithChildren>> getCategoryTree() async {
    try {
      // First get all categories
      final allCategories = await getAllCategories();

      // Build the tree structure
      final Map<String, List<Category>> childrenMap = {};
      final List<Category> rootCategories = [];

      for (final category in allCategories) {
        if (category.parentId == null) {
          rootCategories.add(category);
        } else {
          childrenMap.putIfAbsent(category.parentId!, () => []);
          childrenMap[category.parentId!]!.add(category);
        }
      }

      return rootCategories
          .map((root) => CategoryWithChildren(
                category: root,
                children: childrenMap[root.id] ?? [],
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to build category tree: $e');
    }
  }
}

// Helper class for category tree
class CategoryWithChildren {
  final Category category;
  final List<Category> children;

  CategoryWithChildren({
    required this.category,
    required this.children,
  });
}
