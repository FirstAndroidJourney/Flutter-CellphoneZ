# Task Breakdown - Flutter CellphoneZ E-Commerce App

**Project Type**: Flutter E-Commerce Mobile App  
**Backend**: Supabase (PostgreSQL + Storage)  
**State Management**: BLoC + Freezed  
**Architecture**: Repository Pattern + Clean Architecture  

---

## 📋 ADMIN FLOW

### 1️⃣ CRUD Product

#### Task 1.1: Product Model & Database Schema
- **Status**: Foundation
- **Description**:
  - Xác minh schema Product trong `supabase_schema.sql`
  - Fields cần: id, name, description, price, category_id, image_url, is_available, created_at
  - Cấu hình DatabaseSchema cho Product table
- **Files to modify**:
  - `lib/models/product.dart` (extend từ freezed model)
  - `lib/clients/database_client.dart` (cập nhật schema)
- **Dependencies**: Supabase setup (đã xong)
- **Estimated Time**: 2 hours

#### Task 1.2: Product Repository & Service
- **Status**: Foundation
- **Description**:
  - Tạo ProductRepository với methods: getAll, getById, create, update, delete
  - Tạo ProductService wrapper (business logic)
  - Implement error handling & logging
- **Files to create/modify**:
  - `lib/repository/product_repository.dart`
  - `lib/services/product_service.dart`
  - `lib/common/app_logger.dart`
- **Dependencies**: Task 1.1
- **Estimated Time**: 4 hours

#### Task 1.3: Product Image Upload (Supabase Storage)
- **Status**: Critical Research
- **Description**:
  - Nghiên cứu Supabase Storage API
  - Setup storage bucket: `product-images`
  - Implement image upload logic:
    - Chọn ảnh từ gallery
    - Compress ảnh (để giảm size)
    - Upload lên Supabase Storage
    - Lấy public URL từ uploaded image
  - Error handling for upload failures
  - Delete image khi product bị xóa
- **Research Topics**:
  - Supabase Storage API documentation
  - Flutter image_picker package
  - Image compression libraries (image, flutter_native_splash)
  - File upload best practices
- **Files to create/modify**:
  - `lib/services/storage_service.dart` (mới)
  - `lib/repository/product_repository.dart` (update)
  - `pubspec.yaml` (thêm dependencies: image_picker, image)
- **Dependencies**: Task 1.2, Supabase setup
- **Estimated Time**: 6 hours (3h research + 3h implement)

#### Task 1.4: Product BLoC & UI (Admin)
- **Status**: Feature
- **Description**:
  - Tạo ProductAdminBloc với events: LoadProducts, CreateProduct, UpdateProduct, DeleteProduct
  - Admin screen: Product list view
  - Admin screen: Create/Edit product form
    - Form validation
    - Image picker integration
    - Upload progress indicator
  - Admin screen: Product detail & delete confirmation
- **Files to create**:
  - `lib/screens/admin/blocs/product_admin_bloc.dart`
  - `lib/screens/admin/views/product_list_screen.dart`
  - `lib/screens/admin/views/product_form_screen.dart`
  - `lib/screens/admin/views/components/product_form.dart`
- **Dependencies**: Task 1.3
- **Estimated Time**: 8 hours

---

### 2️⃣ CRUD Category

#### Task 2.1: Category Model & Database Schema
- **Status**: Foundation
- **Description**:
  - Xác minh schema Category trong database
  - Fields: id, name, description, icon_url, created_at
  - Cấu hình DatabaseSchema
- **Files to modify**:
  - `lib/models/category.dart` (extend từ freezed)
  - `lib/clients/database_client.dart`
- **Dependencies**: Supabase setup
- **Estimated Time**: 1.5 hours

#### Task 2.2: Category Repository & Service
- **Status**: Foundation
- **Description**:
  - CategoryRepository: getAll, getById, create, update, delete
  - CategoryService wrapper
- **Files to create/modify**:
  - `lib/repository/category_repository.dart`
  - `lib/services/category_service.dart`
- **Dependencies**: Task 2.1
- **Estimated Time**: 3 hours

