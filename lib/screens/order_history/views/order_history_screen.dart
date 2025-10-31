import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order.dart';
import 'package:shop/screens/order_history/blocs/order_history_bloc.dart';
import 'package:shop/screens/order_history/blocs/order_history_event.dart';
import 'package:shop/screens/order_history/blocs/order_history_state.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;

  const OrderHistoryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderHistoryBloc()..add(LoadUserOrders(userId)),
      child: OrderHistoryScreenView(userId: userId),
    );
  }
}

class OrderHistoryScreenView extends StatefulWidget {
  final String userId;

  const OrderHistoryScreenView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<OrderHistoryScreenView> createState() => _OrderHistoryScreenViewState();
}

class _OrderHistoryScreenViewState extends State<OrderHistoryScreenView> {
  OrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: Column(
        children: [
          // Status Filter
          _buildStatusFilter(),
          const Divider(height: 1),

          // Order List
          Expanded(
            child: BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
              builder: (context, state) {
                if (state is OrderHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is OrderHistoryError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: defaultPadding),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: defaultPadding),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<OrderHistoryBloc>()
                                .add(RefreshOrders(widget.userId));
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is OrderHistoryEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: defaultPadding),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: defaultPadding),
                        if (_selectedStatus != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = null;
                              });
                              context.read<OrderHistoryBloc>().add(
                                    FilterOrdersByStatus(
                                      userId: widget.userId,
                                      status: null,
                                    ),
                                  );
                            },
                            child: const Text('Xem tất cả đơn hàng'),
                          ),
                      ],
                    ),
                  );
                }

                if (state is OrderHistoryLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<OrderHistoryBloc>()
                          .add(RefreshOrders(widget.userId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(defaultPadding),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(
                          context,
                          state.orders[index],
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      null, // All orders
      OrderStatus.pending,
      OrderStatus.paid,
      OrderStatus.shipping,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: defaultPadding / 2),
            child: FilterChip(
              label: Text(_getStatusFilterText(status)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
                context.read<OrderHistoryBloc>().add(
                      FilterOrdersByStatus(
                        userId: widget.userId,
                        status: status,
                      ),
                    );
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to order detail
          context
              .read<OrderHistoryBloc>()
              .add(LoadOrderWithItems(order.id));
          // TODO: Navigate to order detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.id.substring(0, 8).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: defaultPadding / 2),

              // Order Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding / 2),

              const Divider(),

              // Order Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    currencyFormat.format(order.totalPrice),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding / 2),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == OrderStatus.shipping ||
                      order.status == OrderStatus.paid)
                    TextButton.icon(
                      onPressed: () {
                        context
                            .read<OrderHistoryBloc>()
                            .add(TrackOrder(order.id));
                        // TODO: Show tracking dialog or navigate to tracking screen
                        _showTrackingDialog(context, order);
                      },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('Theo dõi'),
                    ),
                  const SizedBox(width: defaultPadding / 2),
                  TextButton.icon(
                    onPressed: () {
                      context
                          .read<OrderHistoryBloc>()
                          .add(LoadOrderWithItems(order.id));
                      // TODO: Navigate to order detail
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Chi tiết'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding / 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getStatusFilterText(OrderStatus? status) {
    if (status == null) return 'Tất cả';
    return _getStatusText(status);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Đang xử lý';
      case OrderStatus.paid:
        return 'Đã thanh toán';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.shipping:
        return Colors.purple;
      case OrderStatus.completed:
        return successColor;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _showTrackingDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theo dõi đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn hàng #${order.id.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: defaultPadding),
            _buildTrackingStep(
              'Đã đặt hàng',
              order.status.index >= OrderStatus.pending.index,
            ),
            _buildTrackingStep(
              'Đã thanh toán',
              order.status.index >= OrderStatus.paid.index,
            ),
            _buildTrackingStep(
              'Đang vận chuyển',
              order.status.index >= OrderStatus.shipping.index,
            ),
            _buildTrackingStep(
              'Đã giao hàng',
              order.status == OrderStatus.completed,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep(String label, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? successColor : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: defaultPadding / 2),
          Text(
            label,
            style: TextStyle(
              color: isCompleted ? Colors.black87 : Colors.grey,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
