// Ví dụ minh họa cách sử dụng Database Schema

import 'package:shop/services/database_schema.dart';

/// Ví dụ minh họa cách sử dụng Database Schema để tránh lỗi khi query
///
/// File này chỉ để tham khảo, không sử dụng trong ứng dụng thực tế.
class SchemaUsageExample {
  // Ví dụ cách sử dụng schema khi thực hiện query
  void exampleUsingSchema() {
    // Thay vì hardcode như thế này (dễ gây lỗi typo):
    const String wrongWayExample =
        "SELECT * FROM products WHERE category_id = '123'";
    print("Cách làm có khả năng gây lỗi: $wrongWayExample");

    // Sử dụng schema để tránh lỗi typo:
    final productsTable = DatabaseSchema.products;

    final query =
        "SELECT * FROM ${productsTable.table} WHERE ${productsTable.categoryId} = '123'";
    print("Cách làm an toàn hơn: $query");

    // Trong Supabase Flutter SDK có thể sử dụng như sau:
    /*
    final result = await supabaseClient
        .from(DatabaseSchema.tables.products)
        .select()
        .eq(DatabaseSchema.products.categoryId, '123')
        .eq(DatabaseSchema.products.isAvailable, true)
        .order(DatabaseSchema.products.createdAt, ascending: false);
    */
  }

  // Ví dụ cách kết hợp với việc truy vấn nhiều bảng
  void exampleJoinQuery() {
    final products = DatabaseSchema.products;
    final categories = DatabaseSchema.categories;
    final orders = DatabaseSchema.orders;
    final orderItems = DatabaseSchema.orderItems;

    // Join query example
    final joinQuery =
        "SELECT p.${products.id}, p.${products.name} FROM ${products.table} p"
        " JOIN ${categories.table} c ON p.${products.categoryId} = c.${categories.id}";
    print("Join query: $joinQuery");

    // Nested relationships example
    final nestedQuery = "SELECT o.${orders.id} FROM ${orders.table} o"
        " JOIN ${orderItems.table} oi ON oi.${orderItems.orderId} = o.${orders.id}";
    print("Nested query: $nestedQuery");
  }
}

// Ví dụ về cách mở rộng schema trong tương lai
/// Ví dụ thêm bảng mới (Đã chuyển thành top-level class)
class ReviewsTable {
  const ReviewsTable();

  final String table = 'product_reviews';

  // Columns
  final String id = 'id';
  final String productId = 'product_id';
  final String userId = 'user_id';
  final String rating = 'rating';
  final String comment = 'comment';
  final String createdAt = 'created_at';
}
