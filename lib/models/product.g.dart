// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String,
      isAvailable: json['is_available'] as bool,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'category_id': instance.categoryId,
      'is_available': instance.isAvailable,
    };

_$ProductWithCategoryImpl _$$ProductWithCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductWithCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String,
      isAvailable: json['is_available'] as bool,
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProductWithCategoryImplToJson(
        _$ProductWithCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'category_id': instance.categoryId,
      'is_available': instance.isAvailable,
      'category': instance.category,
    };

_$ProductDraftImpl _$$ProductDraftImplFromJson(Map<String, dynamic> json) =>
    _$ProductDraftImpl(
      id: json['id'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      isAvailable: json['is_available'] as bool,
    );

Map<String, dynamic> _$$ProductDraftImplToJson(_$ProductDraftImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'category_id': instance.categoryId,
      'is_available': instance.isAvailable,
    };
