// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  String get categoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call(
      {String id,
      String name,
      String slug,
      double price,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'category_id') String categoryId,
      @JsonKey(name: 'is_available') bool isAvailable});
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? price = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? categoryId = null,
    Object? isAvailable = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
          _$ProductImpl value, $Res Function(_$ProductImpl) then) =
      __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String slug,
      double price,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'category_id') String categoryId,
      @JsonKey(name: 'is_available') bool isAvailable});
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
      _$ProductImpl _value, $Res Function(_$ProductImpl) _then)
      : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? price = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? categoryId = null,
    Object? isAvailable = null,
  }) {
    return _then(_$ProductImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl(
      {required this.id,
      required this.name,
      required this.slug,
      required this.price,
      this.description,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(name: 'category_id') required this.categoryId,
      @JsonKey(name: 'is_available') required this.isAvailable});

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final double price;
  @override
  final String? description;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'category_id')
  final String categoryId;
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, slug: $slug, price: $price, description: $description, imageUrl: $imageUrl, categoryId: $categoryId, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, slug, price,
      description, imageUrl, categoryId, isAvailable);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(
      this,
    );
  }
}

abstract class _Product implements Product {
  const factory _Product(
          {required final String id,
          required final String name,
          required final String slug,
          required final double price,
          final String? description,
          @JsonKey(name: 'image_url') final String? imageUrl,
          @JsonKey(name: 'category_id') required final String categoryId,
          @JsonKey(name: 'is_available') required final bool isAvailable}) =
      _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  double get price;
  @override
  String? get description;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'category_id')
  String get categoryId;
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductDraft _$ProductDraftFromJson(Map<String, dynamic> json) {
  return _ProductDraft.fromJson(json);
}

/// @nodoc
mixin _$ProductDraft {
  String? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get imageStoragePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  String? get categoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Serializes this ProductDraft to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductDraftCopyWith<ProductDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductDraftCopyWith<$Res> {
  factory $ProductDraftCopyWith(
          ProductDraft value, $Res Function(ProductDraft) then) =
      _$ProductDraftCopyWithImpl<$Res, ProductDraft>;
  @useResult
  $Res call(
      {String? id,
      String name,
      double price,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? imageStoragePath,
      @JsonKey(name: 'category_id') String? categoryId,
      @JsonKey(name: 'is_available') bool isAvailable});
}

/// @nodoc
class _$ProductDraftCopyWithImpl<$Res, $Val extends ProductDraft>
    implements $ProductDraftCopyWith<$Res> {
  _$ProductDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? price = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? imageStoragePath = freezed,
    Object? categoryId = freezed,
    Object? isAvailable = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      imageStoragePath: freezed == imageStoragePath
          ? _value.imageStoragePath
          : imageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductDraftImplCopyWith<$Res>
    implements $ProductDraftCopyWith<$Res> {
  factory _$$ProductDraftImplCopyWith(
          _$ProductDraftImpl value, $Res Function(_$ProductDraftImpl) then) =
      __$$ProductDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String name,
      double price,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? imageStoragePath,
      @JsonKey(name: 'category_id') String? categoryId,
      @JsonKey(name: 'is_available') bool isAvailable});
}

/// @nodoc
class __$$ProductDraftImplCopyWithImpl<$Res>
    extends _$ProductDraftCopyWithImpl<$Res, _$ProductDraftImpl>
    implements _$$ProductDraftImplCopyWith<$Res> {
  __$$ProductDraftImplCopyWithImpl(
      _$ProductDraftImpl _value, $Res Function(_$ProductDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProductDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? price = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? imageStoragePath = freezed,
    Object? categoryId = freezed,
    Object? isAvailable = null,
  }) {
    return _then(_$ProductDraftImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      imageStoragePath: freezed == imageStoragePath
          ? _value.imageStoragePath
          : imageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductDraftImpl extends _ProductDraft {
  const _$ProductDraftImpl(
      {this.id,
      required this.name,
      required this.price,
      this.description,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.imageStoragePath,
      @JsonKey(name: 'category_id') this.categoryId,
      @JsonKey(name: 'is_available') required this.isAvailable})
      : super._();

  factory _$ProductDraftImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductDraftImplFromJson(json);

  @override
  final String? id;
  @override
  final String name;
  @override
  final double price;
  @override
  final String? description;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? imageStoragePath;
  @override
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @override
  String toString() {
    return 'ProductDraft(id: $id, name: $name, price: $price, description: $description, imageUrl: $imageUrl, imageStoragePath: $imageStoragePath, categoryId: $categoryId, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductDraftImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.imageStoragePath, imageStoragePath) ||
                other.imageStoragePath == imageStoragePath) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, price, description,
      imageUrl, imageStoragePath, categoryId, isAvailable);

  /// Create a copy of ProductDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductDraftImplCopyWith<_$ProductDraftImpl> get copyWith =>
      __$$ProductDraftImplCopyWithImpl<_$ProductDraftImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductDraftImplToJson(
      this,
    );
  }
}

abstract class _ProductDraft extends ProductDraft {
  const factory _ProductDraft(
          {final String? id,
          required final String name,
          required final double price,
          final String? description,
          @JsonKey(name: 'image_url') final String? imageUrl,
          @JsonKey(includeFromJson: false, includeToJson: false)
          final String? imageStoragePath,
          @JsonKey(name: 'category_id') final String? categoryId,
          @JsonKey(name: 'is_available') required final bool isAvailable}) =
      _$ProductDraftImpl;
  const _ProductDraft._() : super._();

  factory _ProductDraft.fromJson(Map<String, dynamic> json) =
      _$ProductDraftImpl.fromJson;

  @override
  String? get id;
  @override
  String get name;
  @override
  double get price;
  @override
  String? get description;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get imageStoragePath;
  @override
  @JsonKey(name: 'category_id')
  String? get categoryId;
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;

  /// Create a copy of ProductDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductDraftImplCopyWith<_$ProductDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
