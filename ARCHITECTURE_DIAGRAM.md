# Architecture Diagram

## Task 1.2 & 1.3: Shop Screen Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        ShopScreen                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ShopScreenView (UI)                     │   │
│  │  ┌────────────────┐  ┌──────────────────────────┐  │   │
│  │  │ CategoryFilter │  │  CustomSearchBar         │  │   │
│  │  │  (Component)   │  │    (Component)           │  │   │
│  │  └────────┬───────┘  └──────────┬───────────────┘  │   │
│  │           │                     │                   │   │
│  │           └─────────┬───────────┘                   │   │
│  │                     │                               │   │
│  │           ┌─────────▼─────────┐                     │   │
│  │           │  ProductListBloc  │                     │   │
│  │           │                   │                     │   │
│  │           │  Events:          │                     │   │
│  │           │  - LoadProducts   │                     │   │
│  │           │  - FilterByCategory                     │   │
│  │           │  - SearchProducts │                     │   │
│  │           │  - RefreshProducts                      │   │
│  │           │  - ClearFilters   │                     │   │
│  │           │                   │                     │   │
│  │           │  States:          │                     │   │
│  │           │  - Initial        │                     │   │
│  │           │  - Loading        │                     │   │
│  │           │  - Loaded         │                     │   │
│  │           │  - Empty          │                     │   │
│  │           │  - Error          │                     │   │
│  │           └─────────┬─────────┘                     │   │
│  │                     │                               │   │
│  │           ┌─────────▼─────────┐                     │   │
│  │           │ ProductRepository │                     │   │
│  │           │                   │                     │   │
│  │           │  - getAllProducts()                     │   │
│  │           │  - getProductsByCategory()              │   │
│  │           │  - searchProducts()                     │   │
│  │           └─────────┬─────────┘                     │   │
│  │                     │                               │   │
│  │           ┌─────────▼─────────┐                     │   │
│  │           │   Supabase API    │                     │   │
│  │           └───────────────────┘                     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

CategoryFilter also uses:
┌──────────────────────┐
│ CategoryRepository   │
│  - getAllCategories()│
└──────────────────────┘

CustomSearchBar uses:
┌──────────────────────┐
│ SharedPreferences    │
│  - Search History    │
└──────────────────────┘
```

## Task 4.3: Order Confirmation & History Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              OrderConfirmationScreen                         │
│                                                              │
│  Input: Order + OrderItems (optional)                       │
│                                                              │
│  Displays:                                                   │
│  - Success animation                                         │
│  - Order details (number, date, status, total)              │
│  - Order items list                                          │
│  - Action buttons (history, shop, share)                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    OrderHistoryScreen                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          OrderHistoryScreenView (UI)                 │   │
│  │  ┌────────────────┐                                  │   │
│  │  │ Status Filter  │                                  │   │
│  │  │   (Chips)      │                                  │   │
│  │  └────────┬───────┘                                  │   │
│  │           │                                           │   │
│  │  ┌────────▼────────┐                                 │   │
│  │  │ Order List      │                                 │   │
│  │  │  - Order Cards  │                                 │   │
│  │  │  - Track Button │                                 │   │
│  │  │  - View Details │                                 │   │
│  │  └────────┬────────┘                                 │   │
│  │           │                                           │   │
│  │  ┌────────▼────────┐                                 │   │
│  │  │OrderHistoryBloc │                                 │   │
│  │  │                 │                                 │   │
│  │  │  Events:        │                                 │   │
│  │  │  - LoadUserOrders                                 │   │
│  │  │  - FilterOrdersByStatus                           │   │
│  │  │  - RefreshOrders                                  │   │
│  │  │  - TrackOrder   │                                 │   │
│  │  │  - LoadOrderWithItems                             │   │
│  │  │                 │                                 │   │
│  │  │  States:        │                                 │   │
│  │  │  - Initial      │                                 │   │
│  │  │  - Loading      │                                 │   │
│  │  │  - Loaded       │                                 │   │
│  │  │  - Empty        │                                 │   │
│  │  │  - Error        │                                 │   │
│  │  │  - TrackingLoaded                                 │   │
│  │  │  - WithItemsLoaded                                │   │
│  │  └────────┬────────┘                                 │   │
│  │           │                                           │   │
│  │  ┌────────▼────────┐                                 │   │
│  │  │ OrderRepository │                                 │   │
│  │  │                 │                                 │   │
│  │  │  - getUserOrders()                                │   │
│  │  │  - getUserOrdersByStatus()                        │   │
│  │  │  - getOrderById()                                 │   │
│  │  │  - getOrderWithItems()                            │   │
│  │  └────────┬────────┘                                 │   │
│  │           │                                           │   │
│  │  ┌────────▼────────┐                                 │   │
│  │  │  Supabase API   │                                 │   │
│  │  └─────────────────┘                                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Example: Search Products

```
User types "iPhone" in SearchBar
        ↓
