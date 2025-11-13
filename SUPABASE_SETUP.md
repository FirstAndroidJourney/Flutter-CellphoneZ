# Supabase Integration Setup Guide

## 1. Supabase Project Setup

### Tạo Supabase Project
1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard)
2. Tạo project mới
3. Lấy Project URL và anon key từ Settings > API

### Database Setup
1. Mở SQL Editor trong Supabase Dashboard
2. Copy và paste nội dung file `supabase_schema.sql`
3. Chạy script để tạo tables và policies

## 2. Flutter App Configuration

### Cập nhật Supabase Config
Trong file `lib/services/app_config.dart`, thay đổi:
```dart
class SupabaseConfig {
  static const String url = 'YOUR_ACTUAL_SUPABASE_URL';
  static const String anonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY';
}
```

### Cập nhật main.dart
```dart
import 'package:flutter/material.dart';
import 'services/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependencies and initialize Supabase
  await setupDependencies();
  
  runApp(MyApp());
}
```

## 3. Cách sử dụng Services

### Authentication
```dart
import 'package:get_it/get_it.dart';
import 'services/auth_service.dart';

final AuthService authService = AuthService();

// Sign up
final userProfile = await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  name: 'John Doe',
);

// Sign in
final userProfile = await authService.signIn(
  email: 'user@example.com',
  password: 'password123',
);

// Get current user
final currentUser = await authService.getCurrentUserProfile();

// Sign out
await authService.signOut();
```

### Products
```dart
import 'services/product_service.dart';

final ProductService productService = ProductService();

// Get all products
final products = await productService.getAllProducts();

// Search products
final searchResults = await productService.searchProducts('iPhone');

// Get products by category
final categoryProducts = await productService.getProductsByCategory(categoryId);

// Get featured products
final featuredProducts = await productService.getFeaturedProducts(limit: 10);
```

### Cart Management
```dart
import 'services/cart_service.dart';

final CartService cartService = CartService();

// Add to cart
await cartService.addToCart(
  productId: 'product-id',
  quantity: 2,
);

// Get cart items
final cartItems = await cartService.getCartItemsWithProducts();

// Update quantity
await cartService.updateQuantity(cartItemId, 3);

// Remove from cart
await cartService.removeFromCart(cartItemId);

// Get cart total
final total = await cartService.getCartTotal();

// Clear cart
await cartService.clearCart();
```

### Order Management
```dart
import 'services/order_service.dart';

final OrderService orderService = OrderService();

// Create order from cart
final order = await orderService.createOrderFromCart();

// Get user orders
final orders = await orderService.getCurrentUserOrders();

// Get order details
final orderWithItems = await orderService.getOrderWithItems(orderId);

// Update order status
await orderService.updateOrderStatus(orderId, OrderStatus.shipping);

// Cancel order
await orderService.cancelOrder(orderId);
```

## 4. Dependency Injection Usage

Tất cả repositories đã được register trong GetIt container:

```dart
import 'package:get_it/get_it.dart';
import 'repository/repositories.dart';

// Get repository instances
final authRepo = getIt<AuthRepository>();
final productRepo = getIt<ProductRepository>();
final cartRepo = getIt<CartRepository>();
final orderRepo = getIt<OrderRepository>();
final userRepo = getIt<UserRepository>();
```

## 5. Error Handling

Tất cả services đều throw exceptions với thông báo lỗi rõ ràng:

```dart
try {
  final products = await productService.getAllProducts();
} catch (e) {
  print('Error fetching products: $e');
  // Handle error in UI
}
```

## 6. Real-time Features (Optional)

Để sử dụng real-time features của Supabase:

```dart
import 'services/supabase_client.dart';

// Listen to product changes
supabase.channel('products')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'products',
    callback: (payload) {
      print('Product changed: ${payload.toString()}');
    },
  )
  .subscribe();
```

## 7. File Upload (Optional)

Để upload images:

```dart
import 'dart:io';

// Upload product image
final file = File('path/to/image.jpg');
final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

final response = await supabase.storage
    .from('product-images')
    .upload(fileName, file);

// Get public URL
final imageUrl = supabase.storage
    .from('product-images')
    .getPublicUrl(fileName);
```

## 8. Email Templates Configuration (Quan trọng!)

### Cấu hình OTP Email cho Password Reset

Để gửi OTP thay vì Magic Link khi reset password:

1. Vào **Supabase Dashboard** → **Authentication** → **Email Templates**

2. Chọn template **"Reset Password"**

3. Thay đổi nội dung email để hiển thị OTP:

```html
<h2>Reset Your Password</h2>
<p>You have requested to reset your password. Use the OTP code below:</p>
<h1 style="font-size: 32px; letter-spacing: 5px;">{{ .Token }}</h1>
<p>This code will expire in 60 minutes.</p>
<p>If you didn't request this, please ignore this email.</p>
```

4. **XÓA hoặc comment out** đoạn magic link để tránh nhầm lẫn:
```html
<!-- <a href="{{ .ConfirmationURL }}">Reset Password</a> -->
```

5. Tương tự với template **"Confirm Signup"** nếu dùng OTP:

```html
<h2>Confirm your signup</h2>
<p>Use this OTP code to confirm your email:</p>
<h1 style="font-size: 32px; letter-spacing: 5px;">{{ .Token }}</h1>
<p>This code will expire in 60 minutes.</p>
```

### Tắt Email Confirmations (Optional)

Nếu muốn user login ngay không cần confirm email:

1. Vào **Authentication** → **Settings** 
2. Tắt **"Enable email confirmations"**

**Lưu ý**: Flow hiện tại đã dùng `signInWithOtp` với `shouldCreateUser: false` để gửi OTP cho reset password, giống như flow sign up.

## 9. Testing

Để test services, bạn có thể mock repositories:

```dart
// Test example
void main() {
  group('ProductService Tests', () {
    test('should return products', () async {
      // Setup mock repository
      // Test service methods
    });
  });
}
```

## Notes

- Tất cả repository methods đều async và trả về Future
- Services handle business logic và validation
- Repositories handle database operations
- Error handling được implement ở cả repository và service layers
- Row Level Security (RLS) đã được setup trong database
- UUID được sử dụng làm primary key cho tất cả tables