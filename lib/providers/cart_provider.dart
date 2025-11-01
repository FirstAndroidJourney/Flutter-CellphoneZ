// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:shop/models/cart_item.dart'; // Đảm bảo import model của bạn
import 'package:shop/services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  
  // 1. "Nâng" tất cả state từ CartScreen lên đây
  List<CartItemWithProduct> _items = [];
  double _total = 0;
  bool _loading = true;

  // 2. Tạo "getters" để UI có thể đọc (nhưng không thể sửa)
  List<CartItemWithProduct> get items => _items;
  double get total => _total;
  bool get loading => _loading;

  /// 3. Hàm tải giỏ hàng (sẽ được gọi khi app khởi động VÀ khi cần)
  Future<void> loadCart() async {
    _loading = true;
    notifyListeners(); // Thông báo cho UI "Bắt đầu loading"

    try {
      _items = await _cartService.getCartItemsWithProducts();
      _total = await _cartService.getCartTotal();
    } catch (e) {
      print('Lỗi nghiêm trọng khi tải giỏ hàng: $e');
      _items = []; // Nếu lỗi thì trả về giỏ rỗng
      _total = 0;
    } finally {
      _loading = false;
      notifyListeners(); // Thông báo cho UI "Loading xong, có dữ liệu mới"
    }
  }

  /// 4. Hàm THÊM vào giỏ (sẽ được ProductBuyNowScreen gọi)
  Future<void> addToCart(String productId, int quantity) async {
    try {
      await _cartService.addToCart(productId: productId, quantity: quantity);
      
      // Quan trọng: Tải lại giỏ hàng ngay sau khi thêm thành công
      await loadCart(); 
    } catch (e) {
      print('Lỗi Provider-addToCart: $e');
      rethrow; // Ném lỗi ra để ProductBuyNowScreen hiển thị SnackBar
    }
  }

  /// 5. Hàm CẬP NHẬT (sẽ được CartScreen gọi)
  Future<void> updateQuantity(String cartItemId, int newQty) async {
    try {
      await _cartService.updateQuantity(cartItemId, newQty);
      await loadCart(); // Tải lại giỏ hàng
    } catch (e) {
      print('Lỗi Provider-updateQuantity: $e');
    }
  }

  /// 6. Hàm XÓA (sẽ được CartScreen gọi)
  Future<void> removeItem(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
      await loadCart(); // Tải lại giỏ hàng
    } catch (e) {
      print('Lỗi Provider-removeItem: $e');
    }
  }
}