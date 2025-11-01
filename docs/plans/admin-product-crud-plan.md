# CellphoneZ Admin Product CRUD – Implementation Plan (31/10/2025)

> Kế hoạch chi tiết hóa cụm nhiệm vụ **1️⃣ CRUD Product** trong `TASK_BREAKDOWN.md`, bám sát trạng thái repository hiện tại. Tài liệu này giúp team triển khai lần lượt các lớp model → repository/service → upload ảnh → BLoC & UI mà **không đổi schema Supabase**. Khi upload ảnh thành công qua Supabase Storage, bắt buộc gán ngay public URL vào trường `image_url` trước khi lưu sản phẩm.

---

## 1. Phạm vi & Ràng buộc
- Tuân thủ bảng `public.products` đang hoạt động (xem §2). Không tạo migration mới.
- Hệ thống admin phải cung cấp CRUD đầy đủ, bao gồm quản lý ảnh (upload, thay thế, xoá).
- Tận dụng các lớp sẵn có (`BaseRepository`, `SchemaAccessor`, `AppLogger`, `DatabaseClient`).
- Đảm bảo dịch vụ mới tương thích với `GetIt` và luồng Supabase hiện có.

---

## 2. Supabase Product Schema (tham chiếu từ `docs/reference/supabase-erd.md`)

| Cột           | Kiểu dữ liệu        | Ràng buộc                                        | Ghi chú triển khai |
|---------------|---------------------|--------------------------------------------------|--------------------|
| `id`          | `uuid`              | `PRIMARY KEY`, default `gen_random_uuid()`       | Để Supabase tự sinh, client không gửi giá trị. |
| `name`        | `varchar`           | `NOT NULL`, default `''`                         | Validate khác rỗng trên UI + service. |
| `price`       | `double precision`  | default `0`                                      | Admin nhập giá trị hợp lệ (`> 0`). |
| `description` | `varchar`           | default `''`                                     | Cho phép bỏ trống, map SafeString khi persist. |
| `image_url`   | `varchar`           | default `''`                                     | Nhận public URL từ Supabase Storage sau upload. |
| `is_available`| `boolean`           | `NOT NULL`                                       | UI phải cung cấp toggle bắt buộc. |
| `category_id` | `uuid`              | FK → `categories.id`, nullable                    | Cho phép chưa gán category, cần validate khi chọn. |

Không có trường `created_at` trong bảng `products`; mọi logic thời gian cần dựa vào dữ liệu khác hoặc Supabase metadata nếu thật sự cần.

---

## 3. Hiện trạng Codebase (31/10/2025)

- **Model** (`lib/models/product.dart:1`)
  - `id` và `categoryId` là `required String`, đang truyền `''` khi tạo mới → mâu thuẫn với Supabase auto-id và FK rỗng.
  - `isAvailable` `@Default(true)` → không gửi được giá trị `false` nếu dùng copyWith mặc định.
  - Chưa có DTO riêng cho create/update (khó gửi payload partial).

- **Repository** (`lib/repository/product_repository.dart:1`)
  - Kế thừa `BaseRepository` nhưng vẫn dùng `print`/`debugPrint` thay vì `AppLogger`.
  - `createProduct`/`updateProduct` dựa vào `Product.toJson()` nên luôn gửi toàn bộ trường, bao gồm `id` rỗng và field nullable `null` → dễ khiến Supabase reject.
  - Chưa có cleanup ảnh khi update/delete.

- **Service** (`lib/services/product_service.dart:1`)
  - Khởi tạo repository trong constructor bằng `getIt` mỗi lần, in log bằng `print`.
  - `createProduct` tự build `Product` với `id: ''` và bỏ qua `isAvailable` (dùng default `true`), chưa xử lý upload ảnh.

- **Schema & DI**
  - `lib/services/database_schema.dart:38` đã khai báo bảng `products` nhưng chưa expose `StorageBuckets` qua `SchemaAccessor`.
  - `lib/services/dependency_injection.dart:1` chưa đăng ký `StorageService` hay converter mới.

- **Presentation**
  - Chưa có thư mục admin chuyên biệt (`lib/admin/…`). UI hiện tại chỉ phục vụ user flow.
  - Chưa có BLoC hoặc screen cho admin product CRUD.

---

## 4. Lộ trình Triển khai (theo `TASK_BREAKDOWN.md`)

