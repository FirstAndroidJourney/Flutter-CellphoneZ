import '../models/order.dart';
import '../models/order_item.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  @override
  String get tableName => ordersSchema.table;

  // Get all orders as Order objects
  Future<List<Order>> getAllOrders() async {
    try {
      final data = await getAll();
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get orders for specific user
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await queryBuilder
          .select()
          .eq(ordersSchema.userId, userId)
          .order(createdAtColumn, ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  // Helper method to safely map database JSON to Order model
  Order _mapToOrder(Map<String, dynamic> json) {
    return Order.fromJson({
      'id': json['id'] ?? '',
      'user_id': json['user_id'] ?? '',
      'total_price':
          (json['total_amount'] ?? json['total_price'] ?? 0).toDouble(),
      'status': json['status'] ?? 'pending',
      'created_at': json['created_at'] ?? DateTime.now().toIso8601String(),
    });
  }

  // Get order by ID
  Future<Order?> getOrderById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? _mapToOrder(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  // Create new order
  Future<Order> createOrder(Order order) async {
    try {
      final data = await create(order.toJson());
      return Order.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order
  Future<Order> updateOrder(String id, Order order) async {
    try {
      final data = await update(id, order.toJson());
      return _mapToOrder(data);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // Update order status
  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final response = await queryBuilder
          .update({'status': status.name})
          .eq('id', id)
          .select()
          .single();
      return _mapToOrder(response);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Delete order
  Future<void> deleteOrder(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('status', status.name)
          .order('created_at', ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  // Get user orders by status
  Future<List<Order>> getUserOrdersByStatus(
      String userId, OrderStatus status) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('user_id', userId)
          .eq('status', status.name)
          .order('created_at', ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders by status: $e');
    }
  }

  // Get order with items (if needed, depends on your schema structure)
  Future<Order?> getOrderWithItems(String orderId) async {
    try {
      // Get order details
      final orderData = await getById(orderId);
      if (orderData == null) return null;

      // Get order items from order_items table
      final orderItemsResponse =
          await client.from('order_items').select().eq('order_id', orderId);

      final orderItemsData =
          List<Map<String, dynamic>>.from(orderItemsResponse);
      final orderItems = orderItemsData
          .map((json) => OrderItem.fromJson({
                'id': json['id'] ?? '',
                'order_id': json['order_id'] ?? '',
                'product_id': json['product_id'] ?? '',
                'quantity': json['quantity'] ?? 1,
                'price': (json['price'] ?? 0).toDouble(),
              }))
          .toList();

      // Create order with items
      final order = _mapToOrder(orderData);
      return order.copyWith(items: orderItems);
    } catch (e) {
      throw Exception('Failed to fetch order with items: $e');
    }
  }

  // Paginated methods
  Future<List<Order>> getAllOrdersPaginated({
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await queryBuilder
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated orders: $e');
    }
  }

  Future<List<Order>> getOrdersByStatusPaginated({
    required OrderStatus status,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('status', status.name)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => _mapToOrder(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated orders by status: $e');
    }
  }
}
