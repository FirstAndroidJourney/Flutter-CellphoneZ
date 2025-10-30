part of 'product_admin_bloc.dart';

abstract class ProductAdminEvent extends Equatable {
  const ProductAdminEvent();

  @override
  List<Object?> get props => [];
}

class ProductAdminStarted extends ProductAdminEvent {
  const ProductAdminStarted();
}

class ProductAdminRefreshed extends ProductAdminEvent {
  const ProductAdminRefreshed();
}

class ProductAdminSubmitted extends ProductAdminEvent {
  const ProductAdminSubmitted({
    this.existing,
    required this.input,
  });

  final Product? existing;
  final ProductFormInput input;

  @override
  List<Object?> get props => [
        existing?.id,
        input,
      ];
}

class ProductAdminDeleteRequested extends ProductAdminEvent {
  const ProductAdminDeleteRequested(this.product);

  final Product product;

  @override
  List<Object?> get props => [product.id];
}

class ProductAdminFormReset extends ProductAdminEvent {
  const ProductAdminFormReset();
}

class ProductFormInput extends Equatable {
  const ProductFormInput({
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.categoryId,
    this.image,
  });

  final String name;
  final double price;
  final bool isAvailable;
  final String? description;
  final String? categoryId;
  final ProductImagePayload? image;

  @override
  List<Object?> get props => [
        name,
        price,
        isAvailable,
        description,
        categoryId,
        image,
      ];
}
