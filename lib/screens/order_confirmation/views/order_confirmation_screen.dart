import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/order.dart';
import 'package:shop/models/order_item.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;
  final List<OrderItem>? orderItems;

  const OrderConfirmationScreen({
    Key? key,
    required this.order,
    this.orderItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Animation/Icon
            Container(
              padding: const EdgeInsets.all(defaultPadding * 2),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(defaultPadding * 2),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    'Cảm ơn bạn đã mua hàng',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: defaultPadding),
                  _buildInfoRow(
                    context,
                    'Mã đơn hàng',
                    '#${order.id.substring(0, 8).toUpperCase()}',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Ngày đặt',
                    dateFormat.format(order.createdAt),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Trạng thái',
                    _getStatusText(order.status),
                    valueColor: _getStatusColor(order.status),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Tổng tiền',
                    currencyFormat.format(order.totalPrice),
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
            if (orderItems != null && orderItems!.isNotEmpty)
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
                      'Sản phẩm đã đặt',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: defaultPadding),
                    ...orderItems!.map((item) => _buildOrderItem(
                          context,
                          item,
                          currencyFormat,
                        )),
                  ],
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  // View Order History Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/order-history',
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem lịch sử đơn hàng'),
                  ),
                  const SizedBox(height: defaultPadding / 2),

                  // Continue Shopping Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                  const SizedBox(height: defaultPadding / 2),

                  // Share/Download Receipt Button
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement share/download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang được phát triển'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ hóa đơn'),
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: Row(
        children: [
          // Product Image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sản phẩm #${item.productId.substring(0, 8)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
