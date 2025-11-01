import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shop/repository/order_repository.dart';
import 'order_history_event.dart';
import 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderRepository _orderRepository;

  OrderHistoryBloc({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? GetIt.I<OrderRepository>(),
        super(const OrderHistoryInitial()) {
    on<LoadUserOrders>(_onLoadUserOrders);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<RefreshOrders>(_onRefreshOrders);
    on<TrackOrder>(_onTrackOrder);
    on<LoadOrderWithItems>(_onLoadOrderWithItems);
  }

  /// Handle loading all orders for a user
  Future<void> _onLoadUserOrders(
    LoadUserOrders event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(const OrderHistoryLoading());
    try {
      final orders = await _orderRepository.getUserOrders(event.userId);

      if (orders.isEmpty) {
        emit(const OrderHistoryEmpty());
      } else {
        emit(OrderHistoryLoaded(orders: orders));
      }
    } catch (e) {
      emit(OrderHistoryError('Không thể tải lịch sử đơn hàng: ${e.toString()}'));
    }
  }

  /// Handle filtering orders by status
  Future<void> _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(const OrderHistoryLoading());
    try {
      final orders = event.status == null
          ? await _orderRepository.getUserOrders(event.userId)
          : await _orderRepository.getUserOrdersByStatus(
              event.userId,
              event.status!,
            );

      if (orders.isEmpty) {
        emit(OrderHistoryEmpty(
          message: event.status == null
              ? 'Bạn chưa có đơn hàng nào'
              : 'Không có đơn hàng với trạng thái này',
        ));
      } else {
        emit(OrderHistoryLoaded(
          orders: orders,
          filterStatus: event.status,
        ));
      }
    } catch (e) {
      emit(OrderHistoryError('Không thể lọc đơn hàng: ${e.toString()}'));
    }
  }

  /// Handle refreshing orders
  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrderHistoryState> emit,
  ) async {
    // Get current state
    final currentState = state;

    try {
      if (currentState is OrderHistoryLoaded) {
        // Refresh based on current filter
        if (currentState.filterStatus != null) {
          add(FilterOrdersByStatus(
            userId: event.userId,
            status: currentState.filterStatus,
          ));
        } else {
          add(LoadUserOrders(event.userId));
        }
      } else {
        // Default refresh
        add(LoadUserOrders(event.userId));
      }
    } catch (e) {
      emit(OrderHistoryError('Không thể làm mới: ${e.toString()}'));
    }
  }

  /// Handle tracking specific order
  Future<void> _onTrackOrder(
    TrackOrder event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(const OrderHistoryLoading());
    try {
      final order = await _orderRepository.getOrderById(event.orderId);

      if (order == null) {
        emit(const OrderHistoryError('Không tìm thấy đơn hàng'));
      } else {
        emit(OrderTrackingLoaded(order));
      }
    } catch (e) {
      emit(OrderHistoryError('Không thể theo dõi đơn hàng: ${e.toString()}'));
    }
  }

  /// Handle loading order with items
  Future<void> _onLoadOrderWithItems(
    LoadOrderWithItems event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(const OrderHistoryLoading());
    try {
      final order = await _orderRepository.getOrderWithItems(event.orderId);

      if (order == null) {
        emit(const OrderHistoryError('Không tìm thấy đơn hàng'));
      } else {
        emit(OrderWithItemsLoaded(order));
      }
    } catch (e) {
      emit(OrderHistoryError(
          'Không thể tải chi tiết đơn hàng: ${e.toString()}'));
    }
  }
}
