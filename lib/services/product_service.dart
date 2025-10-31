import 'dart:io';

import '../repository/product_repository.dart';
import '../models/product.dart';
import 'dependency_injection.dart';
import 'storage_service.dart';

class ProductService {
  late final ProductRepository _productRepository;
  late final StorageService _storageService;

  ProductService() {
    try {
      _productRepository = getIt<ProductRepository>();
      _storageService = getIt<StorageService>();
      print('ProductService: Repositories retrieved successfully');
    } catch (e) {
      print('ProductService: Error getting repositories: $e');
      rethrow;
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      return await _productRepository.getAllProducts();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      return await _productRepository.getProductById(id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      return await _productRepository.getProductsByCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  Future<List<Product>> getProductsByParentCategory(String parentId) async {
    try {
      return await _productRepository.getProductsByParentCategory(parentId);
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllProducts();
      }
      return await _productRepository.searchProducts(query);
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      return await _productRepository.getFeaturedProducts(limit: limit);
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // Create product (admin function)
  Future<Product> createProduct({
    required String name,
    required double price,
    required String categoryId,
    String? description,
    String? imageUrl,
    String? localImagePath,
  }) async {
    try {
      final request = ProductCreateRequest(
        name: name.trim(),
        price: price,
        categoryId: categoryId,
        description: _normalizeNullable(description),
        imageUrl: _normalizeNullable(imageUrl),
      );

      final product = await _productRepository.createProduct(request);

      if (localImagePath != null && localImagePath.isNotEmpty) {
        final file = File(localImagePath);
        if (file.existsSync()) {
          final uploadResult = await _storageService.uploadProductImage(
            productId: product.id,
            file: file,
          );
          final updatedProduct = await _productRepository.updateProduct(
            product.id,
            ProductUpdateRequest(imageUrl: uploadResult.publicUrl),
          );
          return updatedProduct;
        }
      }

      return product;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product (admin function)
  Future<Product> updateProduct(
    String id, {
    String? name,
    double? price,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    String? localImagePath,
    String? previousImageUrl,
  }) async {
    try {
      final normalizedImageUrl = _normalizeNullable(imageUrl);
      StorageFileReference? uploadResult;
      String? finalImageUrl = normalizedImageUrl;
      if (localImagePath != null && localImagePath.isNotEmpty) {
        final file = File(localImagePath);
        if (file.existsSync()) {
          uploadResult = await _storageService.uploadProductImage(
            productId: id,
            file: file,
          );
          finalImageUrl = uploadResult.publicUrl;
        }
      }

      final request = ProductUpdateRequest(
        name: name?.trim(),
        price: price,
        categoryId: categoryId,
        description: _normalizeNullable(description),
        imageUrl: finalImageUrl,
        isAvailable: isAvailable,
      );

      final payload = request.toJson();
      if (payload.isEmpty) {
        throw Exception('No fields provided to update product $id');
      }

      final updatedProduct = await _productRepository.updateProduct(id, request);

      if (uploadResult != null) {
        final previousPath =
            StorageService.extractPathFromPublicUrl(previousImageUrl);
        if (previousPath != null) {
          await _storageService.deleteProductImage(previousPath);
        }
      }

      return updatedProduct;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (admin function)
  Future<void> deleteProduct(String id) async {
    try {
      await _productRepository.deleteProduct(id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by price range
  Future<List<Product>> getProductsByPriceRange({
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final products = await getAllProducts();

      return products.where((product) {
        if (minPrice != null && product.price < minPrice) return false;
        if (maxPrice != null && product.price > maxPrice) return false;
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter products by price: $e');
    }
  }

  // Get related products (products in same category)
  Future<List<Product>> getRelatedProducts(String productId,
      {int limit = 5}) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        return [];
      }

      // Get products from same category
      final categoryProducts =
          await _productRepository.getProductsByCategory(product.categoryId);

      // Filter out the current product
      final relatedProducts =
          categoryProducts.where((p) => p.id != productId).toList();

      // Limit the number of products
      if (relatedProducts.length > limit) {
        return relatedProducts.sublist(0, limit);
      }

      return relatedProducts;
    } catch (e) {
      throw Exception('Failed to fetch related products: $e');
    }
  }

  // Sort products
  List<Product> sortProducts(List<Product> products, ProductSortBy sortBy) {
    switch (sortBy) {
      case ProductSortBy.nameAsc:
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortBy.nameDesc:
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortBy.priceAsc:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortBy.priceDesc:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return products;
  }

  String? _normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum ProductSortBy {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}
