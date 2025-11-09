import 'package:freezed_annotation/freezed_annotation.dart';
part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String slug,
    required double price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'is_available') required bool isAvailable,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
class ProductDraft with _$ProductDraft {
  const factory ProductDraft({
    String? id,
    required String name,
    required double price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? imageStoragePath,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'is_available') required bool isAvailable,
  }) = _ProductDraft;

  const ProductDraft._();

  factory ProductDraft.fromJson(Map<String, dynamic> json) =>
      _$ProductDraftFromJson(json);

  Map<String, dynamic> toPayload() {
    final data = <String, dynamic>{
      'name': name.trim(),
      'price': price,
      'description': description?.trim(),
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_available': isAvailable,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
