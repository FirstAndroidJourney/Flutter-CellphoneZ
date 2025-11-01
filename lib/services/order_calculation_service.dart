import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cart_item.dart';

class OrderCalculationResult {
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;

  OrderCalculationResult({
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
  });
}

class OrderCalculationService {
  double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double calculateTax(double subtotal) {
    return subtotal * TAX_RATE;
  }

  double calculateShipping(String location) {
    // TODO: Implement shipping calculation based on location
    return DEFAULT_SHIPPING_FEE;
  }

  double calculateDiscount(String? couponCode, double subtotal) {
    if (couponCode == null || couponCode.isEmpty) return 0.0;
    
    // Demo voucher: WELCOME gives 10% off
    if (couponCode.toUpperCase() == 'WELCOME') {
      return subtotal * 0.1; // 10% discount
    }
    
    return 0.0; // Invalid voucher
  }

  OrderCalculationResult calculateOrder({
    required List<CartItem> items,
    required String deliveryLocation,
    String? couponCode,
  }) {
    // Chỉ tính những item được chọn
    final selectedItems = items.where((item) => item.isSelected).toList();
    
    final subtotal = calculateSubtotal(selectedItems);
    final tax = calculateTax(subtotal);
    final shipping = calculateShipping(deliveryLocation);
    final discount = calculateDiscount(couponCode, subtotal);

    final total = subtotal + tax + shipping - discount;

    return OrderCalculationResult(
      subtotal: subtotal,
      tax: tax,
      shipping: shipping,
      discount: discount,
      total: total,
    );
  }

  String formatPrice(double price) {
    final priceInt = price.round();
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(priceInt)}đ';
  }
}