import 'package:flutter_bloc/flutter_bloc.dart';

class ProductSelectionCubit extends Cubit<String?> {
  ProductSelectionCubit() : super(null);

  void select(String? productId) {
    emit(productId);
  }

  void clear() {
    emit(null);
  }
}
