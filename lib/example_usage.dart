import 'package:flutter/material.dart';
import 'services/services.dart';
import 'models/product.dart';
import 'models/user_profile.dart';

// Example widget demonstrating service usage
class EcommerceExample extends StatefulWidget {
  @override
  _EcommerceExampleState createState() => _EcommerceExampleState();
}

class _EcommerceExampleState extends State<EcommerceExample> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  UserProfile? currentUser;
  List<Product> products = [];
  List<CartItemWithProduct> cartItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => isLoading = true);

    try {
      // Check if user is already signed in
      currentUser = await _authService.getCurrentUserProfile();

      // Load products
      products = await _productService.getAllProducts();

      // Load cart if user is signed in
      if (currentUser != null) {
        cartItems = await _cartService.getCartItemsWithProducts();
      }
    } catch (e) {
      print('Initialization error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signUp() async {
    try {
      currentUser = await _authService.signUp(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up successful!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    }
  }

  Future<void> _signIn() async {
    try {
      currentUser = await _authService.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Reload cart items
      if (currentUser != null) {
        cartItems = await _cartService.getCartItemsWithProducts();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in successful!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      currentUser = null;
      cartItems.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed out successfully!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to add items to cart')),
      );
      return;
    }

    try {
      await _cartService.addToCart(productId: product.id, quantity: 1);

      // Reload cart items
      cartItems = await _cartService.getCartItemsWithProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to cart!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add to cart failed: $e')),
      );
    }
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      final order = await _orderService.createOrderFromCart();

      // Reload cart (should be empty now)
      cartItems = await _cartService.getCartItemsWithProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Order created successfully! Order ID: ${order.id}')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('E-commerce Example')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('E-commerce Example'),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Badge(
                label: Text('${cartItems.length}'),
                child: Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                // Navigate to cart screen
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Auth section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (currentUser == null) ...[
                  ElevatedButton(
                    onPressed: _signUp,
                    child: Text('Sign Up'),
                  ),
                  ElevatedButton(
                    onPressed: _signIn,
                    child: Text('Sign In'),
                  ),
                ] else ...[
                  Text('Welcome, ${currentUser!.name ?? currentUser!.email}!'),
                  ElevatedButton(
                    onPressed: _signOut,
                    child: Text('Sign Out'),
                  ),
                ],
              ],
            ),
          ),

          // Products section
          Expanded(
            child: products.isEmpty
                ? Center(child: Text('No products available'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          leading: product.imageUrl != null
                              ? Image.network(
                                  product.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image),
                          title: Text(product.name),
                          subtitle:
                              Text('\$${product.price.toStringAsFixed(2)}'),
                          trailing: ElevatedButton(
                            onPressed: () => _addToCart(product),
                            child: Text('Add to Cart'),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Cart/Checkout section
          if (cartItems.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cart Items: ${cartItems.length}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...cartItems.map((item) => Text(
                        '${item.product?.name ?? 'Unknown'} x ${item.cartItem.quantity}',
                      )),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _checkout,
                    child: Text('Checkout'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
