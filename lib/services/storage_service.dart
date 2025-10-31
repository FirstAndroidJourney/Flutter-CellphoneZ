import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../clients/database_client.dart';
import 'database_schema.dart';

class StorageFileReference {
  StorageFileReference({
    required this.path,
    required this.publicUrl,
  });

  final String path;
  final String publicUrl;
}

class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? DatabaseClient.instance.client,
        _bucket = StorageBuckets().productImages;

  final SupabaseClient _client;
  final String _bucket;

  SupabaseStorageClient get _storage => _client.storage;

  /// Upload a product image and return storage metadata.
  Future<StorageFileReference> uploadProductImage({
    required String productId,
    required File file,
    bool upsert = true,
  }) async {
    final fileName = _buildFileName(productId, file);
    final path = 'products/$productId/$fileName';

    final response = await _storage.from(_bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: upsert,
          ),
        );

    if (response.isEmpty) {
      throw Exception('Failed to upload product image');
    }

    final publicUrl = _storage.from(_bucket).getPublicUrl(response);
    return StorageFileReference(path: response, publicUrl: publicUrl);
  }

  /// Remove a product image from storage.
  Future<void> deleteProductImage(String path) async {
    if (path.isEmpty) return;
    await _storage.from(_bucket).remove([path]);
  }

  /// Try to derive the storage path from a public URL.
  static String? extractPathFromPublicUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final bucket = StorageBuckets().productImages;
    final marker = '/object/public/$bucket/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    return url.substring(index + marker.length);
  }

  /// Build a deterministic file name using product id and original extension.
  String _buildFileName(String productId, File file) {
    final ext = p.extension(file.path);
    final sanitizedExt = ext.isEmpty ? '.jpg' : ext.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${productId}_$timestamp$sanitizedExt';
  }
}
