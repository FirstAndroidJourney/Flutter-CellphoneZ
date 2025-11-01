import 'package:freezed_annotation/freezed_annotation.dart';
part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'product_id') required String productId,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'product_image') String? productImage,
    @Default(false) bool isSelected,
  }) = _CartItem;

  const CartItem._();

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  double get totalPrice => quantity * unitPrice;
      
}