CustomSearchBar.onChanged()
        ↓
Debounce Timer (500ms)
        ↓
widget.onSearch("iPhone")
        ↓
context.read<ProductListBloc>().add(SearchProducts("iPhone"))
        ↓
ProductListBloc._onSearchProducts()
        ↓
emit(ProductListLoading())
        ↓
ProductRepository.searchProducts("iPhone")
        ↓
Supabase query: SELECT * WHERE name ILIKE '%iPhone%' OR description ILIKE '%iPhone%'
        ↓
Returns List<Product>
        ↓
emit(ProductListLoaded(products: results, searchQuery: "iPhone"))
        ↓
BlocBuilder rebuilds UI with search results
        ↓
User sees filtered products
        ↓
Search saved to SharedPreferences
```

## Data Flow Example: Filter by Category

```
User taps "Smartphones" category chip
        ↓
CategoryFilter._onCategorySelected(categoryId)
        ↓
context.read<ProductListBloc>().add(FilterByCategory(categoryId))
        ↓
ProductListBloc._onFilterByCategory()
        ↓
emit(ProductListLoading())
        ↓
ProductRepository.getProductsByCategory(categoryId)
        ↓
Supabase query: SELECT * WHERE category_id = categoryId AND is_available = true
        ↓
Returns List<Product>
        ↓
emit(ProductListLoaded(products: results, selectedCategoryId: categoryId))
        ↓
BlocBuilder rebuilds UI with filtered products
        ↓
CategoryFilter highlights selected chip
```

## Data Flow Example: View Order History

```
User navigates to OrderHistoryScreen(userId: "abc123")
        ↓
BlocProvider creates OrderHistoryBloc
        ↓
OrderHistoryBloc initialized with LoadUserOrders event
        ↓
OrderHistoryBloc._onLoadUserOrders()
        ↓
emit(OrderHistoryLoading())
        ↓
OrderRepository.getUserOrders("abc123")
        ↓
Supabase query: SELECT * FROM orders WHERE user_id = "abc123" ORDER BY created_at DESC
        ↓
Returns List<Order>
        ↓
emit(OrderHistoryLoaded(orders: results))
        ↓
BlocBuilder rebuilds UI with order list
        ↓
User sees their orders
        ↓
User taps status filter "Shipping"
        ↓
FilterOrdersByStatus event dispatched
        ↓
Repository filters orders by status
        ↓
UI updates with filtered results
```

## State Management Pattern

All features use the BLoC (Business Logic Component) pattern:

1. **UI Layer** (Views/Screens)
   - Dispatches Events to BLoC
   - Listens to State changes from BLoC
   - Renders UI based on current State

2. **BLoC Layer** (Business Logic)
   - Receives Events
   - Processes business logic
   - Calls Repository methods
   - Emits new States

3. **Repository Layer** (Data Access)
   - Communicates with Supabase
   - Handles data transformation
   - Returns domain models

4. **Model Layer** (Data Models)
   - Freezed classes for immutability
   - JSON serialization
   - Type safety

## Benefits of This Architecture

✅ **Separation of Concerns**: UI, Business Logic, and Data are separate
✅ **Testability**: Each layer can be tested independently
✅ **Maintainability**: Changes in one layer don't affect others
✅ **Scalability**: Easy to add new features
✅ **Type Safety**: Strong typing with Dart and Freezed
✅ **State Predictability**: Clear state transitions
✅ **Reusability**: Components and BLoCs can be reused