#### Task 2.3: Category Admin UI
- **Status**: Feature
- **Description**:
  - Admin screen: Category list
  - Admin screen: Create/Edit category form
  - Admin screen: Delete with confirmation
- **Files to create**:
  - `lib/screens/admin/blocs/category_admin_bloc.dart`
  - `lib/screens/admin/views/category_list_screen.dart`
  - `lib/screens/admin/views/category_form_screen.dart`
- **Dependencies**: Task 2.2
- **Estimated Time**: 6 hours

---

## 👤 USER FLOW

### 3️⃣ Shop (Product Discovery)

#### Task 3.1: Product List UI
- **Status**: Feature
- **Description**:
  - User screen: View all products in grid/list
  - Product card component (name, image, price, rating)
  - Pull-to-refresh
  - Pagination or infinite scroll
  - Loading skeleton/shimmer
- **Files to create/modify**:
  - `lib/screens/shop/views/shop_screen.dart`
  - `lib/screens/shop/views/components/product_card.dart`
  - `lib/screens/shop/blocs/product_list_bloc.dart`
- **Dependencies**: Task 1.2
- **Estimated Time**: 5 hours

#### Task 3.2: Category Filter
- **Status**: Feature
- **Description**:
  - Filter products by category
  - Category chips/tabs at top of product list
  - "All Products" option
  - Update product list when category changes
- **Files to create/modify**:
  - `lib/screens/shop/blocs/product_list_bloc.dart` (update)
  - `lib/screens/shop/views/components/category_filter.dart`
  - `lib/screens/shop/views/shop_screen.dart` (update)
- **Dependencies**: Task 3.1, Task 2.2
- **Estimated Time**: 3 hours

#### Task 3.3: Product Search
- **Status**: Feature
- **Description**:
  - Search bar component
  - Debounced search query
  - Filter products by name/description
  - Search history (optional - use local storage)
  - Clear search button
- **Files to create/modify**:
  - `lib/screens/shop/views/components/search_bar.dart`
  - `lib/screens/shop/blocs/product_list_bloc.dart` (add search events)
  - `lib/screens/shop/views/shop_screen.dart` (update)
- **Dependencies**: Task 3.1
- **Estimated Time**: 4 hours

---

### 4️⃣ Product Info & Cart

#### Task 4.1: Product Detail Screen
- **Status**: Feature
- **Description**:
  - Display product details:
    - Large image with image carousel/slider
    - Product name, description, price
    - Category, rating, reviews count
    - Stock status
  - Related products (same category)
- **Files to create**:
  - `lib/screens/product_detail/views/product_detail_screen.dart`
  - `lib/screens/product_detail/blocs/product_detail_bloc.dart`
  - `lib/screens/product_detail/views/components/image_carousel.dart`
- **Dependencies**: Task 3.1
- **Estimated Time**: 4 hours

#### Task 4.2: Add to Cart
- **Status**: Feature
- **Description**:
  - Quantity selector component
  - Add to cart button
  - Cart update logic in BLoC
  - Toast/snackbar feedback
  - Update cart icon in AppBar
- **Files to create/modify**:
  - `lib/screens/product_detail/views/product_detail_screen.dart` (update)
  - `lib/repository/cart_repository.dart` (implement)
  - `lib/screens/shop/blocs/cart_bloc.dart` (implement/update)
- **Dependencies**: Task 1.2, cart model exists
- **Estimated Time**: 3 hours

#### Task 4.3: Cart Info Screen
- **Status**: Feature
- **Description**:
  - Display cart items list
  - Each item shows: product image, name, quantity, price, subtotal
  - Edit quantity for each item
  - Remove item from cart
  - Cart summary: subtotal, tax, shipping, total
  - Proceed to checkout button
- **Files to create/modify**:
  - `lib/screens/cart/views/cart_screen.dart`
  - `lib/screens/cart/blocs/cart_bloc.dart`
  - `lib/screens/cart/views/components/cart_item_card.dart`
- **Dependencies**: Task 4.2
- **Estimated Time**: 5 hours

---

### 5️⃣ Order Management

