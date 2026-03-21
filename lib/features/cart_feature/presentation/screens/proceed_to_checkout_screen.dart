import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_divider.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_svg_viewer.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/bordered_container.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/user_address_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/bloc/cart_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/screens/change_address_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/screens/payment_methods_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/widgets/orders_list_for_checkout.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/widgets/payment_details_item.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/widgets/app_button.dart';

class ProceedToCheckoutScreen extends StatefulWidget {
  const ProceedToCheckoutScreen({super.key});

  @override
  State<ProceedToCheckoutScreen> createState() => _ProceedToCheckoutScreenState();
}

class _ProceedToCheckoutScreenState extends State<ProceedToCheckoutScreen> {
  String _deliveryAddress = 'Saraçlar Cd. Merkez, Edirne';

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final addresses = await UserAddressService().getAddresses(
        userId: AppSession.userId,
      );
      final selected = addresses.where((a) => a.isSelected).firstOrNull;
      if (selected != null && mounted) {
        setState(() {
          _deliveryAddress = selected.addressLine;
        });
      }
    } catch (_) {}
  }

  Future<void> _changeAddress() async {
    final newAddress = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ChangeAddressScreen(),
      ),
    );

    if (newAddress != null && newAddress.trim().isNotEmpty && mounted) {
      setState(() {
        _deliveryAddress = newAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTypography = context.theme.appTypography;
    final appColors = context.theme.appColors;
    return AppScaffold(
      appBar: GeneralAppBar(title: 'Ödemeye Geç'),
      body: SingleChildScrollView(
        child: Column(
          spacing: Dimens.largePadding,
          children: [
            SizedBox.shrink(),
            BorderedContainer(
              padding: EdgeInsets.symmetric(horizontal: Dimens.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Dimens.largePadding,
                    ),
                    child: Text(
                      'Ödeme detayları',
                      style: appTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppDivider(),
                  BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      final productTotal =
                          cartState is CartLoaded
                              ? cartState.finalPrice.round()
                              : 0;
                      const deliveryFee = 10;
                      final discount =
                          cartState is CartLoaded ? cartState.totalDiscount.round() : 0;
                      final total = productTotal + deliveryFee;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PaymentDetailsItem(
                            title: 'Ürün fiyatı',
                            subtitle: formatPrice(productTotal),
                          ),
                          PaymentDetailsItem(
                            title: 'Teslimat',
                            subtitle: formatPrice(deliveryFee),
                          ),
                          PaymentDetailsItem(
                            title: 'İndirim',
                            subtitle: formatPrice(discount),
                          ),
                          Text(
                            ' - - - - - - - -' * 10,
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                            style: TextStyle(color: appColors.gray2),
                          ),
                          PaymentDetailsItem(
                            title: 'Toplam tutar',
                            subtitle: formatPrice(total),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            BorderedContainer(
              padding: EdgeInsets.symmetric(horizontal: Dimens.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimens.padding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Teslimat adresi',
                          style: appTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        BorderedContainer(
                          borderColor: appColors.primary,
                          borderRadius: Dimens.smallCorners,
                          child: InkWell(
                            onTap: _changeAddress,
                            borderRadius: BorderRadius.circular(
                              Dimens.smallCorners,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(Dimens.padding),
                              child: Text(
                                'Adresi değiştir',
                                style: TextStyle(color: appColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Dimens.largePadding),
                  AppDivider(),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: Dimens.smallPadding,
                    ),
                    leading: AppSvgViewer(
                      Assets.icons.location,
                      color: appColors.primary,
                    ),
                    title: Text(
                      _deliveryAddress,
                      style: appTypography.titleSmall.copyWith(
                        color: appColors.gray4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş listesi',
                    style: appTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: Dimens.largePadding),
                  AppDivider(),
                  OrdersListForCheckout(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: Dimens.largePadding,
          right: Dimens.largePadding,
          bottom: Dimens.padding,
        ),
        child: AppButton(
          onPressed: () {
            appPush(
              context,
              PaymentMethodsScreen(deliveryAddress: _deliveryAddress),
            );
          },
          title: 'Ödemeye Devam Et',
          textStyle: appTypography.bodyLarge,
          borderRadius: Dimens.corners,
          margin: EdgeInsets.symmetric(vertical: Dimens.largePadding),
        ),
      ),
    );
  }
}
