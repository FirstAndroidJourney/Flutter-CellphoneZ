import '../models/cart_item.dart';
import 'base_repository.dart';

class CartRepository extends BaseRepository {
  @override
  String get tableName => 'cart_items';

  // Get all cart items as CartItem objects
  Future<List<CartItem>> getAllCartItems() async {
    try {
      final data = await getAll();
      return data.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
    }
  }

  // Get cart items for specific user
  Future<List<CartItem>> getUserCartItems(String userId) async {
    try {
      final response = await queryBuilder.select().eq('userId', userId);
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user cart items: $e');
    }
  }

  // Get cart item by ID
  Future<CartItem?> getCartItemById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? CartItem.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch cart item: $e');
    }
  }

  // Add item to cart
  Future<CartItem> addToCart(CartItem cartItem) async {
    try {
      // Check if item already exists in cart
      final existingItem = await getCartItemByUserAndProduct(
        cartItem.userId,
        cartItem.productId,
      );

      if (existingItem != null) {
        // Update quantity if item exists
        final updatedQuantity = existingItem.quantity + cartItem.quantity;
        return await updateCartItem(
          existingItem.id,
          existingItem.copyWith(quantity: updatedQuantity),
        );
      } else {
        // Create new cart item
        final data = await create(cartItem.toJson());
        return CartItem.fromJson(data);
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Update cart item
  Future<CartItem> updateCartItem(String id, CartItem cartItem) async {
    try {
      final data = await update(id, cartItem.toJson());
      return CartItem.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Get specific cart item by user and product
  Future<CartItem?> getCartItemByUserAndProduct(
      String userId, String productId) async {
    try {
      final response = await queryBuilder
          .select()
          .eq('userId', userId)
          .eq('productId', productId)
          .maybeSingle();
      return response != null ? CartItem.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch cart item: $e');
    }
  }

  // Clear all cart items for user
  Future<void> clearUserCart(String userId) async {
    try {
      await queryBuilder.delete().eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to clear user cart: $e');
    }
  }

  // Update item quantity
  Future<CartItem> updateQuantity(String id, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(id);
        throw Exception('Item removed from cart');
      }

      final response = await queryBuilder
          .update({'quantity': quantity})
          .eq('id', id)
          .select()
          .single();
      return CartItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Get cart items count for user
  Future<int> getUserCartItemsCount(String userId) async {
    try {
      final response =
          await queryBuilder.select('quantity').eq('userId', userId);
      final data = List<Map<String, dynamic>>.from(response);
      return data.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      throw Exception('Failed to get cart items count: $e');
    }
  }
}
