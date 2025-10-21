import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  /// Safe factory constructor that handles potential null or missing fields
  static Product? safeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      // Handle ID field which is required
      final id = json['id']?.toString() ?? '';
      if (id.isEmpty) return null;

      // Handle name field which is required
      final name = json['name']?.toString() ?? '';
      if (name.isEmpty) return null;

      // Handle price field which is required
      final priceRaw = json['price'];
      final double price = priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw?.toString() ?? '0') ?? 0;

      // Handle categoryId field which is required
      final categoryId = json['category_id']?.toString() ?? '';
      if (categoryId.isEmpty) return null;

      return Product(
        id: id,
        name: name,
        price: price,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        categoryId: categoryId,
        isAvailable: json['is_available'] as bool? ?? true,
      );
    } catch (e) {
      print('Error parsing Product: $e');
      print('Problematic JSON: $json');
      return null;
    }
  }
}
