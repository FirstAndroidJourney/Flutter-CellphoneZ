import 'package:equatable/equatable.dart';
import 'package:shop/models/product.dart';

/// Base class for all ProductList states
abstract class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

/// Loading state
class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

/// Loaded state with products
class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final String? selectedCategoryId;
  final String? searchQuery;
  final bool isFiltered;

  const ProductListLoaded({
    required this.products,
    this.selectedCategoryId,
    this.searchQuery,
    this.isFiltered = false,
  });

  @override
  List<Object?> get props => [
        products,
        selectedCategoryId,
        searchQuery,
        isFiltered,
      ];

  ProductListLoaded copyWith({
    List<Product>? products,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isFiltered,
  }) {
    return ProductListLoaded(
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }
}

/// Empty state when no products found
class ProductListEmpty extends ProductListState {
  final String message;

  const ProductListEmpty({this.message = 'Không tìm thấy sản phẩm'});

  @override
  List<Object?> get props => [message];
}

/// Error state
class ProductListError extends ProductListState {
  final String message;

  const ProductListError(this.message);

  @override
  List<Object?> get props => [message];
}
