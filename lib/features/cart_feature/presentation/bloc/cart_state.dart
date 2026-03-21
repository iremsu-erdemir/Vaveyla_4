part of 'cart_cubit.dart';

@immutable
abstract class CartState {}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final double totalAmount;
  final double totalDiscount;
  final double finalPrice;
  final int totalItems;

  CartLoaded({
    required this.items,
    required this.totalAmount,
    this.totalDiscount = 0,
    double? finalPrice,
    required this.totalItems,
  }) : finalPrice = finalPrice ?? totalAmount;

  double get totalSavings => totalDiscount;

  CartLoaded copyWith({
    List<CartItemModel>? items,
    double? totalAmount,
    double? totalDiscount,
    double? finalPrice,
    int? totalItems,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      finalPrice: finalPrice ?? this.finalPrice,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

class CartError extends CartState {
  final String message;

  CartError(this.message);
}
