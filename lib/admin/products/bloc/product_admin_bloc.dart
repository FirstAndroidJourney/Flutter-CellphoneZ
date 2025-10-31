import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';

part 'product_admin_event.dart';
part 'product_admin_state.dart';

class ProductAdminBloc extends Bloc<ProductAdminEvent, ProductAdminState> {
  ProductAdminBloc(this._productService) : super(const ProductAdminState()) {
    on<ProductAdminStarted>(_onStarted);
    on<ProductAdminRefreshed>(_onRefreshed);
    on<ProductAdminSubmitted>(_onSubmitted);
    on<ProductAdminDeleteRequested>(_onDeleteRequested);
    on<ProductAdminFormReset>(_onFormReset);
  }

  final ProductService _productService;

  Future<void> _onStarted(
    ProductAdminStarted event,
    Emitter<ProductAdminState> emit,
  ) async {
    await _loadProducts(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    ProductAdminRefreshed event,
    Emitter<ProductAdminState> emit,
  ) async {
    await _loadProducts(emit, showLoading: true);
  }

  Future<void> _onSubmitted(
    ProductAdminSubmitted event,
    Emitter<ProductAdminState> emit,
  ) async {
    debugPrint(
      '[ProductAdminBloc] _onSubmitted start | existingId=${event.existing?.id ?? 'new'}',
    );
    emit(
      state.copyWith(
        formStatus: ProductAdminFormStatus.submitting,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      if (event.existing == null) {
        debugPrint('[ProductAdminBloc] _onSubmitted creating product');
        await _productService.createProduct(
          name: event.input.name,
          price: event.input.price,
          isAvailable: event.input.isAvailable,
          description: event.input.description,
          categoryId: event.input.categoryId,
          image: event.input.image,
        );
      } else {
        debugPrint(
          '[ProductAdminBloc] _onSubmitted updating product ${event.existing!.id}',
        );
        await _productService.updateProduct(
          current: event.existing!,
          name: event.input.name,
          price: event.input.price,
          isAvailable: event.input.isAvailable,
          description: event.input.description,
          categoryId: event.input.categoryId,
          newImage: event.input.image,
        );
      }

      final products = await _productService.getAllProducts();
      debugPrint(
        '[ProductAdminBloc] _onSubmitted success | totalProducts=${products.length}',
      );
      emit(
        state.copyWith(
          status: ProductAdminStatus.success,
          products: products,
          formStatus: ProductAdminFormStatus.success,
          successMessage:
              event.existing == null ? 'Đã tạo sản phẩm mới' : 'Đã cập nhật sản phẩm',
          errorMessage: null,
        ),
      );
    } on ArgumentError catch (error) {
      debugPrint('[ProductAdminBloc] _onSubmitted argument error: $error');
      emit(
        state.copyWith(
          formStatus: ProductAdminFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      debugPrint('[ProductAdminBloc] _onSubmitted error: $error');
      emit(
        state.copyWith(
          formStatus: ProductAdminFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ProductAdminDeleteRequested event,
    Emitter<ProductAdminState> emit,
  ) async {
    debugPrint(
      '[ProductAdminBloc] _onDeleteRequested start | productId=${event.product.id}',
    );
    emit(
      state.copyWith(
        formStatus: ProductAdminFormStatus.submitting,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final shouldEnable = !event.product.isAvailable;

      await _productService.updateProductAvailability(
        event.product,
        shouldEnable,
      );
      final products = await _productService.getAllProducts();
      debugPrint(
        '[ProductAdminBloc] _onDeleteRequested success | shouldEnable=$shouldEnable | totalProducts=${products.length}',
      );
      emit(
        state.copyWith(
          status: ProductAdminStatus.success,
          products: products,
          formStatus: ProductAdminFormStatus.success,
          successMessage: shouldEnable
              ? 'Đã mở bán lại sản phẩm'
              : 'Đã ngừng bán sản phẩm',
        ),
      );
    } catch (error) {
      debugPrint('[ProductAdminBloc] _onDeleteRequested error: $error');
      emit(
        state.copyWith(
          formStatus: ProductAdminFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onFormReset(
    ProductAdminFormReset event,
    Emitter<ProductAdminState> emit,
  ) {
    emit(
      state.copyWith(
        formStatus: ProductAdminFormStatus.idle,
        successMessage: null,
        errorMessage: null,
      ),
    );
  }

  Future<void> _loadProducts(
    Emitter<ProductAdminState> emit, {
    required bool showLoading,
  }) async {
    debugPrint(
      '[ProductAdminBloc] _loadProducts start | showLoading=$showLoading',
    );
    if (showLoading) {
      emit(
        state.copyWith(
          status: ProductAdminStatus.loading,
          errorMessage: null,
          successMessage: null,
        ),
      );
    }

    try {
      final products = await _productService.getAllProducts();
      debugPrint(
        '[ProductAdminBloc] _loadProducts success | totalProducts=${products.length}',
      );
      emit(
        state.copyWith(
          status: ProductAdminStatus.success,
          products: products,
          errorMessage: null,
        ),
      );
    } catch (error) {
      debugPrint('[ProductAdminBloc] _loadProducts error: $error');
      emit(
        state.copyWith(
          status: ProductAdminStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
