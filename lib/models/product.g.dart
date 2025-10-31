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
      isAvailable: json['is_available'] as bool? ?? true,
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

_$ProductCreateRequestImpl _$$ProductCreateRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductCreateRequestImpl(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProductCreateRequestImplToJson(
        _$ProductCreateRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'category_id': instance.categoryId,
      'is_available': instance.isAvailable,
    };

_$ProductUpdateRequestImpl _$$ProductUpdateRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductUpdateRequestImpl(
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      isAvailable: json['is_available'] as bool?,
    );

Map<String, dynamic> _$$ProductUpdateRequestImplToJson(
        _$ProductUpdateRequestImpl instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.price case final value?) 'price': value,
      if (instance.description case final value?) 'description': value,
      if (instance.imageUrl case final value?) 'image_url': value,
      if (instance.categoryId case final value?) 'category_id': value,
      if (instance.isAvailable case final value?) 'is_available': value,
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
      isAvailable: json['is_available'] as bool? ?? true,
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
