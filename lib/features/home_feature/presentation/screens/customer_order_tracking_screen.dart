import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/google_geocoding_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/route_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/tracking_realtime_service.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/customer_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/tracking_models.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/customer_orders_cubit.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  const CustomerOrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen> {
  final TrackingRealtimeService _trackingService = TrackingRealtimeService();
  final RouteService _routeService = RouteService();
  final GoogleGeocodingService _geocodingService = GoogleGeocodingService();
  final MapController _mapController = MapController();

  LatLng? _animatedCourierPoint;
  LatLng? _snapshotCustomerPoint;
  String? _snapshotDeliveryAddress;
  CourierDetailsModel? _courier;
  RouteResult? _routeResult;
  bool _trackingActive = false;
  bool _isReady = false;
  String? _lastRouteKey;
  Timer? _animationTimer;
  bool _isGeocodingAddress = false;

  bool _isValidLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  LatLng? _safeLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (_isValidLatLng(lat, lng)) return LatLng(lat, lng);
    // Bazı veri kaynaklarında değerler yer değiştirmiş gelebilir.
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
    _bootstrapRealtime();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _trackingService.unsubscribeOrder(widget.orderId);
    _trackingService.disconnect();
    super.dispose();
  }

  Future<void> _bootstrapRealtime() async {
    try {
      final snapshot = await _trackingService.getSnapshot(
        orderId: widget.orderId,
        customerUserId: AppSession.userId,
      );
      if (!mounted) return;
      if (snapshot != null) {
        setState(() {
          _trackingActive = snapshot.isTrackingActive;
          _courier = snapshot.courier;
          _snapshotDeliveryAddress = snapshot.deliveryAddress;
          _snapshotCustomerPoint = _safeLatLng(
            snapshot.customerLat,
            snapshot.customerLng,
          );
          _animatedCourierPoint = _safeLatLng(
            snapshot.courierLat,
            snapshot.courierLng,
          );
        });
      }

      await _trackingService.connect();
      await _trackingService.subscribeOrder(widget.orderId);
      _trackingService.onTrackingStatusChanged((isActive) {
        if (!mounted) return;
        setState(() => _trackingActive = isActive);
      });
      _trackingService.onLocationUpdated((update) {
        if (!mounted || update.orderId != widget.orderId) return;
        final next = _safeLatLng(update.lat, update.lng);
        if (next == null) return;
        _animateCourierTo(next);
        if (update.courier != null) {
          setState(() => _courier = update.courier);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }

  Future<void> _geocodeSnapshotAddressIfNeeded() async {
    if (_snapshotCustomerPoint != null ||
        _isGeocodingAddress ||
        _snapshotDeliveryAddress == null ||
        _snapshotDeliveryAddress!.trim().isEmpty) {
      return;
    }

    _isGeocodingAddress = true;
    final result = await _geocodingService.geocodeAddress(
      _snapshotDeliveryAddress!,
    );
    _isGeocodingAddress = false;
    if (!mounted || result == null) return;
    setState(() {
      _snapshotCustomerPoint = _safeLatLng(result.latitude, result.longitude);
    });
  }

  void _animateCourierTo(LatLng nextPoint) {
    final current = _animatedCourierPoint;
    if (current == null) {
      setState(() => _animatedCourierPoint = nextPoint);
      return;
    }

    _animationTimer?.cancel();
    const totalSteps = 12;
    var step = 0;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      step++;
      final t = step / totalSteps;
      final lat =
          current.latitude + (nextPoint.latitude - current.latitude) * t;
      final lng =
          current.longitude + (nextPoint.longitude - current.longitude) * t;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _animatedCourierPoint = LatLng(lat, lng));
      if (step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshRouteIfNeeded(LatLng? from, LatLng? to) async {
    if (from == null || to == null) return;
    final routeKey =
        '${from.latitude.toStringAsFixed(4)},${from.longitude.toStringAsFixed(4)}'
        '->${to.latitude.toStringAsFixed(4)},${to.longitude.toStringAsFixed(4)}';
    if (_lastRouteKey == routeKey) return;
    _lastRouteKey = routeKey;
    final route = await _routeService.getRoute(
      from: from,
      to: to,
      courierPosition: from,
    );
    if (!mounted || route == null) return;
    setState(() => _routeResult = route);
  }

  Future<void> _openCourierWhatsApp(String phone) async {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return;

    final waNumber =
        (digitsOnly.length == 11 && digitsOnly.startsWith('0'))
            ? '90${digitsOnly.substring(1)}'
            : digitsOnly;

    final uri = Uri.parse('https://wa.me/$waNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp açılamadı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return AppScaffold(
      appBar: const GeneralAppBar(title: 'Canlı Takip', showBackIcon: true),
      padding: EdgeInsets.zero,
      body: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
        builder: (context, state) {
          final order = _findOrder(state.orders, widget.orderId);
          if (order == null) {
            return const Center(child: Text('Sipariş bulunamadı.'));
          }

          final customerPoint = _customerPoint(order) ?? _snapshotCustomerPoint;
          final courierPoint = _animatedCourierPoint ?? _courierPoint(order);
          _refreshRouteIfNeeded(courierPoint, customerPoint);
          _geocodeSnapshotAddressIfNeeded();

          final routePoints = _sanitizePolylinePoints(
            _routeResult?.polylinePoints ?? const <LatLng>[],
          );
          double? remainingKm = _routeResult?.remainingDistanceKm;
          int? remainingMin = _routeResult?.remainingMinutes;
          if (courierPoint != null && customerPoint != null) {
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
              destLat: customerPoint.latitude,
              destLng: customerPoint.longitude,
              avgSpeedKmPerMin: avgSpeed,
            );
            remainingKm = km;
            remainingMin = min;
          }

          final initialCenter =
              courierPoint ?? customerPoint ?? const LatLng(41.6757, 26.5548);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.move(initialCenter, _mapController.camera.zoom);
          });

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15,
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
                        if (customerPoint != null)
                          Marker(
                            point: customerPoint,
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.home,
                              color: colors.error,
                              size: 34,
                            ),
                          ),
                        if (courierPoint != null)
                          Marker(
                            point: courierPoint,
                            width: 48,
                            height: 48,
                            child: Transform.rotate(
                              angle: _bearingFor(
                                courierPoint,
                                customerPoint ?? courierPoint,
                              ),
                              child: Icon(
                                Icons.motorcycle,
                                color: colors.primary,
                                size: 42,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
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
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (_trackingActive
                                          ? colors.success
                                          : colors.gray)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _trackingActive
                                      ? Icons.gps_fixed
                                      : Icons.gps_off,
                                  color:
                                      _trackingActive
                                          ? colors.success
                                          : colors.gray4,
                                ),
                              ),
                              const SizedBox(width: Dimens.largePadding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _trackingActive
                                          ? 'Canlı konum takibi aktif'
                                          : 'Kurye takibi bekleniyor',
                                      style: typography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      courierPoint == null
                                          ? (_isReady
                                              ? 'Konum verisi bekleniyor'
                                              : 'Bağlantı kuruluyor...')
                                          : '${courierPoint.latitude.toStringAsFixed(5)}, ${courierPoint.longitude.toStringAsFixed(5)}',
                                      style: typography.bodySmall.copyWith(
                                        color: colors.gray4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (remainingKm != null && remainingMin != null) ...[
                            const SizedBox(height: Dimens.largePadding),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    value:
                                        '${remainingKm.toStringAsFixed(1)} km',
                                    label: 'Kalan mesafe',
                                  ),
                                ),
                                const SizedBox(width: Dimens.padding),
                                Expanded(
                                  child: _MetricCard(
                                    value: '~$remainingMin dk',
                                    label: 'Tahmini süre',
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (customerPoint == null) ...[
                            const SizedBox(height: Dimens.largePadding),
                            Text(
                              'Teslimat konumu alınıyor, harita kurye konumuna göre güncelleniyor.',
                              style: typography.bodySmall.copyWith(
                                color: colors.gray4,
                              ),
                            ),
                          ],
                          const SizedBox(height: Dimens.largePadding),
                          Text(
                            'Ürün Detayları',
                            style: typography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: Dimens.padding),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Dimens.largePadding),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items,
                                  style: typography.bodyMedium,
                                ),
                                const SizedBox(height: Dimens.padding),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    order.time.isNotEmpty || order.date.isNotEmpty
                                        ? '${order.date} ${order.time}'
                                        : 'Sipariş bilgisi',
                                    style: typography.bodySmall.copyWith(
                                      color: colors.gray4,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_courier != null) ...[
                            const SizedBox(height: Dimens.largePadding),
                            _CourierProfileCard(
                              courier: _courier!,
                              onPhoneTap: () {
                                final phone = _courier?.phone?.trim();
                                if (phone == null || phone.isEmpty) return;
                                _openCourierWhatsApp(phone);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  CustomerOrderModel? _findOrder(List<CustomerOrderModel> orders, String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  LatLng? _customerPoint(CustomerOrderModel order) {
    return _safeLatLng(order.customerLat, order.customerLng);
  }

  LatLng? _courierPoint(CustomerOrderModel order) {
    return _safeLatLng(order.courierLat, order.courierLng);
  }

  double _bearingFor(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(to.latitude * math.pi / 180);
    final x =
        math.cos(from.latitude * math.pi / 180) *
            math.sin(to.latitude * math.pi / 180) -
        math.sin(from.latitude * math.pi / 180) *
            math.cos(to.latitude * math.pi / 180) *
            math.cos(dLng);
    return math.atan2(y, x);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Container(
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: typography.titleMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: typography.bodySmall.copyWith(color: colors.gray4),
          ),
        ],
      ),
    );
  }
}

class _CourierProfileCard extends StatelessWidget {
  const _CourierProfileCard({required this.courier, required this.onPhoneTap});

  final CourierDetailsModel courier;
  final VoidCallback onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    final hasPhone = courier.phone != null && courier.phone!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        color: colors.white,
        border: Border.all(color: colors.gray.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                courier.photoUrl != null && courier.photoUrl!.isNotEmpty
                    ? NetworkImage(courier.photoUrl!)
                    : null,
            child:
                courier.photoUrl == null || courier.photoUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
          ),
          const SizedBox(width: Dimens.largePadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier.fullName.isEmpty ? 'Kurye' : courier.fullName,
                  style: typography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  courier.phone ?? 'Telefon bilgisi mevcut değil',
                  style: typography.bodySmall.copyWith(color: colors.gray4),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: hasPhone ? onPhoneTap : null,
            icon: Icon(
              Icons.phone,
              color: hasPhone ? colors.primary : colors.gray4,
            ),
            tooltip:
                hasPhone
                    ? 'WhatsApp ile iletişime geç'
                    : 'Telefon bilgisi mevcut değil',
          ),
        ],
      ),
    );
  }
}
