import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'is_popular') @Default(false) bool isPopular,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
class CategoryCreateRequest with _$CategoryCreateRequest {
  const factory CategoryCreateRequest({
    required String name,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'is_popular') @Default(false) bool isPopular,
  }) = _CategoryCreateRequest;

  factory CategoryCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$CategoryCreateRequestFromJson(json);
}
