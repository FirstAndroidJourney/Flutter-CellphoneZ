# Hướng dẫn sử dụng DatabaseSchema

`DatabaseSchema` là một class tiện ích giúp quản lý tên bảng và cột trong Supabase, tránh lỗi typo khi query và đảm bảo consistency trong toàn bộ ứng dụng.

## Cấu trúc

File `database_schema.dart` định nghĩa cấu trúc schema với các thành phần:

1. `TableNames`: Chứa tên các bảng
2. `CommonColumns`: Chứa các cột phổ biến xuất hiện trong nhiều bảng
3. Class riêng cho từng bảng: `UsersTable`, `ProductsTable`, v.v.
4. `StorageBuckets`: Quản lý tên các bucket trong Supabase Storage

## Cách sử dụng

### 1. Truy cập tên bảng

```dart
// Thay vì hardcode tên bảng
final products = await supabase.from('products').select();

// Sử dụng DatabaseSchema
final products = await supabase.from(DatabaseSchema.tables.products).select();
```

### 2. Truy cập tên cột

```dart
// Thay vì hardcode tên cột
final availableProducts = await supabase
    .from('products')
    .select()
    .eq('is_available', true);

// Sử dụng DatabaseSchema
final availableProducts = await supabase
    .from(DatabaseSchema.tables.products)
    .select()
    .eq(DatabaseSchema.products.isAvailable, true);
```

### 3. Join nhiều bảng

```dart
final response = await supabase
    .from(DatabaseSchema.tables.products)
    .select('*, ${DatabaseSchema.tables.categories}!inner(*)')
    .eq('${DatabaseSchema.tables.categories}.${DatabaseSchema.categories.id}', categoryId);
```

### 4. Trong Repository

Ví dụ trong ProductRepository:

```dart
class ProductRepository {
  final SupabaseClient _client = SupabaseClientService.instance;
  final ProductsTable _schema = DatabaseSchema.products;

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final response = await _client
        .from(_schema.table)
        .select()
        .eq(_schema.categoryId, categoryId);
        
    return (response as List).map((item) => Product.fromJson(item)).toList();
  }
}
```

## Lợi ích

1. **Autocompletion trong IDE**: Hỗ trợ gợi ý tên bảng, tên cột
2. **Kiểm tra lỗi typo khi biên dịch**: Lỗi sẽ được phát hiện sớm
3. **Refactoring dễ dàng**: Nếu cần đổi tên cột/bảng, chỉ cần thay đổi tại một nơi
4. **Code rõ ràng hơn**: Các tên bảng/cột được tổ chức thành các nhóm logic

## Khi cần thêm bảng mới

1. Thêm tên bảng vào `TableNames`
2. Tạo class mới tương ứng (ví dụ: `ReviewsTable`)
3. Thêm instance của class đó vào `DatabaseSchema`

```dart
// Thêm vào TableNames
final String reviews = 'product_reviews';

// Tạo class mới
class ReviewsTable {
  const ReviewsTable();
  
  final String table = 'product_reviews';
  final String id = 'id';
  final String productId = 'product_id';
  // ...
}

// Thêm vào DatabaseSchema
static const ReviewsTable reviews = ReviewsTable();
```