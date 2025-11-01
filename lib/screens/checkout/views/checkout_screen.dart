import 'package:flutter/material.dart';
import '../../../models/cart_item.dart';
import '../../../services/order_calculation_service.dart';
import 'address_picker_screen.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderCalculationService _orderCalculation = OrderCalculationService();
  
  String? _selectedAddress;
  String? _couponCode;
  late OrderCalculationResult _orderSummary;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateOrder();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _calculateOrder() {
    _orderSummary = _orderCalculation.calculateOrder(
      items: widget.cartItems,
      deliveryLocation: _selectedAddress ?? '',
      couponCode: _couponCode,
    );
  }

  Future<void> _selectAddress() async {
    // TODO: Navigate to address picker screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPickerScreen(initialAddress: _selectedAddress),
      ),
    );

    if (result != null) {
      // AddressPickerScreen returns a map with keys like 'address', 'type', and optionally 'location'
      String addressText;
      if (result is Map && result.containsKey('address')) {
        addressText = result['address'] as String;
      } else if (result is String) {
        addressText = result;
      } else {
        addressText = '';
      }

      setState(() {
        _selectedAddress = addressText;
        _calculateOrder(); // Recalculate with new address
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Delivery Address Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(_selectedAddress ?? 'Chọn địa chỉ giao hàng'),
              trailing: TextButton(
                onPressed: _selectAddress,
                child: Text(_selectedAddress == null ? 'Chọn' : 'Thay đổi'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Optional customer note
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ghi chú cho người bán (không bắt buộc)'
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected Items Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName),
                                  const SizedBox(height: 4),
                                  Text('Số lượng: ${item.quantity}'),
                                ],
                              ),
                            ),
                            Text(_orderCalculation.formatPrice(item.totalPrice)),
                          ],
                        ),
                      ))
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Summary Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tóm tắt đơn hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow('Tạm tính', _orderSummary.subtotal),
                  _buildPriceRow('Thuế', _orderSummary.tax),
                  _buildPriceRow('Phí vận chuyển', _orderSummary.shipping),
                  if (_orderSummary.discount > 0)
                    _buildPriceRow('Giảm giá', -_orderSummary.discount),
                  const Divider(),
                  _buildPriceRow(
                    'Tổng',
                    _orderSummary.total,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Continue to Payment Button
          ElevatedButton(
            onPressed: _selectedAddress == null
                ? null
                : () async {
                    // Navigate to payment screen when user taps
                    // Filter only selected items
                    final selectedItems = widget.cartItems.where((item) => item.isSelected).toList();
                    
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          orderSummary: _orderSummary,
                          deliveryAddress: _selectedAddress!,
                          items: selectedItems,
                          customerNote: _noteController.text.isEmpty ? null : _noteController.text,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Tiếp tục thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    TextStyle? textStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            _orderCalculation.formatPrice(amount),
            style: textStyle,
          ),
        ],
      ),
    );
  }
}