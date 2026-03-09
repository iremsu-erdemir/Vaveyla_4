import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_sweet_shop_app_ui/core/services/google_geocoding_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_location_cubit.dart'
    show CourierLocationCubit, CourierLocationState, CourierLocationStatus;
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_orders_cubit.dart';

class CourierTrackingScreen extends StatefulWidget {
  const CourierTrackingScreen({super.key, this.selectedOrder});

  final CourierOrderModel? selectedOrder;

  @override
  State<CourierTrackingScreen> createState() => _CourierTrackingScreenState();
}

class _CourierTrackingScreenState extends State<CourierTrackingScreen> {
  final MapController _mapController = MapController();
  final GoogleGeocodingService _geocodingService = GoogleGeocodingService();
  CourierOrderModel? _activeOrder;
  /// Adres metninden geocode edilen koordinatlar (order.id -> LatLng)
  final Map<String, LatLng> _geocodedAddresses = {};
  final Set<String> _geocodingInProgress = {};
  bool _followCourier = true;

  @override
  void initState() {
    super.initState();
    _activeOrder = widget.selectedOrder;
    if (_activeOrder != null) {
      context.read<CourierLocationCubit>().startTracking();
    } else {
      context.read<CourierLocationCubit>().getCurrentPosition();
    }
  }

  @override
  void dispose() {
    context.read<CourierLocationCubit>().stopTracking();
    super.dispose();
  }

  Future<void> _geocodeOrderAddress(CourierOrderModel order) async {
    if (order.customerAddress.trim().isEmpty ||
        order.customerLat != null ||
        _geocodedAddresses.containsKey(order.id) ||
        _geocodingInProgress.contains(order.id)) {
      return;
    }
    _geocodingInProgress.add(order.id);
    final result = await _geocodingService.geocodeAddress(order.customerAddress);
    _geocodingInProgress.remove(order.id);
    if (result != null && mounted) {
      setState(() {
        _geocodedAddresses[order.id] =
            LatLng(result.latitude, result.longitude);
      });
    }
  }

  LatLng? _getCustomerLatLng(CourierOrderModel order) {
    if (order.customerLat != null && order.customerLng != null) {
      return LatLng(order.customerLat!, order.customerLng!);
    }
    return _geocodedAddresses[order.id];
  }

  void _centerOnCourier() {
    final loc = context.read<CourierLocationCubit>().state;
    if (loc.latitude != null && loc.longitude != null) {
      _mapController.move(LatLng(loc.latitude!, loc.longitude!), 17);
      setState(() => _followCourier = true);
    }
  }

