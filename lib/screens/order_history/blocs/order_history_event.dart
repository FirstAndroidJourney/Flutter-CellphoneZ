import 'package:equatable/equatable.dart';
import 'package:shop/models/order.dart';

/// Base class for all OrderHistory events
abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all orders for a user
class LoadUserOrders extends OrderHistoryEvent {
  final String userId;

  const LoadUserOrders(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to filter orders by status
class FilterOrdersByStatus extends OrderHistoryEvent {
  final String userId;
  final OrderStatus? status; // null means show all

  const FilterOrdersByStatus({
    required this.userId,
    this.status,
  });

  @override
  List<Object?> get props => [userId, status];
}

/// Event to refresh orders
class RefreshOrders extends OrderHistoryEvent {
  final String userId;

  const RefreshOrders(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to track specific order
class TrackOrder extends OrderHistoryEvent {
  final String orderId;

  const TrackOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Event to load order with items
class LoadOrderWithItems extends OrderHistoryEvent {
  final String orderId;

  const LoadOrderWithItems(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