#### Task 5.1: Order Model & Repository
- **Status**: Foundation
- **Description**:
  - OrderItem model (product, quantity, price per unit)
  - Order model (items, user, status, total, delivery address, payment method)
  - Order database schema
  - OrderRepository & OrderService
- **Files to create/modify**:
  - `lib/models/order.dart` (update/verify freezed model)
  - `lib/models/order_item.dart` (update/verify)
  - `lib/repository/order_repository.dart`
  - `lib/services/order_service.dart`
- **Dependencies**: Supabase setup, Task 1.2
- **Estimated Time**: 3 hours

#### Task 5.2: Order Calculation & Pricing
- **Status**: Feature
- **Description**:
  - Calculate item subtotal: quantity × price
  - Calculate tax: subtotal × tax_rate (e.g., 10%)
  - Calculate shipping fee (based on location or fixed)
  - Calculate total: subtotal + tax + shipping - discount
  - Handle discount/coupon logic (optional)
  - Price formatting with currency
- **Files to create**:
  - `lib/services/order_calculation_service.dart`
  - Add tax_rate constant in `lib/constants.dart`
- **Dependencies**: Task 5.1
- **Estimated Time**: 3 hours

#### Task 5.3: Delivery Address Selection (Map Integration)
- **Status**: Critical Feature + Research
- **Description**:
  - Integrate Google Maps / Flutter Map
  - User can tap on map to select delivery location
  - Show selected location with marker
  - Convert map coordinates → address (reverse geocoding)
  - Display selected address in checkout form
  - Allow manual address editing
  - Save favorite addresses
- **Research Topics**:
  - Google Maps Flutter SDK / flutter_map package
  - Reverse geocoding (Google Geocoding API or Supabase functions)
  - Location permissions (Android/iOS)
  - Map markers and interactions
- **Files to create/modify**:
  - `lib/services/location_service.dart` (mới)
  - `lib/screens/checkout/views/address_picker_screen.dart`
  - `lib/screens/checkout/views/components/map_picker.dart`
  - `pubspec.yaml` (add: google_maps_flutter or flutter_map)
  - Android/iOS configuration for maps & location
- **Dependencies**: Task 5.1
- **Estimated Time**: 8 hours (3h research + 5h implement)

#### Task 5.4: Order Checkout Screen
- **Status**: Feature
- **Description**:
  - Display order summary:
    - Cart items
    - Pricing breakdown (subtotal, tax, shipping, total)
    - Delivery address
  - Buttons:
    - Edit address (navigate to map)
    - Select payment method
    - Place order button
  - Order confirmation after success
- **Files to create/modify**:
  - `lib/screens/checkout/views/checkout_screen.dart`
  - `lib/screens/checkout/blocs/checkout_bloc.dart`
  - `lib/screens/checkout/views/components/order_summary.dart`
- **Dependencies**: Task 5.2, Task 5.3
- **Estimated Time**: 5 hours

---

### 6️⃣ Payment

#### Task 6.1: Payment Gateway Research
- **Status**: Critical Research
- **Description**:
  - Research payment options:
    - Stripe (international)
    - VNPay (Vietnam)
    - PayPal
    - Other local payment providers
  - Evaluate:
    - Integration complexity
    - Transaction fees
    - Supported payment methods
    - Documentation quality
    - PCI compliance
- **Deliverable**: Research document with recommendations
- **Estimated Time**: 4 hours

#### Task 6.2: Payment Integration (Based on Research)
- **Status**: Feature
- **Description**:
  - Integrate chosen payment gateway
  - Payment form/method selection
  - Handle payment success/failure
  - Create transaction record in database
  - Update order status to "paid"
  - Error handling and user feedback
- **Files to create/modify**:
  - `lib/services/payment_service.dart`
  - `lib/screens/payment/views/payment_screen.dart`
  - `lib/screens/payment/blocs/payment_bloc.dart`
  - `pubspec.yaml` (add payment package)
- **Dependencies**: Task 6.1, Task 5.4
- **Estimated Time**: 8 hours

#### Task 6.3: Order Confirmation & History
- **Status**: Feature
- **Description**:
  - Order confirmation screen after payment
  - Display order number, receipt
  - Option to share/download receipt
  - View order history
  - Track order status