### 4.1 Task 1.1 – Product Model & Database Schema
1. **Refactor model**
   - Chuyển `id` thành `String?` với `@JsonKey(includeIfNull: false)` để Supabase tự sinh.
   - Tách `Product` (read model) và `ProductDraft` (create/update payload) bằng Freezed để tránh gửi trường không hợp lệ.
   - `isAvailable` trở thành `required bool` ở cả entity và draft; UI phải cung cấp giá trị rõ ràng.
   - Chuẩn hóa `description`/`imageUrl` dùng helper `emptyToNull` khi encode.
2. **Schema helper**
   - Thêm getter `storageBuckets` vào `SchemaAccessor` để truy cập `StorageBuckets` (`product-images`).
   - Đảm bảo mọi query sử dụng constant từ `DatabaseSchema.products` thay vì string literal.
3. **Code generation**
   - Sau khi sửa Freezed, chạy `melos run gen` để tái tạo `product.freezed.dart` và `product.g.dart`.

### 4.2 Task 1.2 – Product Repository & Service
1. **Repository**
   - Inject `AppLogger` (qua constructor hoặc getter) để thay `print`/`debugPrint`.
   - Tạo helper `Map<String, dynamic> toInsertPayload(ProductDraft draft)` loại bỏ trường null và `id`.
   - Thêm phương thức `Future<void> removeImage(String storagePath)` nếu sử dụng `StorageService` (hỗ trợ Task 1.3/1.4).
   - Chuẩn hóa lỗi: ném `RepositoryException` (custom) với message + original error.
2. **Service**
   - Nhận `ProductRepository` và `StorageService` qua constructor injection (để dễ test).
   - Thêm validation (ví dụ: `price > 0`, `name.trim().isNotEmpty`).
   - `createProduct`/`updateProduct` nhận `ProductDraft` và option `File? imageFile`. Nếu có ảnh → ủy thác sang Task 1.3 workflow trước khi gọi repository.
   - `deleteProduct` nhận thêm `String? imageStoragePath` để xoá file liên quan.
3. **Logging & Error handling**
   - Dùng `AppLogger` cho mọi log lỗi/thành công.
   - Chuẩn bị các message thân thiện để BLoC/ UI dùng lại.

### 4.3 Task 1.3 – Product Image Upload (Supabase Storage)
1. **StorageService mới**
   - Tạo `lib/services/storage_service.dart` bọc `Supabase.instance.client.storage`.
   - Expose các method: `uploadProductImage(Uint8List bytes, String fileName)`, `removeProductImage(String path)`, `getPublicUrl(String path)`.
   - Đọc hướng dẫn trong `docs/guides/supabase-storage-flutter.md` để chuẩn hóa option (`FileOptions`, `cacheControl`, `upsert: false`).
2. **Bucket & Path**
   - Sử dụng bucket `product-images` (đã tồn tại). Đặt path dạng `products/{productId or timestamp}/{uuid}.jpg`.
   - Thiết lập bucket public hoặc sử dụng signed URL tùy policy; nếu public, dùng `getPublicUrl`.
3. **Upload pipeline trong `ProductService`**
   - Nhận file (từ UI) → compress bằng package `image` (thêm dependency) → convert sang `Uint8List`.
   - Gọi `StorageService.uploadProductImage`, nhận lại `storagePath` và `publicUrl`.
   - Gán `publicUrl` vào `ProductDraft.imageUrl`, lưu `storagePath` để hỗ trợ cleanup.
4. **Cleanup & Retry**
   - Khi update ảnh: upload ảnh mới → cập nhật product → nếu thành công thì gọi `removeProductImage` với path cũ.
   - Khi delete product: xoá record trước, nếu repository trả về success thì xoá ảnh (nếu có).
   - Thêm retry tối đa 1 lần khi upload thất bại, log chi tiết bucket/path/status.
5. **DI**
   - Đăng ký `StorageService` trong `setupDependencies()` trước repository/service cần dùng.

### 4.4 Task 1.4 – Product Admin BLoC & UI
1. **Kiến trúc thư mục**
   - Tạo `lib/admin/products/` gồm `bloc/`, `view/`, `widgets/`.
   - Đặt BLoC riêng (`product_admin_bloc.dart`, `product_admin_event.dart`, `product_admin_state.dart`).
