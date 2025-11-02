import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart';
import '../../constants.dart';
import '../../main.dart';
import '../../route/route_constants.dart';
import '../../services/order_calculation_service.dart';
import '../../models/cart_item.dart';
import 'address_picker_screen.dart';

final supabase = Supabase.instance.client;

class PaymentScreen extends StatefulWidget {
  final OrderCalculationResult orderSummary;
  final String deliveryAddress;
  final List<CartItem> items;
  final String? customerNote;

  const PaymentScreen({
    super.key,
    required this.orderSummary,
    required this.deliveryAddress,
    required this.items,
    this.customerNote,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'store_pickup';
  late String _deliveryAddress;
  late OrderCalculationResult _orderSummary;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.deliveryAddress;
    _orderSummary = widget.orderSummary;
  }

  Future<void> _changeAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPickerScreen(
          initialAddress: _deliveryAddress,
        ),
      ),
    );

    if (result != null) {
      String addressText;
      if (result is Map && result.containsKey('address')) {
        addressText = result['address'] as String;
      } else if (result is String) {
        addressText = result;
      } else {
        addressText = '';
      }

      setState(() {
        _deliveryAddress = addressText;
        // Recalculate order summary using new delivery location
        _orderSummary = OrderCalculationService().calculateOrder(
          items: widget.items,
          deliveryLocation: _deliveryAddress,
        );
      });
    }
  }

  Future<void> _startVNPayPayment(String orderId, double amount) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1️⃣ Gọi Supabase Edge Function để tạo URL thanh toán
      final response = await supabase.functions.invoke(
        'vnpay_create?order_id=$orderId&amount=$amount',
      );

      final paymentUrl = response.data['paymentUrl'] as String?;
      if (paymentUrl == null) {
        throw Exception('Không nhận được URL thanh toán từ server.');
      }

      debugPrint('🔗 VNPay URL: $paymentUrl');

      // 2️⃣ Mở webview VNPay
      await VNPAYFlutter.instance.show(
        context: context,
        paymentUrl: paymentUrl,
        appBarTitle: "Thanh toán VNPay",
        onPaymentSuccess: (params) async {
          debugPrint('✅ Thanh toán thành công: $params');
          final txnRef = params['vnp_TxnRef'] ?? '';
          final orderId =
              txnRef.contains('_') ? txnRef.split('_').first : txnRef;

          if (mounted) Navigator.of(context, rootNavigator: true).pop();

          // ✅ Đợi WebView đóng hoàn toàn
          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              paymentResultScreenRoute,
              (route) => false,
              arguments: {
                'orderId': orderId,
                'status': 'success',
                'purchasedItemIds': widget.items.map((e) => e.id).toList(),
              },
            );
          });
        },
        onPaymentError: (params) async {
          debugPrint('❌ Thanh toán thất bại: $params');
          final txnRef = params['vnp_TxnRef'] ?? '';
          final orderId =
              txnRef.contains('_') ? txnRef.split('_').first : txnRef;

          if (mounted) Navigator.of(context, rootNavigator: true).pop();

          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              paymentResultScreenRoute,
              (route) => false,
              arguments: {'orderId': orderId, 'status': 'failed'},
            );
          });
        },
      );
    } catch (e) {
      debugPrint('💥 Lỗi VNPay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: $e'),
            backgroundColor: cellphoneZRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    switch (_selectedMethod) {
      case 'vnpay':
        // TODO: Tạo order trước, lấy orderId
        final tempOrderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
        await _startVNPayPayment(tempOrderId, _orderSummary.total);
        break;

      case 'ship_cod':
        await _handleCODPayment();
        break;

      case 'store_pickup':
        await _handleStorePickup();
        break;

      case 'qr_transfer':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chức năng chuyển khoản QR đang được phát triển'),
            ),
          );
        }
        break;

      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phương thức thanh toán chưa được hỗ trợ'),
            ),
          );
        }
    }
  }

  Future<void> _handleCODPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đơn hàng'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('Bạn sẽ thanh toán khi nhận hàng (COD).'),
              const SizedBox(height: 8),
              Text('Địa chỉ: $_deliveryAddress'),
              const SizedBox(height: 8),
              Text(
                  'Tổng: ${OrderCalculationService().formatPrice(_orderSummary.total)}'),
              if (widget.customerNote != null &&
                  widget.customerNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Ghi chú:'),
                Text(widget.customerNote!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: cellphoneZRed),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Create order in database
      final orderId = 'COD_${DateTime.now().millisecondsSinceEpoch}';

      // Navigate to result screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        paymentResultScreenRoute,
        (route) => false,
        arguments: {
          'orderId': orderId,
          'status': 'success',
          'purchasedItemIds': widget.items.map((e) => e.id).toList(),
        },
      );
    }
  }

  Future<void> _handleStorePickup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đơn hàng'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('Bạn sẽ thanh toán và nhận hàng tại cửa hàng.'),
              const SizedBox(height: 8),
              Text(
                  'Tổng: ${OrderCalculationService().formatPrice(_orderSummary.total)}'),
              if (widget.customerNote != null &&
                  widget.customerNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Ghi chú:'),
                Text(widget.customerNote!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: cellphoneZRed),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Create order in database
      final orderId = 'STORE_${DateTime.now().millisecondsSinceEpoch}';

      // Navigate to result screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        paymentResultScreenRoute,
        (route) => false,
        arguments: {
          'orderId': orderId,
          'status': 'success',
          'purchasedItemIds': widget.items.map((e) => e.id).toList(),
        },
      );
    }
  }

  Widget _buildSummaryRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            OrderCalculationService().formatPrice(amount),
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cellphoneZRed,
        foregroundColor: Colors.white,
        title: const Text('Chọn phương thức thanh toán'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          // Payment Methods Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Phương thức thanh toán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'store_pickup',
                  groupValue: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                  activeColor: cellphoneZRed,
                  title: const Text('Thanh toán tại cửa hàng'),
                  subtitle: const Text('Thanh toán và nhận tại cửa hàng'),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'qr_transfer',
                  groupValue: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                  activeColor: cellphoneZRed,
                  title: const Text('Chuyển khoản qua mã QR'),
                  subtitle: const Text('Chuyển khoản ngân hàng'),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'vnpay',
                  groupValue: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                  activeColor: cellphoneZRed,
                  title: Row(
                    children: [
                      const Text('VNPAY'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cellphoneZRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Khuyến nghị',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text('Thanh toán qua VNPAY'),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'ship_cod',
                  groupValue: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                  activeColor: cellphoneZRed,
                  title: const Text('Thanh toán khi nhận hàng (COD)'),
                  subtitle: const Text('Giao hàng tận nơi'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Delivery Address & Order Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address
                  if (_selectedMethod == 'ship_cod') ...[
                    const Text(
                      'Địa chỉ giao hàng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text(_deliveryAddress)),
                        TextButton(
                          onPressed: _changeAddress,
                          style: TextButton.styleFrom(
                            foregroundColor: cellphoneZRed,
                          ),
                          child: const Text('Thay đổi'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],

                  // Products
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: item.productImage != null
                                  ? NetworkImage(item.productImage!)
                                  : null,
                              backgroundColor: Colors.grey.shade200,
                              child: item.productImage == null
                                  ? const Icon(Icons.image, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Số lượng: ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              OrderCalculationService()
                                  .formatPrice(item.totalPrice),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),

                  const Divider(height: 24),

                  // Order Summary
                  const Text(
                    'Tóm tắt đơn hàng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (widget.customerNote != null &&
                      widget.customerNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ghi chú',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.customerNote!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildSummaryRow('Tạm tính', _orderSummary.subtotal),
                  _buildSummaryRow('Thuế', _orderSummary.tax),
                  _buildSummaryRow('Phí vận chuyển', _orderSummary.shipping),
                  if (_orderSummary.discount > 0)
                    _buildSummaryRow('Giảm giá', -_orderSummary.discount),
                  const Divider(),
                  _buildSummaryRow('Tổng', _orderSummary.total, bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cellphoneZRed,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isProcessing ? null : _handlePayment,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Thanh toán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
