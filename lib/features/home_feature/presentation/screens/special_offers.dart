import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/campaigns_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/screens/category_products_screen.dart';

import '../../data/data_source/local/sample_data.dart';

class SpecialOffers extends StatefulWidget {
  const SpecialOffers({super.key});

  @override
  State<SpecialOffers> createState() => _SpecialOffersState();
}

class _SpecialOffersState extends State<SpecialOffers> {
  final CampaignsService _campaignsService = CampaignsService();
  List<CampaignModel> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      final campaigns = await _campaignsService.getActiveCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _campaigns = [];
          _loading = false;
        });
      }
    }
  }

  void _onCampaignTap(CampaignModel campaign) {
    if (campaign.targetType == 2 && campaign.targetCategoryName != null) {
      appPush(
        context,
        CategoryProductsScreen(categoryName: campaign.targetCategoryName!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTypography = context.theme.appTypography;
    final appColors = context.theme.appColors;

    return AppScaffold(
      appBar: GeneralAppBar(title: 'Özel Teklifler'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
              ? _buildFallbackBanners(context)
              : RefreshIndicator(
                  onRefresh: _loadCampaigns,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Dimens.largePadding),
                    itemCount: _campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = _campaigns[index];
                      return InkWell(
                        onTap: () => _onCampaignTap(campaign),
                        borderRadius:
                            BorderRadius.circular(Dimens.largePadding),
                        child: Container(
                          padding: const EdgeInsets.all(Dimens.largePadding),
                          decoration: BoxDecoration(
                            color: appColors.primary.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(Dimens.largePadding),
                            border: Border.all(
                              color: appColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimens.padding,
                                      vertical: Dimens.smallPadding,
                                    ),
                                    decoration: BoxDecoration(
                                      color: appColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      campaign.discountLabel,
                                      style: appTypography.labelMedium
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                  if (campaign.minCartAmount != null) ...[
                                    const SizedBox(width: Dimens.padding),
                                    Text(
                                      '${campaign.minCartAmount!.round()} ₺ üzeri',
                                      style: appTypography.bodySmall
                                          .copyWith(color: appColors.gray4),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: Dimens.padding),
                              Text(
                                campaign.name,
                                style: appTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (campaign.description != null &&
                                  campaign.description!.isNotEmpty) ...[
                                const SizedBox(height: Dimens.smallPadding),
                                Text(
                                  campaign.description!,
                                  style: appTypography.bodySmall
                                      .copyWith(color: appColors.gray4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (campaign.targetType == 2 &&
                                  campaign.targetCategoryName != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Dimens.padding,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Ürünlere git',
                                        style: appTypography.labelMedium
                                            .copyWith(color: appColors.primary),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color: appColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Dimens.largePadding),
                  ),
                ),
    );
  }

  Widget _buildFallbackBanners(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Dimens.largePadding),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(Dimens.largePadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.largePadding),
            child: Image.asset(banners[index]),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: Dimens.largePadding),
    );
  }
}
