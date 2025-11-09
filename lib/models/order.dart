import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus { pending, paid, shipping, completed, cancelled }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'total_price') required double totalPrice,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(OrderStatus.pending) OrderStatus status,
    List<OrderItem>? items,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
