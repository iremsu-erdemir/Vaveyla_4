import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/bloc/cart_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/customer_review_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/customer_review_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/products_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/all_products_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/widgets/product_image_widget.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/widgets/app_icon_buttons.dart';
import '../../../../core/widgets/shaded_container.dart';
import 'product_details_screen.dart';

class RestaurantProductsScreen extends StatelessWidget {
  const RestaurantProductsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String restaurantId;
  final String restaurantName;

  Future<void> _showRestaurantReviewSheet(BuildContext context) async {
    final userId = AppSession.userId;
    if (userId.isEmpty) {
      context.showErrorMessage('Yorum için giriş yapmalısınız.');
      return;
    }

    final service = CustomerReviewService();
    final commentController = TextEditingController();
    var rating = 5;
    var existingReviews = <CustomerReviewModel>[];
    try {
      final loaded = await service.getReviews(
        targetType: 'restaurant',
        targetId: restaurantId,
        restaurantId: restaurantId,
        page: 1,
        pageSize: 5,
      );
      existingReviews = loaded.items;
    } catch (_) {}

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: Dimens.largePadding,
            right: Dimens.largePadding,
            top: Dimens.largePadding,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + Dimens.largePadding,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restoranı Değerlendir',
                    style: context.theme.appTypography.titleMedium,
                  ),
                  const SizedBox(height: Dimens.padding),
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setSheetState(() => rating = star),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Yorumunuz'),
                  ),
                  if (existingReviews.isNotEmpty) ...[
                    const SizedBox(height: Dimens.padding),
                    Text(
                      'Mevcut Yorumlar',
                      style: context.theme.appTypography.titleSmall,
                    ),
                    const SizedBox(height: Dimens.smallPadding),
                    ...existingReviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Dimens.smallPadding),
                        child: Text(
                          '${review.customerName}: ${review.comment}',
                          style: context.theme.appTypography.bodySmall,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: Dimens.padding),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      title: 'Gönder',
                      margin: EdgeInsets.zero,
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) return;
                        try {
                          await service.createReview(
                            customerUserId: userId,
                            restaurantId: restaurantId,
                            targetType: 'restaurant',
                            targetId: restaurantId,
                            rating: rating,
                            comment: comment,
                            customerName: AppSession.fullName,
                          );
                          if (!context.mounted) return;
                          Navigator.of(sheetContext).pop();
                          context.showSuccessMessage('Restoran yorumu kaydedildi.');
                        } catch (error) {
                          if (!context.mounted) return;
                          context.showErrorMessage(error);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.theme.appColors;
    return BlocProvider(
      create: (_) => AllProductsCubit(ProductsService())
        ..loadProducts(restaurantId: restaurantId),
      child: AppScaffold(
        appBar: GeneralAppBar(
          title: restaurantName,
          actions: [
            IconButton(
              tooltip: 'Restoranı değerlendir',
              icon: const Icon(Icons.star_rate_rounded),
              onPressed: () => _showRestaurantReviewSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<AllProductsCubit, AllProductsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.products.isEmpty) {
              return const Center(child: Text('Bu restoranda ürün yok.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(Dimens.largePadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Dimens.largePadding,
                crossAxisSpacing: Dimens.largePadding,
                mainAxisExtent: 210,
              ),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return InkWell(
                  onTap: () => appPush(context, ProductDetailsScreen(product: product)),
                  borderRadius: BorderRadius.circular(Dimens.corners),
                  child: ShadedContainer(
                    child: Column(
                      spacing: Dimens.padding,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(Dimens.padding),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimens.corners),
                            child: buildProductImage(product.imageUrl, 200, 114),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimens.padding),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.theme.appTypography.titleSmall,
                                ),
                              ),
                              Text(
                                formatPrice(product.price),
                                style: context.theme.appTypography.labelLarge
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: AppIconButton(
                            iconPath: Assets.icons.shoppingCart,
                            backgroundColor: appColors.primary,
                            onPressed: () {
                              context.read<CartCubit>().addItem(product);
                              context.showSuccessMessage(
                                '${product.name} sepete eklendi!',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
