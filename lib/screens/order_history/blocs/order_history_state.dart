import 'package:equatable/equatable.dart';
import 'package:shop/models/order.dart';

/// Base class for all OrderHistory states
abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial();
}

/// Loading state
class OrderHistoryLoading extends OrderHistoryState {
  const OrderHistoryLoading();
}

/// Loaded state with orders
class OrderHistoryLoaded extends OrderHistoryState {
  final List<Order> orders;
  final OrderStatus? filterStatus;

  const OrderHistoryLoaded({
    required this.orders,
    this.filterStatus,
  });

  @override
  List<Object?> get props => [orders, filterStatus];

  OrderHistoryLoaded copyWith({
    List<Order>? orders,
    OrderStatus? filterStatus,
  }) {
    return OrderHistoryLoaded(
      orders: orders ?? this.orders,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

/// Empty state when no orders found
class OrderHistoryEmpty extends OrderHistoryState {
  final String message;

  const OrderHistoryEmpty({
    this.message = 'Bạn chưa có đơn hàng nào',
  });

  @override
  List<Object?> get props => [message];
}

/// Error state
class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State for tracking specific order
class OrderTrackingLoaded extends OrderHistoryState {
  final Order order;

  const OrderTrackingLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

/// State for order with items loaded
class OrderWithItemsLoaded extends OrderHistoryState {
  final Order order;

  const OrderWithItemsLoaded(this.order);

  @override
  List<Object?> get props => [order];
}
