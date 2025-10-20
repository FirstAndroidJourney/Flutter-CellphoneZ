import '../models/order.dart';
import '../models/order_item.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  @override
  String get tableName => 'orders';

  // Get all orders as Order objects
  Future<List<Order>> getAllOrders() async {
    try {
      final data = await getAll();
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get orders for specific user
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('userId', userId)
          .order('createdAt', ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? Order.fromJson(data) : null;
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
      return Order.fromJson(data);
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
      return Order.fromJson(response);
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
          .order('createdAt', ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Order.fromJson(json)).toList();
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
          .eq('userId', userId)
          .eq('status', status.name)
          .order('createdAt', ascending: false);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => Order.fromJson(json)).toList();
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
          await client.from('order_items').select().eq('orderId', orderId);

      final orderItemsData =
          List<Map<String, dynamic>>.from(orderItemsResponse);
      final orderItems =
          orderItemsData.map((json) => OrderItem.fromJson(json)).toList();

      // Create order with items
      final order = Order.fromJson(orderData);
      return order.copyWith(items: orderItems);
    } catch (e) {
      throw Exception('Failed to fetch order with items: $e');
    }
  }
}
