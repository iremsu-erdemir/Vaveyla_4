import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';

import '../gen/assets.gen.dart';
import '../theme/dimens.dart';
import '../theme/theme.dart';
import 'app_bordered_icon_button.dart';

class GeneralAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GeneralAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackIcon = true,
    this.bottom,
    this.height,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackIcon;
  final PreferredSizeWidget? bottom;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return AppBar(
      centerTitle: true,
      actions: actions,
      title: Text(
        title,
        style: typography.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.12),
              colors.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading:
          showBackIcon
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.largePadding,
                ),
                child: AppBorderedIconButton(
                  iconPath: Assets.icons.arrowLeft,
                  onPressed: () {
                    appPop(context);
                  },
                ),
              )
              : null,
      leadingWidth: 90.0,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height ?? AppBar().preferredSize.height + 16.0);
}
