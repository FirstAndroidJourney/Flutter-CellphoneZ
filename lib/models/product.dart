import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shop/models/category.dart';
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
}

@freezed
class ProductCreateRequest with _$ProductCreateRequest {
  const factory ProductCreateRequest({
    required String name,
    required double price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
  }) = _ProductCreateRequest;

  factory ProductCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProductCreateRequestFromJson(json);
}

@freezed
class ProductUpdateRequest with _$ProductUpdateRequest {
  @JsonSerializable(includeIfNull: false)
  const factory ProductUpdateRequest({
    String? name,
    double? price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'is_available') bool? isAvailable,
  }) = _ProductUpdateRequest;

  factory ProductUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProductUpdateRequestFromJson(json);
}

@freezed
class ProductWithCategory with _$ProductWithCategory {
  const factory ProductWithCategory({
    required String id,
    required String name,
    required double price,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @Default(null) Category? category,
  }) = _ProductWithCategory;

  factory ProductWithCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductWithCategoryFromJson(json);
}
