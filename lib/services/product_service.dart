import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as img;

import '../common/app_logger.dart';
import '../models/product.dart';
import '../repository/product_repository.dart';
import 'database_schema.dart';
import 'dependency_injection.dart';
import 'storage_service.dart';

class ProductService {
  ProductService({
    ProductRepository? productRepository,
    StorageService? storageService,
    AppLogger? logger,
  })  : _productRepository =
            productRepository ?? getIt<ProductRepository>(),
        _storageService = storageService ?? getIt<StorageService>(),
        _logger = logger ?? AppLogger.instance;

  final ProductRepository _productRepository;
  final StorageService _storageService;
  final AppLogger _logger;
  final StorageBuckets _storageBuckets = const StorageBuckets();

  // region: Admin CRUD

  Future<Product> createProduct({
    required String name,
    required double price,
    required bool isAvailable,
    String? description,
    String? categoryId,
    ProductImagePayload? image,
  }) async {
    _validateName(name);
    _validatePrice(price);

    StorageUploadResult? uploadResult;

    try {
      if (image != null) {
        final prepared = await _prepareImage(image);
        uploadResult = await _storageService.uploadProductImage(
          prepared.bytes,
          extension: prepared.extension,
        );
      }

      final draft = ProductDraft(
        name: name,
        price: price,
        description: description?.trim(),
        imageUrl: uploadResult?.publicUrl,
        imageStoragePath: uploadResult?.storagePath,
        categoryId: categoryId,
        isAvailable: isAvailable,
      );

      final product = await _productRepository.createProduct(draft);
      return product;
    } catch (error, stackTrace) {
      _logger.e('Create product failed', error, stackTrace);

      if (uploadResult != null) {
        await _safeRemoveImage(uploadResult.storagePath);
      }

      throw Exception('Failed to create product: $error');
    }
  }

  Future<Product> updateProduct({
    required Product current,
    required String name,
    required double price,
    required bool isAvailable,
    String? description,
    String? categoryId,
    ProductImagePayload? newImage,
  }) async {
    _validateName(name);
    _validatePrice(price);

    StorageUploadResult? uploadResult;
    final String? previousStoragePath =
        _extractStoragePath(current.imageUrl ?? '');

    try {
      if (newImage != null) {
        final prepared = await _prepareImage(newImage);
        uploadResult = await _storageService.uploadProductImage(
          prepared.bytes,
          productId: current.id,
          extension: prepared.extension,
        );
      }

      final draft = ProductDraft(
        name: name,
        price: price,
        description: description?.trim(),
        imageUrl: newImage != null ? uploadResult?.publicUrl : null,
        imageStoragePath: uploadResult?.storagePath,
        categoryId: categoryId,
        isAvailable: isAvailable,
      );

      final result =
          await _productRepository.updateProduct(current.id, draft);

      if (uploadResult != null && previousStoragePath != null) {
        await _safeRemoveImage(previousStoragePath);
      }

      return result;
    } catch (error, stackTrace) {
      _logger.e('Update product ${current.id} failed', error, stackTrace);

      if (uploadResult != null) {
        await _safeRemoveImage(uploadResult.storagePath);
      }

      throw Exception('Failed to update product: $error');
    }
  }

  Future<void> updateProductAvailability(
    Product product,
    bool isAvailable,
  ) async {
    try {
      await _productRepository.updateProductAvailability(
        product.id,
        isAvailable,
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Update availability for product ${product.id} failed',
        error,
        stackTrace,
      );
      throw Exception('Failed to change product availability: $error');
    }
  }

  // endregion

  // region: Public product APIs

  Future<List<Product>> getAllProducts() async {
    try {
      return await _productRepository.getAllProducts();
    } catch (error) {
      throw Exception('Failed to fetch products: $error');
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      return await _productRepository.getProductById(id);
    } catch (error) {
      throw Exception('Failed to fetch product: $error');
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      return await _productRepository.getProductsByCategory(categoryId);
    } catch (error) {
      throw Exception('Failed to fetch products by category: $error');
    }
  }

  Future<List<Product>> getProductsByParentCategory(String parentId) async {
    try {
      return await _productRepository.getProductsByParentCategory(parentId);
    } catch (error) {
      throw Exception('Failed to fetch products by category: $error');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      return await _productRepository.searchProducts(query);
    } catch (error) {
      throw Exception('Failed to search products: $error');
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      return await _productRepository.getFeaturedProducts(limit: limit);
    } catch (error) {
      throw Exception('Failed to fetch featured products: $error');
    }
  }

  Future<List<Product>> getProductsByPriceRange({
    double? minPrice,
    double? maxPrice,
  }) async {
    final products = await getAllProducts();

    return products.where((product) {
      if (minPrice != null && product.price < minPrice) {
        return false;
      }
      if (maxPrice != null && product.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<Product>> getRelatedProducts(
    String productId, {
    int limit = 5,
  }) async {
    final product = await getProductById(productId);
    if (product == null) {
      return [];
    }

    final categoryProducts =
        await _productRepository.getProductsByCategory(product.categoryId);

    final related =
        categoryProducts.where((p) => p.id != productId).toList();

    return related.length > limit
        ? related.sublist(0, limit)
        : related;
  }

  // endregion

  // region: Helpers

  void _validateName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Product name must not be empty');
    }
  }

  void _validatePrice(double price) {
    if (price <= 0) {
      throw ArgumentError('Product price must be greater than zero');
    }
  }

  Future<_PreparedImage> _prepareImage(ProductImagePayload image) async {
    try {
      final decoded = img.decodeImage(image.bytes);
      if (decoded == null) {
        return _PreparedImage(bytes: image.bytes, extension: image.extension);
      }

      const maxDimension = 1280;
      img.Image processed = decoded;

      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        processed = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
        );
      }

      late final List<int> encoded;
      final ext = image.extension.toLowerCase();
      if (ext == 'png') {
        encoded = img.encodePng(processed);
      } else {
        encoded = img.encodeJpg(processed, quality: 85);
      }

      return _PreparedImage(
        bytes: Uint8List.fromList(encoded),
        extension: ext == 'png' ? 'png' : 'jpg',
      );
    } catch (error, stackTrace) {
      _logger.w('Image compression failed, using original bytes',
          error, stackTrace);
      return _PreparedImage(bytes: image.bytes, extension: image.extension);
    }
  }

  String? _extractStoragePath(String? publicUrl) {
    if (publicUrl == null || publicUrl.isEmpty) {
      return null;
    }

    final marker = '/object/public/${_storageBuckets.productImages}/';
    final index = publicUrl.indexOf(marker);

    if (index == -1) {
      return null;
    }

    return publicUrl.substring(index + marker.length);
  }

  Future<void> _safeRemoveImage(String storagePath) async {
    try {
      await _storageService.removeProductImage(storagePath);
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to clean up image at $storagePath',
        error,
        stackTrace,
      );
    }
  }

  // endregion
}

class ProductImagePayload extends Equatable {
  ProductImagePayload({
    required this.bytes,
    required String extension,
  }) : extension = extension.replaceAll('.', '').toLowerCase();

  final Uint8List bytes;
  final String extension;

  @override
  List<Object?> get props => [bytes, extension];
}

class _PreparedImage {
  _PreparedImage({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}
