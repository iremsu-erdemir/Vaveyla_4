import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_sweet_shop_app_ui/core/services/google_geocoding_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/route_service.dart';
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
  final RouteService _routeService = RouteService();
  late final CourierLocationCubit _locationCubit;
  CourierOrderModel? _activeOrder;
  RouteResult? _routeResult;
  String? _lastRouteOrderId;

  /// Adres metninden geocode edilen koordinatlar (order.id -> LatLng)
  final Map<String, LatLng> _geocodedAddresses = {};
  final Set<String> _geocodingInProgress = {};
  bool _followCourier = true;

  bool _isValidLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  LatLng? _safeLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (_isValidLatLng(lat, lng)) return LatLng(lat, lng);
    // Bazı veri kaynaklarında lat/lng alanları yer değiştirmiş gelebilir.
    if (_isValidLatLng(lng, lat)) return LatLng(lng, lat);
    return null;
  }

  List<LatLng> _sanitizePolylinePoints(List<LatLng> points) {
    return points
        .where((p) => _isValidLatLng(p.latitude, p.longitude))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _locationCubit = context.read<CourierLocationCubit>();
    _activeOrder = widget.selectedOrder;
    if (_activeOrder != null) {
      _locationCubit.startTracking(orderId: _activeOrder!.id);
    } else {
      _locationCubit.startTracking();
    }
  }

  @override
  void dispose() {
    _locationCubit.stopTracking();
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
    final result = await _geocodingService.geocodeAddress(
      order.customerAddress,
    );
    _geocodingInProgress.remove(order.id);
    if (result != null && mounted) {
      final point = _safeLatLng(result.latitude, result.longitude);
      if (point == null) return;
      setState(() {
        _geocodedAddresses[order.id] = point;
      });
    }
  }

  LatLng? _getCustomerLatLng(CourierOrderModel order) {
    return _safeLatLng(order.customerLat, order.customerLng) ??
        _geocodedAddresses[order.id];
  }

  LatLng? _getRestaurantLatLng(CourierOrderModel order) {
    return _safeLatLng(order.restaurantLat, order.restaurantLng);
  }

  Future<void> _fetchRouteIfNeeded(
    List<CourierOrderModel> activeOrders,
    double? courierLat,
    double? courierLng,
  ) async {
    if (activeOrders.isEmpty) return;
    final order = activeOrders.first;
    final from = _getRestaurantLatLng(order);
    final to = _getCustomerLatLng(order);
    if (from == null || to == null) return;
    if (_lastRouteOrderId == order.id && _routeResult != null) return;
    _lastRouteOrderId = order.id;
    final courierPos = _safeLatLng(courierLat, courierLng);
    final result = await _routeService.getRoute(
      from: from,
      to: to,
      courierPosition: courierPos,
    );
    if (result != null && mounted) {
      setState(() => _routeResult = result);
    }
  }

  void _centerOnCourier() {
    final loc = context.read<CourierLocationCubit>().state;
    final courierPoint = _safeLatLng(loc.latitude, loc.longitude);
    if (courierPoint != null) {
      _mapController.move(courierPoint, 17);
      setState(() => _followCourier = true);
    }
  }

  LatLng get _centerPoint {
    final loc = context.read<CourierLocationCubit>().state;
    final order = _activeOrder;
    final dest = order != null ? _getCustomerLatLng(order) : null;
    final courierPoint = _safeLatLng(loc.latitude, loc.longitude);
    if (dest != null) {
      if (courierPoint != null) {
        return LatLng(
          (courierPoint.latitude + dest.latitude) / 2,
          (courierPoint.longitude + dest.longitude) / 2,
        );
      }
      return dest;
    }
    if (courierPoint != null) {
      return courierPoint;
    }
    return const LatLng(41.6757, 26.5548);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return BlocConsumer<CourierLocationCubit, CourierLocationState>(
      listener: (context, locState) {
        final courierPoint = _safeLatLng(locState.latitude, locState.longitude);
        if (_followCourier && courierPoint != null) {
          _mapController.move(
            courierPoint,
            _mapController.camera.zoom,
          );
        }
      },
      buildWhen:
          (prev, curr) =>
              prev.latitude != curr.latitude ||
              prev.longitude != curr.longitude ||
              prev.status != curr.status,
      builder: (context, locState) {
        return BlocBuilder<CourierOrdersCubit, List<CourierOrderModel>>(
          builder: (context, orders) {
            final activeOrders =
                _activeOrder != null
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchRouteIfNeeded(
                activeOrders,
                locState.latitude,
                locState.longitude,
              );
            });

            final routePoints = _sanitizePolylinePoints(
              _routeResult?.polylinePoints ?? const <LatLng>[],
            );
            double? remainingKm = _routeResult?.remainingDistanceKm;
            int? remainingMin = _routeResult?.remainingMinutes;
            final courierPoint = _safeLatLng(
              locState.latitude,
              locState.longitude,
            );
            if (activeOrders.isNotEmpty && courierPoint != null) {
              final order = activeOrders.first;
              final dest = _getCustomerLatLng(order);
              if (dest != null) {
                final avgSpeed =
                    (_routeResult?.totalDistanceKm != null &&
                            _routeResult?.totalDurationMinutes != null &&
                            _routeResult!.totalDurationMinutes! > 0)
                        ? _routeResult!.totalDistanceKm! /
                            _routeResult!.totalDurationMinutes!
                        : null;
                final (km, min) = RouteResult.computeRemaining(
                  courierLat: courierPoint.latitude,
                  courierLng: courierPoint.longitude,
                  destLat: dest.latitude,
                  destLng: dest.longitude,
                  avgSpeedKmPerMin: avgSpeed,
                );
                remainingKm = km;
                remainingMin = min;
              }
            }

            return AppScaffold(
              appBar: GeneralAppBar(
                title: 'Canlı Takip',
                showBackIcon: widget.selectedOrder != null,
              ),
              padding: EdgeInsets.zero,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
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
                        if (routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 5,
                                color: colors.error,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (locState.latitude != null &&
                                locState.longitude != null &&
                                _safeLatLng(
                                      locState.latitude,
                                      locState.longitude,
                                    ) !=
                                    null)
                              Marker(
                                point: _safeLatLng(
                                  locState.latitude,
                                  locState.longitude,
                                )!,
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
                                      order.customerLng != order.restaurantLng))
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
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
                          top: false,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            locState.status ==
                                                    CourierLocationStatus
                                                        .tracking
                                                ? colors.success.withValues(
                                                  alpha: 0.2,
                                                )
                                                : colors.gray.withValues(
                                                  alpha: 0.2,
                                                ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        locState.status ==
                                                CourierLocationStatus.tracking
                                            ? Icons.gps_fixed
                                            : Icons.gps_not_fixed,
                                        color:
                                            locState.status ==
                                                    CourierLocationStatus
                                                        .tracking
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
                                            _statusText(locState),
                                            style: typography.titleSmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (locState.message != null &&
                                              locState.message!
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              locState.message!,
                                              style: typography.bodySmall
                                                  .copyWith(
                                                    color: colors.error,
                                                  ),
                                            ),
                                          if (locState.latitude != null &&
                                              locState.longitude != null)
                                            Text(
                                              '${locState.latitude!.toStringAsFixed(5)}, ${locState.longitude!.toStringAsFixed(5)}',
                                              style: typography.bodySmall
                                                  .copyWith(
                                                    color: colors.gray4,
                                                  ),
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
                                              .startTracking(
                                                orderId: _activeOrder?.id,
                                              );
                                        },
                                        icon: const Icon(
                                          Icons.play_arrow,
                                          size: 20,
                                        ),
                                        label: const Text('Takibi Başlat'),
                                      ),
                                    if (locState.status ==
                                        CourierLocationStatus.tracking)
                                      TextButton.icon(
                                        onPressed: () {
                                          context
                                              .read<CourierLocationCubit>()
                                              .stopTracking();
                                        },
                                        icon: const Icon(Icons.stop, size: 20),
                                        label: const Text('Takibi Durdur'),
                                      ),
                                  ],
                                ),
                                if (activeOrders.isNotEmpty &&
                                    remainingKm != null &&
                                    remainingMin != null) ...[
                                  const SizedBox(height: Dimens.largePadding),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            Dimens.largePadding,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${remainingKm.toStringAsFixed(1)} km',
                                                style: typography.titleMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.primary,
                                                    ),
                                              ),
                                              Text(
                                                'Kalan mesafe',
                                                style: typography.bodySmall
                                                    .copyWith(
                                                      color: colors.gray4,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: Dimens.padding),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            Dimens.largePadding,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '~$remainingMin dk',
                                                style: typography.titleMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.primary,
                                                    ),
                                              ),
                                              Text(
                                                'Tahmini süre',
                                                style: typography.bodySmall
                                                    .copyWith(
                                                      color: colors.gray4,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Dimens.largePadding),
                                ],
                                if (activeOrders.isNotEmpty) ...[
                                  const SizedBox(height: Dimens.largePadding),
                                  Text(
                                    'Teslimat Adresi',
                                    style: typography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: Dimens.padding),
                                  ...activeOrders.map(
                                    (order) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: Dimens.padding,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          Dimens.largePadding,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            Dimens.corners,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.items,
                                              style: typography.titleSmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
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
                                                order
                                                    .customerPhone!
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
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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

  String _statusText(CourierLocationState state) {
    switch (state.status) {
      case CourierLocationStatus.tracking:
        return 'Canlı konum takibi aktif';
      case CourierLocationStatus.loading:
        return 'Konum alınıyor...';
      case CourierLocationStatus.denied:
        return 'Konum izni gerekli';
      case CourierLocationStatus.error:
        return 'Konum alınamadı';
      case CourierLocationStatus.success:
      case CourierLocationStatus.idle:
        return 'Takip beklemede';
    }
  }
}
