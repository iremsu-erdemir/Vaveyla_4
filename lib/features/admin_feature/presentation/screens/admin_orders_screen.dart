import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/admin_feature/data/services/admin_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _orders = [];
  bool _loading = true;
  double _totalRevenue = 0;
  double _totalDiscount = 0;
  double _totalPlatformEarning = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _adminService.getOrders(take: 100);
      if (mounted) {
        double rev = 0;
        double disc = 0;
        double plat = 0;
        for (final o in list) {
          if (o is Map<String, dynamic>) {
            rev += _toDouble(o['total']) ?? 0;
            disc += _toDouble(o['totalDiscount']) ?? 0;
            plat += _toDouble(o['platformEarning']) ?? 0;
          }
        }
        setState(() {
          _orders = list;
          _totalRevenue = rev;
          _totalDiscount = disc;
          _totalPlatformEarning = plat;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return AppScaffold(
      appBar: GeneralAppBar(title: 'Sipariş ve Finans'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimens.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Toplam Ciro',
                            value: formatPrice(_totalRevenue),
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: Dimens.padding),
                        Expanded(
                          child: _StatCard(
                            title: 'Toplam İndirim',
                            value: formatPrice(_totalDiscount),
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.padding),
                    _StatCard(
                      title: 'Platform Kazancı',
                      value: formatPrice(_totalPlatformEarning),
                      color: colors.primary,
                    ),
                    const SizedBox(height: Dimens.extraLargePadding),
                    Text(
                      'Son Siparişler',
                      style: typography.titleMedium,
                    ),
                    const SizedBox(height: Dimens.padding),
                    ...List.generate(
                      _orders.length.clamp(0, 20),
                      (index) {
                        final o = _orders[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: Dimens.padding),
                          child: ListTile(
                            title: Text(o['items']?.toString() ?? ''),
                            subtitle: Text(
                              '${formatPrice(_toDouble(o['total']) ?? 0)} • İndirim: ${formatPrice(_toDouble(o['totalDiscount']) ?? 0)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.appTypography;

    return Container(
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimens.corners),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.labelMedium.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: typography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
