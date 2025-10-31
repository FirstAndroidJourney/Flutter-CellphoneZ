import 'package:flutter_test/flutter_test.dart';
import 'package:shop/services/storage_service.dart';

void main() {
  group('StorageService.extractPathFromPublicUrl', () {
    test('returns null for null or empty input', () {
      expect(StorageService.extractPathFromPublicUrl(null), isNull);
      expect(StorageService.extractPathFromPublicUrl(''), isNull);
    });

    test('returns null when url does not contain bucket marker', () {
      const url = 'https://example.com/some/other/path.png';
      expect(StorageService.extractPathFromPublicUrl(url), isNull);
    });

    test('extracts path for product-images bucket', () {
      const url =
          'https://project.supabase.co/storage/v1/object/public/product-images/products/123/file.png';
      expect(
        StorageService.extractPathFromPublicUrl(url),
        'products/123/file.png',
      );
    });
  });
}
