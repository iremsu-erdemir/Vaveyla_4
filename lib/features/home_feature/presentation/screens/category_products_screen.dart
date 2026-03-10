import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_rating_summary.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/bloc/cart_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/widgets/product_image_widget.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/dimens.dart';
import '../../../../core/widgets/app_icon_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/general_app_bar.dart';
import '../../../../core/widgets/shaded_container.dart';
import '../../data/services/products_service.dart';
import '../bloc/category_products_cubit.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  static const _closedRestaurantMessage =
      'Bu restoran şu anda hizmet verememektedir.';

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final appColors = context.theme.appColors;
    return BlocProvider(
      create: (_) =>
          CategoryProductsCubit(ProductsService())..loadProducts(categoryName),
      child: AppScaffold(
        appBar: GeneralAppBar(title: categoryName),
        body: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = state.products;
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: appColors.gray4),
                    const SizedBox(height: Dimens.largePadding),
                    Text(
                      'Bu kategoride henüz ürün yok',
                      style: context.theme.appTypography.bodyLarge.copyWith(
                        color: appColors.gray4,
                      ),
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(Dimens.largePadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Dimens.largePadding,
                crossAxisSpacing: Dimens.largePadding,
                mainAxisExtent: 220,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isRestaurantOpen = product.restaurantIsOpen;
                return InkWell(
                  onTap: () {
                    if (!isRestaurantOpen) {
                      context.showErrorMessage(_closedRestaurantMessage);
                      return;
                    }
                    appPush(context, ProductDetailsScreen(product: product));
                  },
                  borderRadius: BorderRadius.circular(Dimens.corners),
                  child: ShadedContainer(
                    child: Stack(
                      children: [
                        Column(
                          spacing: Dimens.padding,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(Dimens.padding),
                              child: SizedBox(
                                height: 100,
                                width: 200,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(Dimens.corners),
                                  child: _buildProductImage(
                                    context,
                                    product.imageUrl,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.padding,
                              ),
                              child: Column(
                                spacing: Dimens.smallPadding,
                                children: [
                                  Text(
                                    product.name,
                                    style: context.theme.appTypography.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppRatingSummary(
                                        rating: product.rate,
                                        reviewCount: product.reviewCount,
                                      ),
                                      Text(
                                        formatPrice(product.price),
                                        style: context.theme.appTypography
                                            .labelLarge
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: AppIconButton(
                                      iconPath: Assets.icons.shoppingCart,
                                      backgroundColor: appColors.primary,
                                      onPressed: () async {
                                        if (!isRestaurantOpen) {
                                          context.showErrorMessage(
                                            _closedRestaurantMessage,
                                          );
                                          return;
                                        }
                                        final errorMessage = await context
                                            .read<CartCubit>()
                                            .addItem(product);
                                        if (!context.mounted) return;
                                        if (errorMessage == null) {
                                          context.showSuccessMessage(
                                            '${product.name} sepete eklendi!',
                                          );
                                          return;
                                        }
                                        context.showErrorMessage(errorMessage);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isRestaurantOpen)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.grey.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        Positioned(
                          top: Dimens.padding,
                          right: Dimens.padding,
                          child: Visibility(
                            visible: !isRestaurantOpen,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.smallPadding,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(
                                  Dimens.smallCorners,
                                ),
                              ),
                              child: Text(
                                'Kapalı',
                                style: context.theme.appTypography.labelSmall
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
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

  Widget _buildProductImage(BuildContext context, String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(context),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(context),
      );
    }
    return buildProductImage(imageUrl, 200, 100);
  }

  Widget _placeholderImage(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }
}
