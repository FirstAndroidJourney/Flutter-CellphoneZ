import 'package:equatable/equatable.dart';

/// Base class for all ProductList events
abstract class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all products
class LoadProducts extends ProductListEvent {
  const LoadProducts();
}

/// Event to filter products by category
class FilterByCategory extends ProductListEvent {
  final String? categoryId; // null means "All Products"

  const FilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Event to search products
class SearchProducts extends ProductListEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to refresh products
class RefreshProducts extends ProductListEvent {
  const RefreshProducts();
}

/// Event to clear filters and search
class ClearFilters extends ProductListEvent {
  const ClearFilters();
}
