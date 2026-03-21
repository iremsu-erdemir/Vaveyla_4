import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/gen/assets.gen.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_orders_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_orders_tab_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_location_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/screens/courier_tracking_screen.dart';

class CourierOrdersScreen extends StatefulWidget {
  const CourierOrdersScreen({super.key});

  @override
  State<CourierOrdersScreen> createState() => _CourierOrdersScreenState();
}

class _CourierOrdersScreenState extends State<CourierOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      try {
        context.read<CourierOrdersTabCubit>().selectTab(_tabController.index);
      } catch (_) {}
    }
  }

  void _syncToTabCubit() {
    if (!mounted) return;
    try {
      final tabIndex = context.read<CourierOrdersTabCubit>().state;
      if (_tabController.index != tabIndex) {
        _tabController.animateTo(tabIndex);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncToTabCubit());
    return BlocListener<CourierOrdersTabCubit, int>(
      listener: (_, tabIndex) => _syncToTabCubit(),
      child: AppScaffold(
      appBar: GeneralAppBar(
        title: 'Teslimat Siparişleri',
        showBackIcon: false,
        actions: [
          IconButton(
            onPressed: () => context.read<CourierOrdersCubit>().loadOrders(),
            icon: Icon(Icons.refresh, color: colors.primary, size: 28),
            tooltip: 'Yenile',
          ),
          const SizedBox(width: Dimens.padding),
        ],
        height: AppBar().preferredSize.height + 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: BlocBuilder<CourierOrdersCubit, List<CourierOrderModel>>(
            builder: (context, orders) {
              final assigned = orders
                  .where((o) => o.status == CourierOrderStatus.assigned)
                  .length;
              final inTransit = orders
                  .where(
                    (o) =>
                        o.status == CourierOrderStatus.pickedUp ||
                        o.status == CourierOrderStatus.inTransit,
                  )
                  .length;
              final delivered = orders
                  .where((o) => o.status == CourierOrderStatus.delivered)
                  .length;
              return TabBar(
                controller: _tabController,
                dividerColor: colors.gray,
                labelColor: colors.primary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                unselectedLabelColor: colors.black,
                indicatorColor: colors.primary,
                tabs: [
                  Tab(child: _TabWithBadge(label: 'Bekleyen', count: assigned)),
                  Tab(child: _TabWithBadge(label: 'Yolda', count: inTransit)),
                  Tab(child: _TabWithBadge(label: 'Teslim', count: delivered)),
                ],
              );
            },
          ),
        ),
      ),
      body: BlocBuilder<CourierOrdersCubit, List<CourierOrderModel>>(
        builder: (context, orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: orders
                    .where((o) => o.status == CourierOrderStatus.assigned)
                    .toList(),
                status: CourierOrderStatus.assigned,
                tabController: _tabController,
              ),
              _OrdersList(
                orders: orders
                    .where(
                      (o) =>
                          o.status == CourierOrderStatus.pickedUp ||
                          o.status == CourierOrderStatus.inTransit,
                    )
                    .toList(),
                status: CourierOrderStatus.inTransit,
                tabController: _tabController,
              ),
              _OrdersList(
                orders: orders
                    .where((o) => o.status == CourierOrderStatus.delivered)
                    .toList(),
                status: CourierOrderStatus.delivered,
                tabController: _tabController,
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.theme.appColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.status,
    required this.tabController,
  });

  final List<CourierOrderModel> orders;
  final CourierOrderStatus status;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined, size: 64, color: colors.gray4),
            const SizedBox(height: Dimens.largePadding),
            Text(
              'Henüz sipariş yok',
              style: typography.bodyLarge.copyWith(color: colors.gray4),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Dimens.largePadding),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimens.largePadding),
      itemBuilder: (context, index) {
        final order = orders[index];
        final accent = _statusColor(order.status);
        return Container(
          padding: const EdgeInsets.all(Dimens.largePadding),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(Dimens.corners),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimens.corners),
                    child: order.imagePath.isNotEmpty
                        ? Image.network(
                            order.imagePath,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          )
                        : Assets.images.logo.image(
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: Dimens.largePadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.items,
                                style: typography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.padding,
                                vertical: Dimens.smallPadding,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formatPrice(order.total),
                                style: typography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimens.padding),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: colors.gray4),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.customerAddress,
                                style: typography.bodySmall.copyWith(
                                  color: colors.gray4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (order.status != CourierOrderStatus.delivered) ...[
                          const SizedBox(height: Dimens.padding),
                          Wrap(
                            spacing: Dimens.padding,
                            runSpacing: Dimens.padding,
                            children: _buildActionButtons(
                              context,
                              order,
                              order.status,
                              tabController,
                            ),
                          ),
                        ],
                        const SizedBox(height: Dimens.padding),
                        Row(
                          children: [
                            Text(
                              order.time,
                              style: typography.bodySmall.copyWith(
                                color: colors.gray4,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _statusText(order.status),
                              style: typography.labelSmall.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (order.restaurantEarning > 0 ||
                            order.totalDiscount > 0) ...[
                          const SizedBox(height: Dimens.padding),
                          Container(
                            padding: const EdgeInsets.all(Dimens.padding),
                            decoration: BoxDecoration(
                              color: colors.gray.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(Dimens.smallCorners),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hakediş Özeti',
                                  style: typography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.gray4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Müşteri Ödemesi:',
                                      style: typography.bodySmall,
                                    ),
                                    Text(
                                      formatPrice(order.customerPaidAmount),
                                      style: typography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.totalDiscount > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'İndirim:',
                                        style: typography.bodySmall,
                                      ),
                                      Text(
                                        formatPrice(order.totalDiscount),
                                        style: typography.bodySmall.copyWith(
                                          color: colors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Restoran Hakedişi:',
                                      style: typography.bodySmall,
                                    ),
                                    Text(
                                      formatPrice(order.restaurantEarning),
                                      style: typography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    CourierOrderModel order,
    CourierOrderStatus status,
    TabController tabController,
  ) {
    final colors = context.theme.appColors;
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.largePadding,
        vertical: Dimens.padding,
      ),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final cubit = context.read<CourierOrdersCubit>();

    if (status == CourierOrderStatus.assigned) {
      return [
        FilledButton(
          onPressed: () async {
            try {
              await cubit.markPickedUp(order.id);
              if (!context.mounted) return;
              tabController.animateTo(1);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sipariş #${order.id} kabul edildi')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sipariş kabul edilemedi: $e')),
              );
            }
          },
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(colors.success),
          ),
          child: const Text('Siparişi Kabul Et'),
        ),
        FilledButton.icon(
          onPressed: () async {
            try {
              await cubit.markPickedUp(order.id);
              if (!context.mounted) return;
              tabController.animateTo(1);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: cubit),
                      BlocProvider.value(
                        value: context.read<CourierLocationCubit>(),
                      ),
                    ],
                    child: CourierTrackingScreen(selectedOrder: order),
                  ),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sipariş kabul edilemedi: $e')),
              );
            }
          },
          icon: const Icon(Icons.map, size: 18),
          label: const Text('Haritada Git'),
          style: buttonStyle,
        ),
      ];
    }
    if (status == CourierOrderStatus.pickedUp) {
      return [
        FilledButton(
          onPressed: () async {
            try {
              await cubit.markInTransit(order.id);
              if (!context.mounted) return;
              tabController.animateTo(1);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sipariş #${order.id} yola çıktı')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Durum güncellenemedi: $e')),
              );
            }
          },
          style: buttonStyle,
          child: const Text('Yola Çıktım'),
        ),
      ];
    }
    if (status == CourierOrderStatus.inTransit) {
      return [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: cubit),
                    BlocProvider.value(
                      value: context.read<CourierLocationCubit>(),
                    ),
                  ],
                  child: CourierTrackingScreen(selectedOrder: order),
                ),
              ),
            );
          },
          icon: const Icon(Icons.map, size: 18),
          label: const Text('Canlı Takip'),
          style: buttonStyle,
        ),
        FilledButton(
          onPressed: () async {
            try {
              await cubit.markDelivered(order.id);
              if (!context.mounted) return;
              tabController.animateTo(2);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sipariş #${order.id} teslim edildi')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Teslim durumu kaydedilemedi: $e')),
              );
            }
          },
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(colors.success),
          ),
          child: const Text('Teslim Ettim'),
        ),
      ];
    }
    return [];
  }

  Color _statusColor(CourierOrderStatus s) {
    switch (s) {
      case CourierOrderStatus.assigned:
        return const Color(0xFFFFA726);
      case CourierOrderStatus.pickedUp:
        return const Color(0xFF42A5F5);
      case CourierOrderStatus.inTransit:
        return const Color(0xFF42A5F5);
      case CourierOrderStatus.delivered:
        return const Color(0xFF66BB6A);
    }
  }

  String _statusText(CourierOrderStatus s) {
    switch (s) {
      case CourierOrderStatus.assigned:
        return 'Bekliyor';
      case CourierOrderStatus.pickedUp:
        return 'Alındı';
      case CourierOrderStatus.inTransit:
        return 'Yolda';
      case CourierOrderStatus.delivered:
        return 'Teslim Edildi';
    }
  }
}
