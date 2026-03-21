import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';

class CartItemModel {
  final String? cartItemId;
  final ProductModel product;
  int quantity;

  CartItemModel({
    this.cartItemId,
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({
    String? cartItemId,
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      cartItemId: cartItemId ?? this.cartItemId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