- **Files to create/modify**:
  - `lib/screens/order_confirmation/views/order_confirmation_screen.dart`
  - `lib/screens/order_history/views/order_history_screen.dart`
  - `lib/screens/order_history/blocs/order_history_bloc.dart`
- **Dependencies**: Task 6.2
- **Estimated Time**: 4 hours

---

## 📊 TASK SUMMARY

### Phân loại theo độ ưu tiên:

| Priority | Category | Tasks | Time |
|----------|----------|-------|------|
| 🔴 CRITICAL | Foundation | 1.1, 1.2, 2.1, 2.2, 5.1 | 14 hrs |
| 🟠 HIGH | Core Features | 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.2 | 24 hrs |
| 🟡 MEDIUM | Advanced Features | 1.3, 1.4, 2.3, 5.3, 5.4, 6.2, 6.3 | 41 hrs |
| 🟢 RESEARCH | Investigation | 6.1 | 4 hrs |
| **TOTAL** | | **20 Tasks** | **~83 hours** |

---

## 🔄 Implementation Order (Recommended)

### Phase 1: Foundation (14 hours)
1. Task 1.1 - Product Model
2. Task 2.1 - Category Model
3. Task 1.2 - Product Repository
4. Task 2.2 - Category Repository
5. Task 5.1 - Order Model & Repository

### Phase 2: Core User Features (24 hours)
6. Task 3.1 - Product List UI
7. Task 3.2 - Category Filter
8. Task 3.3 - Product Search
9. Task 4.1 - Product Detail Screen
10. Task 4.2 - Add to Cart
11. Task 4.3 - Cart Screen
12. Task 5.2 - Order Calculation

### Phase 3: Advanced Features (49 hours)
13. Task 1.3 - Product Image Upload (Research + Implement)
14. Task 1.4 - Product Admin UI
15. Task 2.3 - Category Admin UI
16. Task 6.1 - Payment Gateway Research
17. Task 5.3 - Map Integration & Address Selection (Research + Implement)
18. Task 5.4 - Checkout Screen
19. Task 6.2 - Payment Integration
20. Task 6.3 - Order Confirmation & History

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter 3.2+
- **State Management**: BLoC + Cubit
- **Code Generation**: Freezed, JSON Serializable
- **UI Components**: Material Design, Custom widgets

### Backend
- **Database**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage
- **Authentication**: Supabase Auth
- **API**: Supabase SDK + REST APIs

### Key Dependencies to Add
```yaml
# Image handling
image_picker: ^1.0.0
image: ^4.0.0

# Maps & Location
google_maps_flutter: ^2.5.0  # or flutter_map: ^5.0.0
geolocator: ^9.0.0
geocoding: ^2.0.0

# Payment (TBD after research)
stripe_flutter: ^10.0.0  # or other payment SDK

# Forms & Validation
formz: ^0.6.0

# Network images
cached_network_image: ^3.2.0 # already exists

# Utility
intl: ^0.19.0  # for date/currency formatting
uuid: ^4.0.0
```

---

## 📝 Notes

### Image Upload Best Practices
- Compress images before upload (target: < 2MB)
- Use progressive JPEGs
- Generate thumbnail for display
- Implement retry logic for failed uploads
- Show upload progress to user

### Map Integration Considerations
- Handle location permissions properly
- Cache selected locations
- Provide fallback when map fails
- Validate coordinates
- Consider using FakeFirebaseGeocodingPlatform for testing

### Payment Gateway Tips
- Always process payments on backend (security)
- Implement webhook handlers for payment status updates
- Store transaction IDs and reference numbers
- Log all payment attempts for debugging
- Test with sandbox environment first

---

## ✅ Checklist for Each Task

```markdown
- [ ] Read/understand requirements
- [ ] Set up files and folder structure
- [ ] Implement core logic
- [ ] Add error handling
- [ ] Add logging
- [ ] Write/update tests (if applicable)
- [ ] Code review
- [ ] Merge to main branch
```

---

**Created**: October 23, 2025  
**Project**: Flutter CellphoneZ E-Commerce
