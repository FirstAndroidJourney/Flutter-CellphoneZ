import 'package:flutter/widgets.dart';

import '../models/product.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository {
  @override
  String get tableName => productsSchema.table;

  // Get all products as Product objects
  Future<List<Product>> getAllProducts() async {
    try {
      final data = await getAll();
      // Use the safer parsing method and filter out nulls
      return data
          .map((json) => Product.fromJson(json))
          .where((product) => product != null)
          .cast<Product>()
          .toList();
    } catch (e) {
      print('Error in getAllProducts: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final data = await getById(id);
      // Use the safer parsing method
      if (data == null) {
        return null;
      }
      return Product.fromJson(data);
    } catch (e) {
      print('Error in getProductById: $e');
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Create new product
  Future<Product> createProduct(Product product) async {
    try {
      final data = await create(product.toJson());

      // Use the safe parser to handle potential issues
      final createdProduct = Product.fromJson(data);
      if (createdProduct == null) {
        throw Exception('Created product returned invalid data');
      }
      return createdProduct;
    } catch (e) {
      print('Error in createProduct: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final data = await update(id, product.toJson());

      // Use the safe parser to handle potential issues
      final updatedProduct = Product.fromJson(data);
      if (updatedProduct == null) {
        throw Exception('Updated product returned invalid data');
      }
      return updatedProduct;
    } catch (e) {
      print('Error in updateProduct: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await delete(id);
    } catch (e) {
      print('Error in deleteProduct: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await queryBuilder
          .select()
          .eq(productsSchema.categoryId, categoryId)
          .eq(productsSchema.isAvailable, true);

      final data = List<Map<String, dynamic>>.from(response);

      // Use the safer parsing method and filter out nulls
      return data
          .map((json) => Product.fromJson(json))
          .where((product) => product != null)
          .cast<Product>()
          .toList();
    } catch (e) {
      print('Error in getProductsByCategory: $e');
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Sử dụng productsSchema để truy cập tên trường
      String searchQuery =
          '${productsSchema.name}.ilike.%$query%,${productsSchema.description}.ilike.%$query%';
      final response = await queryBuilder
          .select()
          .or(searchQuery)
          .eq(productsSchema.isAvailable, true);

      final data = List<Map<String, dynamic>>.from(response);
      // Use the safer parsing method and filter out nulls
      return data
          .map((json) => Product.fromJson(json))
          .where((product) => product != null)
          .cast<Product>()
          .toList();
    } catch (e) {
      print('Error in searchProducts: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  // Get featured products (example: top 10 by price)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      debugPrint('Fetching featured products with limit: $limit');
      final response = await queryBuilder
          .select()
          .eq(productsSchema.isAvailable, true)
          .order(productsSchema.price, ascending: false)
          .limit(limit);

      // Print the raw response for debugging
      debugPrint('Featured products raw response: $response');

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('Fetched ${data.length} featured products.');

      // Use the safer parsing method and filter out nulls
      final products = data
          .map((json) => Product.fromJson(json))
          .where((product) => product != null)
          .cast<Product>()
          .toList();

      debugPrint('Successfully parsed ${products.length} valid products');
      return products;
    } catch (e) {
      debugPrint('Error in getFeaturedProducts: $e');
      throw Exception('Failed to fetch featured products: $e');
    }
  }
}