2. **BLoC logic**
   - Events chính: `LoadProducts`, `CreateProduct`, `UpdateProduct`, `DeleteProduct`, `PickImage`, `RemoveImage`.
   - State chứa: danh sách `Product`, `FormStatus`, `UploadProgress`, `String? imagePreviewUrl`, `File? imageFile`.
   - Trong handler create/update: gọi `ProductService` → emit loading → emit success/failure → refresh list.
3. **UI**
   - `product_list_screen.dart`: table/list với actions edit/delete, FAB "Thêm sản phẩm".
   - `product_form_screen.dart`: form (name, price, category dropdown, switch `isAvailable`, description, image picker). Hiển thị preview và tiến trình upload.
   - Kết nối router hiện tại (`lib/route/`), ẩn màn hình dưới guard chỉ admin.
4. **UX yêu cầu**
   - Validate inline (ví dụ `price > 0`). Hiển thị snackbar/toast từ state message.
   - Khi xoá sản phẩm, confirm dialog + hiển thị spinner trong lúc chờ.
5. **Testing**
   - Bloc test: happy path create/update, upload fail fallback, delete cleans image.
   - Widget test: form validation, preview ảnh.

---

## 5. Workflow Upload Ảnh (Chi tiết triển khai)
1. **Chọn ảnh**: sử dụng `image_picker`. Bổ sung dependency `image_picker` + xử lý permission cho Android/iOS.
2. **Nén ảnh**: dùng package `image` để resize/compress về ~1–2MB trước upload.
3. **Đặt tên file**: `final fileName = '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}.jpg';`.
4. **Upload**:
   ```dart
   final storagePath = await storageService.uploadProductImage(
     bytes,
     fileName,
     options: const FileOptions(
       cacheControl: '3600',
       upsert: false,
       contentType: 'image/jpeg',
     ),
   );
   final publicUrl = storageService.getPublicUrl(storagePath);
   ```
5. **Gán URL vào product**: `draft = draft.copyWith(imageUrl: publicUrl, imageStoragePath: storagePath);` trước khi gọi repository.
6. **Cleanup khi update/delete**: gọi `storageService.removeProductImage(storagePath)` nếu tồn tại.
7. **Error handling**: nếu upload lỗi → hiển thị snackbar “Không thể upload ảnh, vui lòng thử lại”, không gọi repository tới khi thành công.

---

## 6. Kiểm thử & QA
- **Automation**: chạy `melos run analyze`, `melos run test`, `melos run format` trước khi merge.
- **Unit test**: mock Supabase client/StorageService để test `ProductRepository` & `ProductService` (bao gồm branch upload thành công/thất bại).
- **Bloc test**: xác minh state transition khi CRUD + upload ảnh.
- **Widget test**: form validation, hiển thị preview ảnh, luồng xoá sản phẩm.
- **Manual QA checklist**:
  - Tạo mới sản phẩm có ảnh → kiểm tra record trên Supabase hiển thị `image_url` chính xác.
  - Cập nhật ảnh → ảnh cũ bị xoá (verify trong bucket).
  - Xoá sản phẩm → ảnh không còn trong bucket.
  - Test khi Supabase trả lỗi (401/timeout) → UI hiển thị thông báo rõ ràng.

---

## 7. Rủi ro & Giảm thiểu
- **Dị biệt schema Supabase**: kiểm tra lại trên dashboard sản xuất trước khi release; nếu phát hiện khác biệt, cập nhật doc và code ngay, vẫn tránh migration.
- **Ảnh “mồ côi”**: lưu `storagePath` cùng product (có thể dùng metadata local hoặc field phụ) để xoá chính xác khi update/delete.
- **Upload thất bại**: implement retry + log chi tiết. Nếu fail liên tục, giữ draft ở state pending và cảnh báo admin.
- **Quyền truy cập admin UI**: cần guard (ví dụ kiểm tra role) để tránh người dùng thường truy cập.
- **Performance**: giới hạn kích thước ảnh sau compress; cân nhắc lazy loading danh sách sản phẩm nếu số lượng lớn.

---

## 8. Definition of Done
- Admin có thể tạo, chỉnh sửa, xóa sản phẩm kèm ảnh; dữ liệu đồng bộ với Supabase mà không vi phạm schema hiện tại.
- Tầng repository/service dùng `AppLogger`, không còn `print` thủ công.
- Upload ảnh sử dụng Supabase Storage, tự động set `image_url`, quản lý cleanup hợp lý.
- BLoC/UI admin hoàn tất với kiểm thử tối thiểu (unit + bloc + widget) và tài liệu workflow này được cập nhật nếu có thay đổi.

