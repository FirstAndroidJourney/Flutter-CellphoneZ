part of 'product_admin_bloc.dart';

enum ProductAdminStatus { initial, loading, success, failure }

enum ProductAdminFormStatus { idle, submitting, success, failure }

const _kNoChange = Object();

class ProductAdminState extends Equatable {
  const ProductAdminState({
    this.status = ProductAdminStatus.initial,
    this.products = const [],
    this.formStatus = ProductAdminFormStatus.idle,
    this.errorMessage,
    this.successMessage,
  });

  final ProductAdminStatus status;
  final List<Product> products;
  final ProductAdminFormStatus formStatus;
  final String? errorMessage;
  final String? successMessage;

  ProductAdminState copyWith({
    ProductAdminStatus? status,
    List<Product>? products,
    ProductAdminFormStatus? formStatus,
    Object? errorMessage = _kNoChange,
    Object? successMessage = _kNoChange,
  }) {
    return ProductAdminState(
      status: status ?? this.status,
      products: products ?? this.products,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: identical(errorMessage, _kNoChange)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _kNoChange)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        formStatus,
        errorMessage,
        successMessage,
      ];
}
