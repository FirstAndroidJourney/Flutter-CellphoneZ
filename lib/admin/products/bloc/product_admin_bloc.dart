import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
    emit(
      state.copyWith(
        formStatus: ProductAdminFormStatus.submitting,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      if (event.existing == null) {
        await _productService.createProduct(
          name: event.input.name,
          price: event.input.price,
          isAvailable: event.input.isAvailable,
          description: event.input.description,
          categoryId: event.input.categoryId,
          image: event.input.image,
        );
      } else {
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
      emit(
        state.copyWith(
          formStatus: ProductAdminFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
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
    emit(
      state.copyWith(
        formStatus: ProductAdminFormStatus.submitting,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await _productService.deleteProduct(event.product);
      final products = await _productService.getAllProducts();
      emit(
        state.copyWith(
          status: ProductAdminStatus.success,
          products: products,
          formStatus: ProductAdminFormStatus.success,
          successMessage: 'Đã xóa sản phẩm',
        ),
      );
    } catch (error) {
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
      emit(
        state.copyWith(
          status: ProductAdminStatus.success,
          products: products,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductAdminStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
