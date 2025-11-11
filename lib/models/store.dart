import 'package:freezed_annotation/freezed_annotation.dart';

part 'store.freezed.dart';
part 'store.g.dart';

@freezed
class Store with _$Store {
  const factory Store({
    required String id,
    required String name,
    @JsonKey(name: 'address_full') required String addressFull,
    String? city,
    required double latitude,
    required double longitude,
    String? phone,
    @JsonKey(defaultValue: <String>[]) @Default(<String>[]) List<String> services,
    @JsonKey(name: 'opening_hours') Map<String, dynamic>? openingHours,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(ignore: true) double? distanceKm,
  }) = _Store;

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
}
