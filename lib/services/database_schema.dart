/// Class quản lý schema cho các bảng trong Supabase database
///
/// Sử dụng class này thay vì hardcoded string khi thực hiện query để tránh lỗi typo
/// và đảm bảo consistency trong toàn bộ ứng dụng.
class DatabaseSchema {
  // Tên các bảng
  static const TableNames tables = TableNames();

  // Các cột chung cho tất cả các bảng
  static const CommonColumns common = CommonColumns();

  // Schema cho từng bảng cụ thể
  static const UsersTable users = UsersTable();
  static const ProductsTable products = ProductsTable();
  static const CategoriesTable categories = CategoriesTable();
  static const CartItemsTable cartItems = CartItemsTable();
  static const OrdersTable orders = OrdersTable();
  static const OrderItemsTable orderItems = OrderItemsTable();
  static const PaymentsTable payments = PaymentsTable();
  static const StorageBuckets storage = StorageBuckets();
}

/// Tên các bảng trong database
class TableNames {
  const TableNames();

  final String users = 'user_profiles';
  final String products = 'products';
  final String categories = 'categories';
  final String cartItems = 'cart_items';
  final String orders = 'orders';
  final String orderItems = 'order_items';
}

/// Các cột phổ biến xuất hiện trong nhiều bảng
class CommonColumns {
  const CommonColumns();

  final String id = 'id';
  final String createdAt = 'created_at';
  final String updatedAt = 'updated_at';
  final String userId = 'user_id';
}

/// Schema cho bảng User Profiles
class UsersTable {
  const UsersTable();

  final String table = 'user_profiles';

  // Columns
  final String id = 'id';
  final String email = 'email';
  final String fullName = 'full_name';
  final String avatarUrl = 'avatar_url';
  final String phone = 'phone';
  final String address = 'address';
  final String createdAt = 'created_at';
  final String updatedAt = 'updated_at';
}

/// Schema cho bảng Products
class ProductsTable {
  const ProductsTable();

  final String table = 'products';

  // Columns
  final String id = 'id';
  final String name = 'name';
  final String price = 'price';
  final String description = 'description';
  final String imageUrl = 'image_url';
  final String categoryId = 'category_id';
  final String isAvailable = 'is_available';
}

/// Schema cho bảng Categories
class CategoriesTable {
  const CategoriesTable();

  final String table = 'categories';

  // Columns
  final String id = 'id';
  final String name = 'name';
  final String parentId = 'parent_id';
}

/// Schema cho bảng Cart Items
class CartItemsTable {
  const CartItemsTable();

  final String table = 'cart_items';

  // Columns
  final String id = 'id';
  final String userId = 'user_id';
  final String productId = 'product_id';
  final String quantity = 'quantity';
}

/// Schema cho bảng Orders
class OrdersTable {
  const OrdersTable();

  final String table = 'orders';

  // Columns
  final String id = 'id';
  final String userId = 'user_id';
  final String status =
      'status'; // pending, processing, shipped, delivered, cancelled
  final String totalAmount = 'total_amount';
  final String shippingAddress = 'shipping_address';
  final String paymentMethod = 'payment_method';
  final String createdAt = 'created_at';
}

/// Schema cho bảng Order Items
class OrderItemsTable {
  const OrderItemsTable();

  final String table = 'order_items';

  // Columns
  final String id = 'id';
  final String orderId = 'order_id';
  final String productId = 'product_id';
  final String quantity = 'quantity';
  final String price = 'price'; // Giá tại thời điểm mua
  final String createdAt = 'created_at';
}

// Các bucket storage
class StorageBuckets {
  const StorageBuckets();

  final String productImages = 'product-images';
  final String userAvatars = 'user-avatars';
}

class PaymentsTable {
  const PaymentsTable();

  final String table = 'payments';
  final String id = 'id';
  final String orderId = 'order_id';
  final String userId = 'user_id';
  final String amount = 'amount';
  final String status = 'status';
  final String method = 'method';
  final String transactionId = 'transaction_id';
  final String createdAt = 'created_at';
}
