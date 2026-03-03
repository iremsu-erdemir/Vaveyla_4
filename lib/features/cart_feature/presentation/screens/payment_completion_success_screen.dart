import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/screens/home_screen.dart';

class PaymentCompletionSuccessScreen extends StatelessWidget {
  const PaymentCompletionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return AppScaffold(
      safeAreaBottom: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: appColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 70,
                color: appColors.success,
              ),
            ),
            const SizedBox(height: Dimens.largePadding),
            Text(
              context.tr('payment_success_title'),
              style: typography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.padding),
            Text(
              context.tr('payment_success_message'),
              style: typography.bodyMedium.copyWith(color: appColors.gray4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: Dimens.largePadding,
          right: Dimens.largePadding,
          bottom: Dimens.largePadding,
        ),
        child: AppButton(
          onPressed:
              () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              ),
          title: context.tr('done'),
          textStyle: typography.bodyLarge.copyWith(color: appColors.white),
          borderRadius: Dimens.corners,
          margin: EdgeInsets.zero,
        ),
      ),
    );
  }
}
