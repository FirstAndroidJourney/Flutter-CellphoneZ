import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus { pending, paid, shipping, completed, cancelled }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    required double totalPrice,
    required DateTime createdAt,
    @Default(OrderStatus.pending) OrderStatus status,
    List<OrderItem>? items, // Danh sách sản phẩm trong order
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
