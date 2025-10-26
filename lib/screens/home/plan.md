# Kế hoạch redesign Home Screen CellphoneZ

## 1. Mục tiêu
- Chuyển template Shoplon thành trang chủ bán thiết bị điện tử CellphoneZ: nhấn mạnh khuyến mãi, sản phẩm hot, dịch vụ hậu mãi.
- Tăng tỷ lệ click banner ≥15%, cải thiện khả năng tìm sản phẩm (time-to-product ≤10s) và tạo khác biệt thương hiệu (tone đỏ #d70018).

## 2. Nghiên cứu & Insight
- Benchmark: CellphoneS, Thegioididong, FPT Shop, Apple Store để so sánh bố cục banner, flash sale, quick actions.
- Phỏng vấn nhanh người dùng mục tiêu (2–3 người) về nhu cầu: xem giá, ưu đãi trả góp, trade-in, dịch vụ tại nhà.
- Kiểm tra analytics hiện tại (nếu có) để biết section nào được tương tác nhiều nhất, làm cơ sở sắp xếp sliver.

## 3. Định hướng visual
- Màu: Primary đỏ CellphoneZ (#d70018), Secondary xám trung tính (#f6f6f6, #1f1f1f), Accent gradient đỏ–đen cho flagship.
- Typography: Montserrat Bold cho heading, Inter/Roboto cho body để giữ nét công nghệ.
- Icon: outline 1.5pt, bo góc lớn (16–20) cho pill button tạo cảm giác cao cấp.
- Ảnh hero: thiết bị thật, nền tối giúp sản phẩm nổi bật; bổ sung badge “Chính hãng”, “Trả góp 0%”.

## 4. Kiến trúc nội dung Home Screen (Sliver order)
1. **Status/AppBar**  
   - Logo CellphoneZ, search, icon giỏ, bell, shortcut QR.  
   - Sticky khi scroll.
2. **Hero Carousel**  
   - 3–4 banner: Flash Sale, Trả góp 0%, Trade-in, Mua combo.  
   - Timer + indicator; CTA “Mua ngay”.
3. **Quick Actions Row**  
   - Icon buttons: Đặt lịch sửa, Tra cứu bảo hành, Check trade-in, Ưu đãi doanh nghiệp.
4. **Danh mục sản phẩm**  
   - Chip scroll ngang: Điện thoại, Laptop, Tablet, Đồng hồ, Nhà thông minh, Phụ kiện.  
   - Chip “Ưu đãi hôm nay” nổi bật.
5. **Flash Sale / Deal sốc**  
   - Card list ngang với countdown, badge % giảm, hiển thị giá gốc & giá mới.
6. **Popular / Top flagship**  
   - Card lớn cho iPhone, Galaxy, MacBook… kèm lựa chọn màu, dung lượng.
7. **Gợi ý theo nhu cầu**  
   - Carousel “Chơi game / Chụp ảnh / Làm việc / Học Online” → nhảy vào bộ lọc tương ứng.
8. **Tin công nghệ & Khuyến mãi dịch vụ**  
   - Card blog + banner “Thu cũ đổi mới”, “Ưu đãi bảo hành mở rộng”.
9. **Footer CTA**  
   - Sticky chat tư vấn + hotline, hiển thị ở cuối list.

## 5. Công việc UI chi tiết
- **Layout**: cập nhật `CustomScrollView` trong `home_screen.dart`, tạo các `SliverToBoxAdapter` mới theo thứ tự mục 4.
- **Components**:
  - `HeroBanner` mới hỗ trợ gradient + overlay text + CTA button.  
  - `QuickActionButton` (icon + label, bo góc lớn).  
  - `FlashSaleCard` có countdown, badge, thông tin trả góp.  
  - `RecommendationTile` cho nhu cầu sử dụng.  
  - `ArticleCard` cho tin tức.
- **Theme**: thêm `CellphoneZTheme` (màu, typography, shadow, spacing) để tái sử dụng.
- **Icon & asset**: cập nhật folder `assets/icons` với gói icon mới, tạo mapping trong `pubspec.yaml`.

## 6. Nội dung & copywriting
- Viết lại headline: “Flash Sale Z-Verse”, “Thu cũ đổi mới – thêm đến 3 triệu”.
- Badge tin cậy: “Hàng chính hãng”, “Giao nhanh 2h”.  
- Micro copy cho trạng thái rỗng: “Hiện chưa có deal, quay lại sau nhé”.

## 7. Data & logic
- Kết nối API thực:  
  - Flash sale: endpoint `GET /promotions/flash-sale`.  
  - Category: `GET /categories?type=electronics`.  
  - Articles: `GET /news?limit=5`.  
  - Gợi ý nhu cầu: build từ analytics hoặc dataset tĩnh trước.
- Hỗ trợ skeleton khi loading, xử lý lỗi hiển thị `Retry`.
- Tracking sự kiện: `hero_tap`, `flash_sale_buy`, `category_select`, `quick_action_tap`.

## 8. Timeline thực hiện (2 tuần)
- **Ngày 1-2**: Research + moodboard + flow IA.  
- **Ngày 3-4**: Wireframe low-fi (mobile).  
- **Ngày 5-7**: Hi-fi Home (hero, quick action, category, flash sale).  
- **Ngày 8-9**: Hoàn tất các block còn lại + tạo component.  
- **Ngày 10**: Prototype tương tác, review stakeholder.  
- **Ngày 11-12**: Handover spec + asset, cập nhật Flutter widget skeleton.  
- **Ngày 13-14**: Implement + QA (analyze, test, performance check).

## 9. Checklist bàn giao
- ✅ Figma file + component library.  
- ✅ Assets (SVG/PNG, banner PSD/fig).  
- ✅ Spec màu, font, spacing, trạng thái hover/tap.  
- ✅ Jira/Notion task mapping cho từng block Flutter.  
- ✅ Test cases UI: load chậm, không có deal, dark mode.
