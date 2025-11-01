import 'package:flutter/material.dart';
import '../../../services/order_calculation_service.dart';
import '../../../models/cart_item.dart';
import 'address_picker_screen.dart';

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
  final TextEditingController _voucherController = TextEditingController();
  String? _appliedVoucher;

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.deliveryAddress;
    _orderSummary = widget.orderSummary;
    // Debug prints
    print('PaymentScreen - Items received: ${widget.items.length}');
    print('PaymentScreen - Delivery address: $_deliveryAddress');
    print('PaymentScreen - Order summary: subtotal=${_orderSummary.subtotal}');
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
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
        _orderSummary = OrderCalculationService().calculateOrder(
          items: widget.items,
          deliveryLocation: _deliveryAddress,
          couponCode: _appliedVoucher,
        );
      });
    }
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã giảm giá')),
      );
      return;
    }

    setState(() {
      _appliedVoucher = code;
      _orderSummary = OrderCalculationService().calculateOrder(
        items: widget.items,
        deliveryLocation: _deliveryAddress,
        couponCode: code,
      );
    });

    if (_orderSummary.discount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Áp dụng mã giảm giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã giảm giá không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      _appliedVoucher = null;
    }
  }

  Widget _buildSummaryRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(
            OrderCalculationService().formatPrice(amount),
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn phương thức thanh toán'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Payment Methods Card
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Phương thức thanh toán',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'store_pickup',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                            title: const Text('Thanh toán tại cửa hàng'),
                            subtitle: const Text('Thanh toán và nhận tại cửa hàng'),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'qr_transfer',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                            title: const Text('Chuyển khoản qua mã QR'),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'vnpay',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                            title: const Text('VNPAY'),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'ship_cod',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                            title: const Text('Thanh toán khi nhận hàng (COD)'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Voucher Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mã giảm giá', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _voucherController,
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập mã giảm giá (thử mã WELCOME)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    textCapitalization: TextCapitalization.characters,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _applyVoucher,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Áp dụng'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Text(_deliveryAddress)),
                                TextButton(
                                  onPressed: _changeAddress,
                                  child: const Text('Thay đổi'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        ? const Icon(Icons.image)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName),
                                        const SizedBox(height: 4),
                                        Text('Số lượng: ${item.quantity}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Text(OrderCalculationService().formatPrice(item.totalPrice)),
                                ],
                              ),
                            )),
                            const SizedBox(height: 12),
                            const Text('Tóm tắt đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (widget.customerNote != null && widget.customerNote!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(widget.customerNote!),
                              const Divider(),
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
              ),
            ),
            // Payment Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 64,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    if (_selectedMethod == 'ship_cod') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận đơn hàng'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: [
                                Text('Bạn sẽ thanh toán khi nhận hàng (COD).'),
                                const SizedBox(height: 8),
                                Text('Địa chỉ: $_deliveryAddress'),
                                const SizedBox(height: 8),
                                Text('Tổng: ${OrderCalculationService().formatPrice(_orderSummary.total)}'),
                                if (widget.customerNote != null && widget.customerNote!.isNotEmpty) ...[
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
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Đặt hàng thành công'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cảm ơn bạn! Đơn hàng đã được đặt và sẽ được giao tận nơi.'),
                                SizedBox(height: 8),
                                Text('Chúng tôi sẽ sớm liên hệ với bạn để xác nhận đơn hàng.'),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );

                        // Return to cart screen
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chức năng thanh toán chưa được triển khai'),
                        ),
                      );
                    }
                  },
                  child: const Text('Thanh toán', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}