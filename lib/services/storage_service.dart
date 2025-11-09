import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../common/app_logger.dart';
import 'database_schema.dart';

class StorageService {
  StorageService({
    SupabaseClient? client,
    AppLogger? logger,
    String? productBucket,
  })  : _client = client ?? Supabase.instance.client,
        _logger = logger ?? AppLogger.instance,
        _productBucket = productBucket ?? const StorageBuckets().productImages;

  final SupabaseClient _client;
  final AppLogger _logger;
  final String _productBucket;

  /// Uploads a product image and returns both the storage path and the public URL.
  Future<StorageUploadResult> uploadProductImage(
    Uint8List bytes, {
    String? productId,
    String extension = 'jpg',
    FileOptions? options,
  }) async {
    final String folder = productId == null || productId.isEmpty
        ? 'drafts'
        : 'products/$productId';
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$extension';
    final String storagePath = p.posix.join(folder, fileName);

    final FileOptions resolvedOptions = options ??
        const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'image/jpeg',
        );

    try {
      _logger.d('Uploading product image to $storagePath');
      await _client.storage
          .from(_productBucket)
          .uploadBinary(storagePath, bytes, fileOptions: resolvedOptions);

      final String publicUrl =
          _client.storage.from(_productBucket).getPublicUrl(storagePath);

      _logger.d('Upload completed for $storagePath');
      return StorageUploadResult(
        storagePath: storagePath,
        publicUrl: publicUrl,
      );
    } on StorageException catch (error, stackTrace) {
      _logger.e(
        'Upload failed for $storagePath',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Removes an existing product image from storage.
  Future<void> removeProductImage(String storagePath) async {
    if (storagePath.isEmpty) {
      return;
    }

    try {
      _logger.d('Removing product image at $storagePath');
      await _client.storage.from(_productBucket).remove([storagePath]);
    } on StorageException catch (error, stackTrace) {
      _logger.e(
        'Failed to remove image at $storagePath',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Generates the public URL for a stored product image.
  String getPublicUrl(String storagePath) {
    return _client.storage.from(_productBucket).getPublicUrl(storagePath);
  }

  /// Check if bucket exists and is accessible
  Future<bool> checkBucketAccess() async {
    try {
      await _client.storage.from(_productBucket).list();
      return true;
    } catch (error) {
      _logger.e('📸 [StorageService] Bucket access check failed', error);
      return false;
    }
  }
}

class StorageUploadResult {
  StorageUploadResult({
    required this.storagePath,
    required this.publicUrl,
  });

  final String storagePath;
  final String publicUrl;
}