  LatLng get _centerPoint {
    final loc = context.read<CourierLocationCubit>().state;
    final order = _activeOrder;
    final dest = order != null ? _getCustomerLatLng(order) : null;
    if (dest != null) {
      if (loc.latitude != null && loc.longitude != null) {
        return LatLng(
          (loc.latitude! + dest.latitude) / 2,
          (loc.longitude! + dest.longitude) / 2,
        );
      }
      return dest;
    }
    if (loc.latitude != null && loc.longitude != null) {
      return LatLng(loc.latitude!, loc.longitude!);
    }
    return const LatLng(41.6757, 26.5548);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return BlocConsumer<CourierLocationCubit, CourierLocationState>(
        listener: (context, locState) {
          if (_followCourier &&
              locState.latitude != null &&
              locState.longitude != null) {
            _mapController.move(
              LatLng(locState.latitude!, locState.longitude!),
              _mapController.camera.zoom,
            );
          }
        },
        buildWhen: (prev, curr) =>
            prev.latitude != curr.latitude ||
            prev.longitude != curr.longitude ||
            prev.status != curr.status,
        builder: (context, locState) {
          return BlocBuilder<CourierOrdersCubit, List<CourierOrderModel>>(
            builder: (context, orders) {
              final activeOrders = _activeOrder != null
                  ? [_activeOrder!]
                  : orders
                      .where(
                        (o) =>
                            o.status == CourierOrderStatus.assigned ||
                            o.status == CourierOrderStatus.pickedUp ||
                            o.status == CourierOrderStatus.inTransit,
                      )
                      .toList();

              for (final order in activeOrders) {
                _geocodeOrderAddress(order);
              }

              return AppScaffold(
                appBar: GeneralAppBar(
                  title: 'Canlı Takip',
                  showBackIcon: widget.selectedOrder != null,
                ),
                padding: EdgeInsets.zero,
                body: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _centerPoint,
                        initialZoom: 15,
                        onMapReady: () {
                          final firstDest =
                              activeOrders.isNotEmpty
                                  ? _getCustomerLatLng(activeOrders.first)
                                  : null;
                          if (firstDest != null) {
                            _mapController.move(firstDest, 16);
                          }
                        },
                        onPositionChanged: (camera, hasGesture) {
                          if (hasGesture) {
                            setState(() => _followCourier = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName:
                              'com.sweet.shop.flutter_sweet_shop_app_ui',
                        ),
                        MarkerLayer(
                          markers: [
                            if (locState.latitude != null &&
                                locState.longitude != null)
                              Marker(
                                point: LatLng(
                                  locState.latitude!,
                                  locState.longitude!,
                                ),
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: colors.primary,
                                  size: 48,
                                ),
                              ),
                            for (final order in activeOrders)
                              if (_getCustomerLatLng(order) != null)
                                Marker(
                                  point: _getCustomerLatLng(order)!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: colors.error,
                                    size: 40,
                                  ),
                                ),
                            for (final order in activeOrders)
                              if (order.restaurantLat != null &&
                                  order.restaurantLng != null &&
                                  (order.customerLat != order.restaurantLat ||
                                      order.customerLng !=
                                          order.restaurantLng))
                                Marker(
                                  point: LatLng(
                                    order.restaurantLat!,
                                    order.restaurantLng!,
                                  ),
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.store,
                                    color: colors.secondary,
                                    size: 36,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: Dimens.largePadding,
                      bottom: 280,
                      child: Material(
                        color: colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _centerOnCourier,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.my_location,
                              color: colors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(Dimens.largePadding),
                        decoration: BoxDecoration(
                          color: colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: locState.status ==
                                              CourierLocationStatus.tracking
                                          ? colors.success.withValues(alpha: 0.2)
                                          : colors.gray.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      locState.status ==
                                              CourierLocationStatus.tracking
                                          ? Icons.gps_fixed
                                          : Icons.gps_not_fixed,
                                      color: locState.status ==
                                              CourierLocationStatus.tracking
                                          ? colors.success
                                          : colors.gray4,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: Dimens.largePadding),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          locState.status ==
                                                  CourierLocationStatus.tracking
                                              ? 'Canlı konum takibi aktif'
                                              : 'Konum yükleniyor...',
                                          style: typography.titleSmall
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (locState.latitude != null &&
                                            locState.longitude != null)
                                          Text(
                                            '${locState.latitude!.toStringAsFixed(5)}, ${locState.longitude!.toStringAsFixed(5)}',
                                            style: typography.bodySmall
                                                .copyWith(color: colors.gray4),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (locState.status !=
                                      CourierLocationStatus.tracking)
                                    TextButton.icon(
                                      onPressed: () {
                                        context
                                            .read<CourierLocationCubit>()
                                            .startTracking();
                                      },
                                      icon: const Icon(Icons.play_arrow, size: 20),
                                      label: const Text('Takibi Başlat'),
                                    ),
                                ],
                              ),
                              if (activeOrders.isNotEmpty) ...[
                                const SizedBox(height: Dimens.largePadding),
                                Text(
                                  'Teslimat Adresi',
                                  style: typography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: Dimens.padding),
                                ...activeOrders.map((order) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: Dimens.padding,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          Dimens.largePadding,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.primary
                                              .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(Dimens.corners),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.items,
                                              style: typography.titleSmall
                                                  .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: colors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    order.customerAddress,
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                          color: colors.gray4,
                                                        ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (order.customerPhone != null &&
                                                order.customerPhone!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 16,
                                                    color: colors.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    order.customerPhone!,
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                          color: colors.gray4,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
    );
  }
}
