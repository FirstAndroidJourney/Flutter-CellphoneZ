import '../models/order_item.dart';
import 'base_repository.dart';

class OrderItemRepository extends BaseRepository {
  @override
  String get tableName => orderItemsSchema.table;

  // Get all order items as OrderItem objects
  Future<List<OrderItem>> getAllOrderItems() async {
    try {
      final data = await getAll();
      return data.map((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch order items: $e');
    }
  }

  // Get order items for specific order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await queryBuilder.select().eq(orderItemsSchema.orderId, orderId);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch order items: $e');
    }
  }

  // Get order item by ID
  Future<OrderItem?> getOrderItemById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? OrderItem.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch order item: $e');
    }
  }

  // Create new order item
  Future<OrderItem> createOrderItem(OrderItem orderItem) async {
    try {
      final data = await create(orderItem.toJson());
      return OrderItem.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create order item: $e');
    }
  }

  // Create multiple order items
  Future<List<OrderItem>> createOrderItems(List<OrderItem> orderItems) async {
    try {
      final itemsData = orderItems.map((item) => item.toJson()).toList();
      final response = await queryBuilder.insert(itemsData).select();
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to create order items: $e');
    }
  }

  // Update order item
  Future<OrderItem> updateOrderItem(String id, OrderItem orderItem) async {
    try {
      final data = await update(id, orderItem.toJson());
      return OrderItem.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update order item: $e');
    }
  }

  // Delete order item
  Future<void> deleteOrderItem(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to delete order item: $e');
    }
  }

  // Delete all items for an order
  Future<void> deleteOrderItems(String orderId) async {
    try {
      await queryBuilder.delete().eq('orderId', orderId);
    } catch (e) {
      throw Exception('Failed to delete order items: $e');
    }
  }

  // Get order items with product details (if you want to join with products table)
  Future<List<Map<String, dynamic>>> getOrderItemsWithProducts(
      String orderId) async {
    try {
      final response = await client.from('order_items').select('''
            *,
            products:productId (
              id,
              name,
              imageUrl,
              description
            )
          ''').eq('orderId', orderId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch order items with products: $e');
    }
  }
}
