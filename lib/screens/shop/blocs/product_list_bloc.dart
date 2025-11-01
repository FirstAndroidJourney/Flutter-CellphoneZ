import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shop/repository/product_repository.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final ProductRepository _productRepository;

  ProductListBloc({ProductRepository? productRepository})
      : _productRepository = productRepository ?? GetIt.I<ProductRepository>(),
        super(const ProductListInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<RefreshProducts>(_onRefreshProducts);
    on<ClearFilters>(_onClearFilters);
  }

  /// Handle loading all products
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final products = await _productRepository.getAllProducts();
      if (products.isEmpty) {
        emit(const ProductListEmpty());
      } else {
        emit(ProductListLoaded(products: products));
      }
    } catch (e) {
      emit(ProductListError('Không thể tải sản phẩm: ${e.toString()}'));
    }
  }

  /// Handle filtering by category
  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<ProductListState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final products = event.categoryId == null
          ? await _productRepository.getAllProducts()
          : await _productRepository.getProductsByCategory(event.categoryId!);

      if (products.isEmpty) {
        emit(ProductListEmpty(
          message: event.categoryId == null
              ? 'Không có sản phẩm nào'
              : 'Không có sản phẩm trong danh mục này',
        ));
      } else {
        emit(ProductListLoaded(
          products: products,
          selectedCategoryId: event.categoryId,
          isFiltered: event.categoryId != null,
        ));
      }
    } catch (e) {
      emit(ProductListError('Không thể lọc sản phẩm: ${e.toString()}'));
    }
  }

  /// Handle searching products (debounce is handled in UI)
  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductListState> emit,
  ) async {
    // If query is empty, load all products
    if (event.query.trim().isEmpty) {
      add(const LoadProducts());
      return;
    }

    emit(const ProductListLoading());
    try {
      final products = await _productRepository.searchProducts(event.query);

      if (products.isEmpty) {
        emit(ProductListEmpty(
          message: 'Không tìm thấy sản phẩm với từ khóa "${event.query}"',
        ));
      } else {
        emit(ProductListLoaded(
          products: products,
          searchQuery: event.query,
          isFiltered: true,
        ));
      }
    } catch (e) {
      emit(ProductListError('Không thể tìm kiếm sản phẩm: ${e.toString()}'));
    }
  }

  /// Handle refreshing products
  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductListState> emit,
  ) async {
    // Get current state
    final currentState = state;

    try {
      if (currentState is ProductListLoaded) {
        // Refresh based on current filters
        if (currentState.searchQuery != null &&
            currentState.searchQuery!.isNotEmpty) {
          add(SearchProducts(currentState.searchQuery!));
        } else if (currentState.selectedCategoryId != null) {
          add(FilterByCategory(currentState.selectedCategoryId));
        } else {
          add(const LoadProducts());
        }
      } else {
        // Default refresh
        add(const LoadProducts());
      }
    } catch (e) {
      emit(ProductListError('Không thể làm mới: ${e.toString()}'));
    }
  }

  /// Handle clearing all filters
  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<ProductListState> emit,
  ) async {
    add(const LoadProducts());
  }
}
