import '../models/product.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository {
  @override
  String get tableName => 'products';

  // Get all products as Product objects
  Future<List<Product>> getAllProducts() async {
    try {
      final data = await getAll();
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? Product.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Create new product
  Future<Product> createProduct(Product product) async {
    try {
      final data = await create(product.toJson());
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final data = await update(id, product.toJson());
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('categoryId', categoryId)
          .eq('isAvailable', true);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await queryBuilder
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('isAvailable', true);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get featured products (example: top 10 by price)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('isAvailable', true)
          .order('price', ascending: false)
          .limit(limit);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }
}
