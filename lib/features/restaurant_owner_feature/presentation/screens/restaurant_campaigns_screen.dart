import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_campaign_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_campaign_form_screen.dart';

class RestaurantCampaignsScreen extends StatefulWidget {
  const RestaurantCampaignsScreen({super.key});

  @override
  State<RestaurantCampaignsScreen> createState() =>
      _RestaurantCampaignsScreenState();
}

class _RestaurantCampaignsScreenState extends State<RestaurantCampaignsScreen> {
  final RestaurantCampaignService _service = RestaurantCampaignService();
  List<dynamic> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return AppScaffold(
      appBar: GeneralAppBar(
        title: 'Kampanyalarım',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const RestaurantCampaignFormScreen(),
                ),
              );
              if (result == true && mounted) _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _campaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 64, color: colors.gray4),
                          const SizedBox(height: Dimens.largePadding),
                          Text(
                            'Henüz kampanya yok',
                            style: typography.bodyLarge.copyWith(
                              color: colors.gray4,
                            ),
                          ),
                          const SizedBox(height: Dimens.padding),
                          FilledButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RestaurantCampaignFormScreen(),
                                ),
                              );
                              if (result == true && mounted) _load();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Kampanya Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dimens.largePadding),
                      itemCount: _campaigns.length,
                      itemBuilder: (context, index) {
                        final c =
                            _campaigns[index] as Map<String, dynamic>;
                        final status = c['status']?.toString() ?? 'Pending';
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: Dimens.largePadding,
                          ),
                          child: ListTile(
                            title: Text(c['name']?.toString() ?? ''),
                            subtitle: Text(
                              '${c['discountValue']} ${c['discountType'] == 1 ? '%' : '₺'} • $status',
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Sil'),
                                ),
                              ],
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  try {
                                    await _service.deleteCampaign(
                                      c['campaignId']?.toString() ?? '',
                                    );
                                    if (mounted) _load();
                                  } catch (_) {}
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
