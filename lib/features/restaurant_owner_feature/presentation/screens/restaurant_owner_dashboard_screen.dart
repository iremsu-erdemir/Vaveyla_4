import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/gen/assets.gen.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_svg_viewer.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/bordered_container.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/notification_bell_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/shaded_container.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/models/menu_item_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/models/order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/bloc/restaurant_menu_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/bloc/restaurant_orders_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/bloc/restaurant_owner_nav_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/bloc/restaurant_settings_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/data/services/restaurant_owner_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_menu_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_orders_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_chats_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_reports_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_settings_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/presentation/screens/restaurant_owner_stat_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class RestaurantOwnerDashboardScreen extends StatelessWidget {
  const RestaurantOwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerUserId = AppSession.userId;
    final ownerService = RestaurantOwnerService(authService: AuthService());
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RestaurantOwnerNavCubit()),
        BlocProvider(
          create:
              (_) => RestaurantMenuCubit(ownerService, ownerUserId)..loadMenu(),
        ),
        BlocProvider(
          create:
              (_) =>
                  RestaurantOrdersCubit(ownerService, ownerUserId)
                    ..loadOrders()
                    ..startPolling(),
        ),
        BlocProvider(
          create:
              (_) =>
                  RestaurantSettingsCubit(ownerService, ownerUserId)
                    ..loadSettings(),
        ),
      ],
      child: const _RestaurantOwnerDashboardScreen(),
    );
  }
}

