# Store Locator & Map Integration Plan

## Goals
- Cung cấp trải nghiệm bản đồ khả dụng cho người dùng (chọn điểm nhận hàng) và admin (quản lý cửa hàng).
- Giảm độ phức tạp bằng cách eager-load ≤10 cửa hàng.
- Cho phép chuyển đổi linh hoạt giữa Google Maps / MapTiler cho bước dẫn đường.

## User-Facing Store Locator
### Entry Points
- **Checkout flow**: Trong `PaymentScreen`, khi user chọn `store_pickup` hiển thị nút “Chọn cửa hàng”. Nhấn vào push `StoreLocatorScreen`.
- **Bottom navigation**: Thêm tab hoặc shortcut “Cửa hàng” để người dùng truy cập map ngay từ trang chủ.

### Data & Schema
- Bảng mới `public.stores`:
  - `id UUID PK`
  - `name`, `address_full`, `city`
  - `latitude`, `longitude`
  - `phone`, `services JSONB`, `opening_hours JSONB`
  - `is_active boolean`
- Bảng `orders` bổ sung:
  - `pickup_type text CHECK (IN ('delivery','store_pickup')) DEFAULT 'delivery'`
  - `pickup_store_id uuid REFERENCES public.stores(id)`
- Seed tối đa 10 cửa hàng mẫu để eager-load.

### API Strategy
- Eager load tất cả cửa hàng thông qua PostgREST endpoint `GET /rest/v1/stores?is_active=eq.true`.
- Lọc, sắp xếp theo khoảng cách/keyword ở client (Haversine).
- Giữ khả năng mở rộng sang RPC `search_stores` nếu số lượng tăng.

### Client Architecture
- `StoreService.fetchStores()` trả `List<Store>`; cache trong bộ nhớ.
- `StoreLocatorCubit` xử lý trạng thái: danh sách đầy đủ, lọc, vị trí người dùng, store được chọn.
- `ExternalNavigationService` chịu trách nhiệm mở ứng dụng điều hướng với enum `ExternalMapProvider` (Google Maps hoặc MapTiler Directions).

### StoreLocatorScreen (User)
- AppBar với TextField tìm kiếm (không voice).
- `flutter_map` + MapTiler tiles hiển thị marker cửa hàng; overlay `MapTilerLogo`/copyright.
- Bottom sheet với danh sách & filter chips (dịch vụ, “đang mở”, bán kính slider).
- Marker ↔ card đồng bộ; nút “Chọn làm điểm lấy” pop `StoreSelection` về caller qua `Navigator.pop`.
- Tùy chọn “Chỉ đường” sử dụng `ExternalNavigationService`.

### Checkout Integration
- `PaymentScreen` nhận `StoreSelection`, lưu `_selectedStore`, cập nhật UI và set `_selectedMethod = 'store_pickup'`.
- Order payload gửi `pickup_type='store_pickup'` + `pickup_store_id`.

## Admin Store Management
- Màn hình admin mới (`lib/admin/store_manager/`):
  - Danh sách cửa hàng (status toggle, edit/delete).
  - MapTiler map song song hiển thị marker; chọn marker highlight entry.
  - Form tạo/sửa cho phép chọn tọa độ bằng map tap hoặc nhập tay; upload metadata (dịch vụ, giờ mở cửa, hình ảnh).
  - Action “Preview trên user map”.
- Shared `StoreService` với endpoint có quyền admin (RLS policies).

## Attribution & Branding
- Overlay logo hoặc text “© MapTiler © OpenStreetMap contributors” ở góc map để tuân thủ licensing.
- Ghi chú thêm trong docs/README cách cấu hình `.env` (`MAPTILER_API_KEY`) & MapTiler style.

## Testing & Rollout
- Unit tests cho `StoreLocatorCubit` (lọc, chọn store, error states).
- Widget test cho `StoreLocatorScreen` (search/filter interactions).
- Admin CRUD tests (mock Supabase).
- Manual QA script: mở tab “Cửa hàng”, tìm/lọc, chọn store, quay lại checkout, đặt đơn.
- Document các bước seed dữ liệu và phân quyền Supabase.
