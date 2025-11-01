class ProductCategory {
  final String id;
  final String name;
  final String icon;

  ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

final List<ProductCategory> productCategories = [
  ProductCategory(
    id: 'phones',
    name: 'Điện thoại',
    icon: 'assets/icons/smartphone.png',
  ),
  ProductCategory(
    id: 'laptops',
    name: 'Laptop',
    icon: 'assets/icons/laptop.png',
  ),
  ProductCategory(
    id: 'tvs',
    name: 'Tivi',
    icon: 'assets/icons/tv.png',
  ),
  ProductCategory(
    id: 'accessories',
    name: 'Phụ kiện',
    icon: 'assets/icons/accessories.png',
  ),
  ProductCategory(
    id: 'smartwatches',
    name: 'Đồng hồ thông minh',
    icon: 'assets/icons/smartwatch.png',
  ),
  ProductCategory(
    id: 'tablets',
    name: 'Máy tính bảng',
    icon: 'assets/icons/tablet.png',
  ),
];
