import 'package:freezed_annotation/freezed_annotation.dart';
part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId, // Liên kết Order
    required String productId,
    required int quantity,
    required double price, // Lưu giá tại thời điểm đặt
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
