import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order.dart';
import 'package:shop/models/order_item.dart';
import 'package:shop/services/order_service.dart';
import 'package:intl/intl.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({Key? key}) : super(key: key);

  @override
  _OrderManagementState createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  late ScrollController _scrollController;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  OrderStatus? _selectedStatus;
  String? _errorMessage;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isInitialLoad = true;

  final Map<OrderStatus, String> _statusLabels = {
    OrderStatus.pending: 'Chờ xử lý',
    OrderStatus.paid: 'Đã thanh toán',
    OrderStatus.shipping: 'Đang giao',
    OrderStatus.completed: 'Hoàn thành',
    OrderStatus.cancelled: 'Đã hủy',
  };

  final Map<OrderStatus, Color> _statusColors = {
    OrderStatus.pending: Colors.orange,
    OrderStatus.paid: Colors.blue,
    OrderStatus.shipping: Colors.purple,
    OrderStatus.completed: Colors.green,
    OrderStatus.cancelled: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasMoreData = true;
      _allOrders.clear();
      _filteredOrders.clear();
    }

    if (_isLoading && !_isInitialLoad) return;
    if (_isLoadingMore) return;
    if (!_hasMoreData && !isRefresh) return;

    setState(() {
      if (_isInitialLoad || isRefresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      List<Order> newOrders;

      if (_selectedStatus == null) {
        // Load all orders
        newOrders = await _orderService.getAllOrdersPaginated(
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        // Load orders by status
        newOrders = await _orderService.getAllOrdersByStatusPaginated(
          status: _selectedStatus!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

      // Load order items for each order (limit to avoid too many requests)
      final ordersWithItems = <Order>[];
      for (final order in newOrders.take(10)) {
        // Only load items for first 10 to avoid performance issues
        try {
          final orderWithItems =
              await _orderService.getOrderWithItems(order.id);
          ordersWithItems.add(orderWithItems ?? order);
        } catch (e) {
          ordersWithItems.add(order);
        }
      }

      // Add remaining orders without items
      ordersWithItems.addAll(newOrders.skip(10));

      setState(() {
        if (isRefresh) {
          _allOrders = ordersWithItems;
        } else {
          _allOrders.addAll(ordersWithItems);
        }

        _currentPage++;
        _hasMoreData = newOrders.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _isInitialLoad = false;
      });

      _filterOrdersByStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Không thể tải đơn hàng: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải đơn hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      if (!_isLoadingMore && _hasMoreData) {
        _loadOrders();
      }
    }
  }

  void _filterOrdersByStatus() {
    if (_selectedStatus == null) {
      _filteredOrders = _allOrders;
    } else {
      _filteredOrders =
          _allOrders.where((order) => order.status == _selectedStatus).toList();
    }
  }

  void _onTabChanged() {
    final tabIndex = _tabController.index;
    final previousStatus = _selectedStatus;

    setState(() {
      if (tabIndex == 0) {
        _selectedStatus = null; // All orders
      } else {
        _selectedStatus = OrderStatus.values[tabIndex - 1];
      }
    });

    // If status changed, reload with new filter
    if (previousStatus != _selectedStatus) {
      _currentPage = 0;
      _hasMoreData = true;
      _allOrders.clear();
      _filteredOrders.clear();
      _loadOrders(isRefresh: true);
    } else {
      _filterOrdersByStatus();
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Widget _buildStatusChip(OrderStatus status) {
    final color = _statusColors[status] ?? Colors.grey;
    final label = _statusLabels[status] ?? 'Không xác định';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ngày đặt: ${_formatDate(order.createdAt)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              // Text(
              //   'Khách hàng: ${order.userId}',
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.grey[600],
              //   ),
              // ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatPrice(order.totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cellphoneZRed,
                    ),
                  ),
                ],
              ),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${order.items!.length} sản phẩm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết đơn hàng',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderInfoSection(order),
                        const SizedBox(height: 20),
                        if (order.items != null)
                          _buildOrderItemsSection(order.items!),
                        const SizedBox(height: 20),
                        _buildOrderActionsSection(order),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfoSection(Order order) {
    return Card(
      elevation: 0,
      color: cellphoneZRed.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Mã đơn hàng:', order.id),
            _buildInfoRow('Khách hàng:', order.userId),
            _buildInfoRow('Ngày đặt:', _formatDate(order.createdAt)),
            _buildInfoRow('Tổng tiền:', _formatPrice(order.totalPrice)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sản phẩm đã đặt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildOrderItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.phone_android,
                color: Colors.grey[400],
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productId, // Using productId as product name for now
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số lượng: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatPrice(item.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cellphoneZRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionsSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (order.status == OrderStatus.pending) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order, OrderStatus.paid),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Xác nhận',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateOrderStatus(order, OrderStatus.cancelled),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text('Hủy đơn',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ] else if (order.status == OrderStatus.paid) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateOrderStatus(order, OrderStatus.shipping),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: const Text('Giao hàng',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
            ] else if (order.status == OrderStatus.shipping) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateOrderStatus(order, OrderStatus.completed),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Hoàn thành',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update order status via service
      await _orderService.updateOrderStatus(order.id, newStatus);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Close order details bottom sheet
      if (mounted) Navigator.pop(context);

      // Reload orders to get updated data
      await _loadOrders(isRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật trạng thái: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 24,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(6, 6),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(-6, -6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/logo/CellphoneZ.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Quản lý đơn hàng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (_) => _onTabChanged(),
          labelColor: cellphoneZRed,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: cellphoneZRed,
          tabs: [
            const Tab(text: 'Tất cả'),
            Tab(text: _statusLabels[OrderStatus.pending]),
            Tab(text: _statusLabels[OrderStatus.paid]),
            Tab(text: _statusLabels[OrderStatus.shipping]),
            Tab(text: _statusLabels[OrderStatus.completed]),
            Tab(text: _statusLabels[OrderStatus.cancelled]),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cellphoneZRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _loadOrders(isRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: cellphoneZRed.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có đơn hàng nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cellphoneZRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _loadOrders(isRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Làm mới'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(isRefresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredOrders.length +
                            (_isLoadingMore ? 1 : 0) +
                            (!_hasMoreData && _filteredOrders.isNotEmpty
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator when loading more
                          if (index >= _filteredOrders.length &&
                              _isLoadingMore) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            );
                          }

                          // Show "no more data" indicator when reached end
                          if (index >= _filteredOrders.length &&
                              !_hasMoreData) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                'Đã hiển thị tất cả ${_filteredOrders.length} đơn hàng',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          return _buildOrderCard(_filteredOrders[index]);
                        },
                      ),
                    ),
    );
  }
}
