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

  // Constructor - Tự động load giỏ hàng khi khởi tạo
  CartProvider() {
    loadCart();
  }

  // 2. Tạo "getters" để UI có thể đọc (nhưng không thể sửa)
  List<CartItemWithProduct> get items => _items;
  double get total => _total;
  bool get loading => _loading;
  int get totalItems =>
      _items.fold<int>(0, (sum, item) => sum + item.cartItem.quantity);

  /// 3. Hàm tải giỏ hàng (sẽ được gọi khi app khởi động VÀ khi cần)
  Future<void> loadCart() async {
    _loading = true;
    notifyListeners(); // Thông báo cho UI "Bắt đầu loading"

    try {
      _items = await _cartService.getCartItemsWithProducts();
      _total = await _cartService.getCartTotal();
    } catch (e) {
      // Nếu lỗi (ví dụ: chưa đăng nhập), trả về giỏ rỗng
      // Không cần in lỗi ra console nếu chỉ là chưa đăng nhập
      if (e.toString().contains('not authenticated')) {
        // User chưa đăng nhập - trả về giỏ rỗng, không báo lỗi
        _items = [];
        _total = 0;
      } else {
        // Lỗi khác - in ra để debug
        print('Lỗi khi tải giỏ hàng: $e');
        _items = [];
        _total = 0;
      }
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

  /// 7. Hàm làm mới giỏ hàng (gọi khi user đăng nhập/đăng xuất)
  Future<void> refresh() async {
    await loadCart();
  }

  /// 8. Hàm xóa toàn bộ giỏ hàng (khi user đăng xuất)
  void clearLocalCart() {
    _items = [];
    _total = 0;
    _loading = false;
    notifyListeners();
  }
}
