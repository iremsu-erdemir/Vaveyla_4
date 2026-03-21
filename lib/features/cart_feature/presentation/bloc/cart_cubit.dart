import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/cart_item_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/services/customer_cart_service.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());
  static const String differentRestaurantErrorMessage =
      'Aynı anda farklı pastanelerden ürün ekleyemezsiniz. Lütfen önce sepetinizi temizleyin.';

  final CustomerCartService _cartService = CustomerCartService();
  final List<CartItemModel> _items = [];

  String get _customerUserId => AppSession.userId;

  Future<void> loadCart() async {
    final customerUserId = _customerUserId;
    if (customerUserId.isEmpty) {
      _items.clear();
      emit(_buildLoadedState());
      return;
    }
    try {
      final items = await _cartService.getCart(customerUserId: customerUserId);
      _items
        ..clear()
        ..addAll(items);

      try {
        final calc = await _cartService.calculateCart(customerUserId: customerUserId);
        if (calc != null && calc.items.isNotEmpty) {
          final calcByProduct = {
            for (final c in calc.items) c.productId: c,
          };
          final merged = _items.map((item) {
            final calcItem = calcByProduct[item.product.id];
            if (calcItem != null) {
              return item.copyWith(
                originalLinePrice: calcItem.originalPrice,
                discountedLinePrice: calcItem.discountedPrice,
              );
            }
            return item;
          }).toList();
          _items
            ..clear()
            ..addAll(merged);
          emit(CartLoaded(
            items: List.from(_items),
            totalAmount: calc.totalPrice,
            totalDiscount: calc.totalDiscount,
            finalPrice: calc.finalPrice,
            totalItems: _items.fold(0, (s, i) => s + i.quantity),
          ));
          return;
        }
      } catch (_) {}

      emit(_buildLoadedState());
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<String?> addItem(ProductModel product) async {
    final customerUserId = _customerUserId;
    if (customerUserId.isEmpty) {
      const message = 'Sepete eklemek için giriş yapın.';
      emit(CartError(message));
      return message;
    }

    if (_hasItemsFromDifferentRestaurant(product)) {
      emit(CartError(differentRestaurantErrorMessage));
      return differentRestaurantErrorMessage;
    }

    try {
      await _cartService.addItem(
        customerUserId: customerUserId,
        productId: product.id,
        quantity: 1,
        weightKg: product.weight,
      );
      await loadCart();
      return null;
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(CartError(message));
      return message;
    }
  }

  Future<void> removeItem(String cartItemId) async {
    final customerUserId = _customerUserId;
    if (customerUserId.isEmpty) return;
    try {
      await _cartService.removeItem(
        customerUserId: customerUserId,
        cartItemId: cartItemId,
      );
      await loadCart();
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    final customerUserId = _customerUserId;
    if (customerUserId.isEmpty) return;
    try {
      await _cartService.updateItemQuantity(
        customerUserId: customerUserId,
        cartItemId: cartItemId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> incrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.cartItemId == cartItemId);
    if (index >= 0) {
      await updateQuantity(
        cartItemId,
        _items[index].quantity + 1,
      );
    }
  }

  Future<void> decrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.cartItemId == cartItemId);
    if (index >= 0) {
      final newQuantity = _items[index].quantity - 1;
      if (newQuantity <= 0) {
        await removeItem(cartItemId);
      } else {
        await updateQuantity(cartItemId, newQuantity);
      }
    }
  }

  Future<void> clearCart() async {
    final customerUserId = _customerUserId;
    if (customerUserId.isEmpty) {
      _items.clear();
      emit(_buildLoadedState());
      return;
    }
    try {
      await _cartService.clearCart(customerUserId: customerUserId);
      _items.clear();
      emit(_buildLoadedState());
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  CartLoaded _buildLoadedState() {
    final totalAmount = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalItems = _items.fold(0, (sum, item) => sum + item.quantity);

    return CartLoaded(
      items: List.from(_items),
      totalAmount: totalAmount,
      totalDiscount: 0,
      finalPrice: totalAmount,
      totalItems: totalItems,
    );
  }

  bool isProductInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  bool _hasItemsFromDifferentRestaurant(ProductModel product) {
    final targetRestaurantId = product.restaurantId?.trim();
    if (targetRestaurantId == null || targetRestaurantId.isEmpty) {
      return false;
    }

    for (final item in _items) {
      final cartRestaurantId = item.product.restaurantId?.trim();
      if (cartRestaurantId == null || cartRestaurantId.isEmpty) {
        continue;
      }
      if (cartRestaurantId.toLowerCase() != targetRestaurantId.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  String _extractErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '').trim();
    }
    return raw;
  }
}
