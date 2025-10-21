import 'package:freezed_annotation/freezed_annotation.dart';
part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId, // Cart của user nào
    @JsonKey(name: 'product_id')
    required String productId, // Sản phẩm trong giỏ
    required int quantity,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
