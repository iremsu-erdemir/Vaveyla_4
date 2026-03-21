import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_bordered_icon_button.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/dimens.dart';

class ProductDetailsAppBar extends StatelessWidget {
  const ProductDetailsAppBar({
    super.key,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.largePadding),
        child: AppBorderedIconButton(
          iconPath: Assets.icons.arrowLeft,
          color: Colors.white,
          onPressed: () {
            appPop(context);
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.largePadding),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(100),
            ),
            child: IconButton(
              onPressed: onFavoriteTap,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      leadingWidth: 90.0,
    );
  }
}
