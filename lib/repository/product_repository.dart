import '../common/app_logger.dart';
import '../models/product.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository {
  ProductRepository({
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger.instance;

  final AppLogger _logger;

  @override
  String get tableName => productsSchema.table;

  Future<List<Product>> getAllProducts() async {
    try {
      final data = await getAll();
      return _parseProducts(data);
    } catch (error, stackTrace) {
      _logger.e('Failed to fetch products', error, stackTrace);
      throw Exception('Failed to fetch products: $error');
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final data = await getById(id);
      if (data == null) {
        return null;
      }
      return Product.fromJson(data);
    } catch (error, stackTrace) {
      _logger.e('Failed to fetch product $id', error, stackTrace);
      throw Exception('Failed to fetch product: $error');
    }
  }

  Future<Product> createProduct(ProductDraft draft) async {
    try {
      final payload = draft.toPayload();
      final data = await create(payload);
      return Product.fromJson(data);
    } catch (error, stackTrace) {
      _logger.e('Failed to create product', error, stackTrace);
      throw Exception('Failed to create product: $error');
    }
  }

  Future<Product> updateProduct(String id, ProductDraft draft) async {
    try {
      final payload = draft.toPayload();
      final data = await update(id, payload);
      return Product.fromJson(data);
    } catch (error, stackTrace) {
      _logger.e('Failed to update product $id', error, stackTrace);
      throw Exception('Failed to update product: $error');
    }
  }

  Future<Product> updateProductAvailability(String id, bool isAvailable) async {
    try {
      final data = await update(id, {
        productsSchema.isAvailable: isAvailable,
      });
      return Product.fromJson(data);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to update availability for product $id',
        error,
        stackTrace,
      );
      throw Exception('Failed to update product availability: $error');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await delete(id);
    } catch (error, stackTrace) {
      _logger.e('Failed to delete product $id', error, stackTrace);
      throw Exception('Failed to delete product: $error');
    }
  }

  Future<List<Product>> getProductsByParentCategory(String parentId) async {
    try {
      _logger.d('Fetching products by parent category: $parentId');

      final response = await client
          .from(categoriesSchema.table)
          .select(categoriesSchema.id)
          .eq(categoriesSchema.parentId, parentId);

      final subcategoryRows = List<Map<String, dynamic>>.from(response);
      if (subcategoryRows.isEmpty) {
        return getProductsByCategory(parentId);
      }

      final ids = subcategoryRows
          .map((row) => row[categoriesSchema.id] as String)
          .toList();

      final productsResponse = await client
          .from(tableName)
          .select()
          .inFilter(productsSchema.categoryId, ids)
          .eq(productsSchema.isAvailable, true);

      return _parseProducts(productsResponse);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to fetch products by parent category $parentId',
        error,
        stackTrace,
      );
      throw Exception('Failed to fetch products by parent category: $error');
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .eq(productsSchema.categoryId, categoryId)
          .eq(productsSchema.isAvailable, true);

      return _parseProducts(response);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to fetch products for category $categoryId',
        error,
        stackTrace,
      );
      throw Exception('Failed to fetch products by category: $error');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final normalized = query.trim();
      if (normalized.isEmpty) {
        return getAllProducts();
      }

      final orStatement =
          '${productsSchema.name}.ilike.%$normalized%,${productsSchema.description}.ilike.%$normalized%';

      final response = await queryBuilder
          .select()
          .or(orStatement)
          .eq(productsSchema.isAvailable, true);

      return _parseProducts(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to search products', error, stackTrace);
      throw Exception('Failed to search products: $error');
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await queryBuilder
          .select()
          .eq(productsSchema.isAvailable, true)
          .order(productsSchema.price, ascending: false)
          .limit(limit);

      return _parseProducts(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to fetch featured products', error, stackTrace);
      throw Exception('Failed to fetch featured products: $error');
    }
  }

  List<Product> _parseProducts(dynamic response) {
    final data = List<Map<String, dynamic>>.from(response as List);
    return data.map(Product.fromJson).toList();
  }
}
