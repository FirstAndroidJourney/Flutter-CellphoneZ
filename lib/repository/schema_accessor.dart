import '../services/database_schema.dart';

/// Mixin cung cấp truy cập thuận tiện đến schema database
/// 
/// Mixin này cung cấp các getter để truy cập schema mà không cần gọi 
/// DatabaseSchema static class trực tiếp, giúp giảm boilerplate code.
mixin SchemaAccessor {
  // Trả về tên bảng cụ thể cho repository
  String get tableName;
  
  // Các trường chung cho tất cả các bảng
  String get idColumn => DatabaseSchema.common.id;
  String get createdAtColumn => DatabaseSchema.common.createdAt;
  String get updatedAtColumn => DatabaseSchema.common.updatedAt;
  String get userIdColumn => DatabaseSchema.common.userId;
  
  // Getter tiện ích để truy cập tên các bảng
  TableNames get tables => DatabaseSchema.tables;
  
  // Getter tiện ích để truy cập schema các bảng
  UsersTable get usersSchema => DatabaseSchema.users;
  ProductsTable get productsSchema => DatabaseSchema.products;
  CategoriesTable get categoriesSchema => DatabaseSchema.categories;
  CartItemsTable get cartItemsSchema => DatabaseSchema.cartItems;
  OrdersTable get ordersSchema => DatabaseSchema.orders;
  OrderItemsTable get orderItemsSchema => DatabaseSchema.orderItems;
}