class _RestaurantOwnerDashboardScreen extends StatelessWidget {
  const _RestaurantOwnerDashboardScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return BlocBuilder<RestaurantOwnerNavCubit, int>(
      builder: (context, selectedIndex) {
        final cubit = context.read<RestaurantOwnerNavCubit>();
        final List<Widget> screens = [
          const _DashboardTab(),
          const RestaurantOwnerOrdersScreen(),
          const RestaurantOwnerMenuScreen(),
          const RestaurantOwnerChatsScreen(),
          const RestaurantOwnerSettingsScreen(),
        ];
        return AppScaffold(
          padding: EdgeInsets.zero,
          body: screens[selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: cubit.onItemTap,
              destinations: [
                NavigationDestination(
                  icon: AppSvgViewer(Assets.icons.home2),
                  selectedIcon: AppSvgViewer(
                    Assets.icons.home2,
                    color: colors.primary,
                  ),
                  label: 'Panel',
                ),
                NavigationDestination(
                  icon: AppSvgViewer(Assets.icons.receipt),
                  selectedIcon: AppSvgViewer(
                    Assets.icons.receipt,
                    color: colors.primary,
                  ),
                  label: 'Siparişler',
                ),
                NavigationDestination(
                  icon: AppSvgViewer(Assets.icons.menu),
                  selectedIcon: AppSvgViewer(
                    Assets.icons.menu,
                    color: colors.primary,
                  ),
                  label: 'Menü',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline, color: colors.gray4),
                  selectedIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: colors.primary,
                  ),
                  label: 'Sohbet',
                ),
                NavigationDestination(
                  icon: AppSvgViewer(Assets.icons.setting2),
                  selectedIcon: AppSvgViewer(
                    Assets.icons.setting2,
                    color: colors.primary,
                  ),
                  label: 'Ayarlar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return BlocBuilder<RestaurantOrdersCubit, List<RestaurantOrderModel>>(
      builder: (context, orders) {
        return BlocBuilder<RestaurantMenuCubit, List<MenuItemModel>>(
          builder: (context, menuItems) {
            final pending =
                orders
                    .where((o) => o.status == RestaurantOrderStatus.pending)
                    .length;
            final totalRevenue = orders
                .where((o) => o.status == RestaurantOrderStatus.completed)
                .fold<int>(0, (sum, o) => sum + o.total);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Dimens.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    title: 'Pastane Paneli',
                    subtitle: 'Hoş geldiniz! Bugünkü özetiniz',
                  ),
                  const SizedBox(height: Dimens.largePadding),
                  const _CampaignCarousel(),
                  const SizedBox(height: Dimens.extraLargePadding),
                  _StatsGrid(
                    stats: [
                      _StatItem(
                        icon: Assets.icons.bagTimer,
                        label: 'Bekleyen Sipariş',
                        value: '$pending',
                        color: colors.warning,
                        onTap:
                            () => _openStatDetails(
                              context,
                              StatDetailType.pendingOrders,
                            ),
                      ),
                      _StatItem(
                        icon: Assets.icons.receipt,
                        label: 'Sipariş',
                        value: '${orders.length}',
                        color: colors.primary,
                        onTap:
                            () => _openStatDetails(
                              context,
                              StatDetailType.todayOrders,
                            ),
                      ),
                      _StatItem(
                        icon: Assets.icons.moneyTick,
                        label: 'Toplam Gelir',
                        value: formatPrice(totalRevenue),
                        color: colors.success,
                        onTap:
                            () => _openStatDetails(
                              context,
                              StatDetailType.totalRevenue,
                            ),
                      ),
                      _StatItem(
                        icon: Assets.icons.people,
                        label: 'Menü Ürünü',
                        value: '${menuItems.length}',
                        color: colors.secondary,
                        onTap:
                            () => _openStatDetails(
                              context,
                              StatDetailType.menuItems,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimens.extraLargePadding),
                  _LiveStatusStrip(
                    pending: pending,
                    preparing:
                        orders
                            .where(
                              (o) =>
                                  o.status == RestaurantOrderStatus.preparing,
                            )
                            .length,
                    completed:
                        orders
                            .where(
                              (o) =>
                                  o.status == RestaurantOrderStatus.completed,
                            )
                            .length,
                  ),
                  const SizedBox(height: Dimens.extraLargePadding),
                  Text(
                    'Hızlı İşlemler',
                    style: typography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Dimens.largePadding),
                  _QuickOrderBanner(
                    onTap: () {
                      context.read<RestaurantOwnerNavCubit>().onItemTap(1);
                    },
                  ),
                  const SizedBox(height: Dimens.largePadding),
                  _QuickActionCard(
                    icon: Assets.icons.receiptAdd,
                    title: 'Yeni Sipariş',
                    subtitle: 'Manuel sipariş ekle',
                    onTap: () {
                      context.read<RestaurantOwnerNavCubit>().onItemTap(1);
                    },
                  ),
                  const SizedBox(height: Dimens.largePadding),
                  _QuickActionCard(
                    icon: Assets.icons.menu,
                    title: 'Menüyü Düzenle',
                    subtitle: 'Ürün ekle veya güncelle',
                    onTap: () {
                      context.read<RestaurantOwnerNavCubit>().onItemTap(2);
                    },
                  ),
                  const SizedBox(height: Dimens.largePadding),
                  _QuickActionCard(
                    icon: Assets.icons.chartSquare,
                    title: 'Raporlar',
                    subtitle: 'Satış ve performans raporları',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                    value:
                                        context.read<RestaurantOrdersCubit>(),
                                  ),
                                  BlocProvider.value(
                                    value: context.read<RestaurantMenuCubit>(),
                                  ),
                                ],
                                child: const RestaurantOwnerReportsScreen(),
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: Dimens.extraLargePadding),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openStatDetails(BuildContext context, StatDetailType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: context.read<RestaurantOrdersCubit>(),
                ),
                BlocProvider.value(value: context.read<RestaurantMenuCubit>()),
              ],
              child: RestaurantOwnerStatDetailsScreen(type: type),
            ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final childAspectRatio = width < 300 ? 1.2 : 1.4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: Dimens.largePadding,
          crossAxisSpacing: Dimens.largePadding,
          childAspectRatio: childAspectRatio,
          children: stats.map((s) => _StatCard(item: s)).toList(),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.appTypography;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(Dimens.corners),
        child: Container(
          padding: const EdgeInsets.all(Dimens.largePadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimens.corners),
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: 0.16),
                item.color.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: item.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppSvgViewer(item.icon, width: 22, color: item.color),
              ),
              const SizedBox(height: Dimens.padding),
              Text(
                item.value,
                style: typography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Dimens.smallPadding),
              Text(
                item.label,
                style: typography.bodySmall.copyWith(
                  color: context.theme.appColors.gray4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Container(
      padding: const EdgeInsets.all(Dimens.extraLargePadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.storefront, color: colors.primary),
          ),
          const SizedBox(width: Dimens.largePadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lobsterTwo(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: typography.bodyMedium.copyWith(color: colors.gray4),
                ),
              ],
            ),
          ),
          const NotificationBellButton(),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return BorderedContainer(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.corners),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.largePadding),
          child: Row(
            children: [
              ShadedContainer(
                width: 56,
                height: 56,
                borderRadius: Dimens.corners,
                child: Center(
                  child: AppSvgViewer(icon, width: 28, color: colors.primary),
                ),
              ),
              const SizedBox(width: Dimens.largePadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: typography.bodySmall.copyWith(color: colors.gray4),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSvgViewer(
                Assets.icons.arrowRight4,
                width: 20,
                color: colors.gray4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignCarousel extends StatelessWidget {
  const _CampaignCarousel();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CampaignCard(
            title: 'Hızlı Teslimat',
            subtitle: 'Ortalama teslimat 25 dk',
            color: colors.primary,
          ),
          const SizedBox(width: Dimens.largePadding),
          _CampaignCard(
            title: 'Öne Çıkan Ürünler',
            subtitle: 'Günün en çok satanları',
            color: colors.secondary,
          ),
          const SizedBox(width: Dimens.largePadding),
          _CampaignCard(
            title: 'Kampanya Zamanı',
            subtitle: 'Yeni indirimler ekleyin',
            color: colors.success,
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.appTypography;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: typography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(subtitle, style: typography.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _LiveStatusStrip extends StatelessWidget {
  const _LiveStatusStrip({
    required this.pending,
    required this.preparing,
    required this.completed,
  });

  final int pending;
  final int preparing;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Container(
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.gray.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatusPill(
            label: 'Bekleyen',
            value: pending,
            color: colors.warning,
            typography: typography,
          ),
          _StatusPill(
            label: 'Hazırlanan',
            value: preparing,
            color: colors.primary,
            typography: typography,
          ),
          _StatusPill(
            label: 'Tamamlanan',
            value: completed,
            color: colors.success,
            typography: typography,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.color,
    required this.typography,
  });

  final String label;
  final int value;
  final Color color;
  final dynamic typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.largePadding,
        vertical: Dimens.padding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: typography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: typography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOrderBanner extends StatelessWidget {
  const _QuickOrderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(Dimens.largePadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.18),
                colors.secondary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.flash_on, color: colors.primary),
              ),
              const SizedBox(width: Dimens.largePadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı Sipariş Al',
                      style: typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Yeni siparişleri hızla oluşturun',
                      style: typography.bodySmall.copyWith(color: colors.gray4),
                    ),
                  ],
                ),
              ),
              AppSvgViewer(
                Assets.icons.arrowRight4,
                width: 18,
                color: colors.gray4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
