import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/products_service.dart';

class AllProductsState {
  const AllProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
}

class AllProductsCubit extends Cubit<AllProductsState> {
  AllProductsCubit(this._service) : super(const AllProductsState());

  final ProductsService _service;

  Future<void> loadProducts({
    String? category,
    String? restaurantId,
    String? type,
  }) async {
    emit(AllProductsState(isLoading: true, error: null));
    try {
      final products = await _service.getProducts(
        category: category,
        restaurantId: restaurantId,
        type: type,
      );
      emit(AllProductsState(products: products, isLoading: false));
    } catch (e) {
      emit(AllProductsState(isLoading: false, error: e.toString()));
    }
  }
}
