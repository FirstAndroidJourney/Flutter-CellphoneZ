import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order.dart';
import 'package:shop/models/order_item.dart';
import 'package:shop/route/route_constants.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final supabase = Supabase.instance.client;
  Order? _order;
  List<OrderItem> _orderItems = [];
  Map<String, Map<String, dynamic>> _productDetails = {}; // Cache product info
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      debugPrint('🔍 Loading order data for: ${widget.orderId}');
      
      // Validate order ID format
      if (widget.orderId.isEmpty) {
        throw Exception('Order ID không hợp lệ');
      }
      
      // Load order from database
      final orderResponse = await supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .maybeSingle();

      if (orderResponse == null) {
        throw Exception('Không tìm thấy đơn hàng với ID: ${widget.orderId}');
      }

      debugPrint('✅ Order data: $orderResponse');

      // Load order items
      final orderItemsResponse = await supabase
          .from('order_items')
          .select()
          .eq('order_id', widget.orderId);

      final orderItemsData = List<Map<String, dynamic>>.from(orderItemsResponse);
      debugPrint('✅ Order items: ${orderItemsData.length} items');

      // Load product details for each item
      for (var itemData in orderItemsData) {
        final productId = itemData['product_id'];
        if (!_productDetails.containsKey(productId)) {
          try {
            final productResponse = await supabase
                .from('products')
                .select('id, name, image_url')
                .eq('id', productId)
                .maybeSingle();
            
            if (productResponse != null) {
              _productDetails[productId] = productResponse;
              debugPrint('✅ Loaded product: ${productResponse['name']}');
            }
          } catch (e) {
            debugPrint('⚠️ Failed to load product $productId: $e');
          }
        }
      }

      setState(() {
        _order = Order.fromJson({
          'id': orderResponse['id'] ?? '',
          'user_id': orderResponse['user_id'] ?? '',
          'total_price': (orderResponse['total_price'] ?? 0).toDouble(),
          'status': orderResponse['status'] ?? 'pending',
          'created_at': orderResponse['created_at'] ?? DateTime.now().toIso8601String(),
        });
        
        _orderItems = orderItemsData.map((json) {
          return OrderItem(
            id: json['id'] ?? '',
            orderId: json['order_id'] ?? '',
            productId: json['product_id'] ?? '',
            quantity: json['quantity'] ?? 1,
            price: (json['price'] ?? 0).toDouble(),
          );
        }).toList();
        
        _loading = false;
      });
      
      debugPrint('✅ Order loaded successfully: ${_order?.id} with ${_orderItems.length} items');
    } catch (e) {
      debugPrint('❌ Error loading order: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: cellphoneZRed,
        foregroundColor: Colors.white,
        title: const Text('Chi tiết đơn hàng'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              entryPointScreenRoute,
              (route) => false,
            );
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cellphoneZRed))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi: $_error'),
                      ElevatedButton(
                        onPressed: _loadOrderData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Success Animation/Icon
                          Container(
                            padding: const EdgeInsets.all(defaultPadding * 2),
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(defaultPadding * 2),
                                  decoration: BoxDecoration(
                                    color: successColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 80,
                                    color: successColor,
                                  ),
                                ),
                                const SizedBox(height: defaultPadding),
                                Text(
                                  'Đặt hàng thành công!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: defaultPadding / 2),
                                Text(
                                  'Cảm ơn bạn đã mua hàng',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Order Details Card
                          Container(
                            margin: const EdgeInsets.all(defaultPadding),
                            padding: const EdgeInsets.all(defaultPadding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin đơn hàng',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: defaultPadding),
                                _buildInfoRow(
                                  context,
                                  'Mã đơn hàng',
                                  '#${_order!.id.substring(0, 8).toUpperCase()}',
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  context,
                                  'Ngày đặt',
                                  dateFormat.format(_order!.createdAt),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  context,
                                  'Trạng thái',
                                  _getStatusText(_order!.status),
                                  valueColor: _getStatusColor(_order!.status),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  context,
                                  'Tổng tiền',
                                  currencyFormat.format(_order!.totalPrice),
                                  valueStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Order Items (if available)
                          if (_orderItems.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.all(defaultPadding),
                              padding: const EdgeInsets.all(defaultPadding),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sản phẩm đã đặt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: defaultPadding),
                                  ..._orderItems.map((item) => _buildOrderItem(
                                        context,
                                        item,
                                        currencyFormat,
                                      )),
                                ],
                              ),
                            ),

                          // Action Buttons
                          Container(
                            padding: const EdgeInsets.all(defaultPadding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              child: Column(
                                children: [
                                  // Continue Shopping Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          entryPointScreenRoute,
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cellphoneZRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Tiếp tục mua sắm',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // View Order History Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final user = supabase.auth.currentUser;
                                        if (user != null) {
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            orderHistoryScreenRoute,
                                            (route) => route.isFirst,
                                            arguments: user.id,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Vui lòng đăng nhập để xem lịch sử đơn hàng'),
                                            ),
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cellphoneZRed,
                                        side: const BorderSide(
                                            color: cellphoneZRed),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Xem lịch sử đơn hàng',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          Text(
            value,
            style: valueStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    BuildContext context,
    OrderItem item,
    NumberFormat currencyFormat,
  ) {
    final productInfo = _productDetails[item.productId];
    final productName = productInfo?['name'] ?? 'Sản phẩm #${item.productId.substring(0, 8)}';
    final imageUrl = productInfo?['image_url'];

    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(Icons.shopping_bag, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(item.price * item.quantity),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Đang xử lý';
      case OrderStatus.paid:
        return 'Đã thanh toán';
      case OrderStatus.shipping:
        return 'Đang giao hàng';
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
}
