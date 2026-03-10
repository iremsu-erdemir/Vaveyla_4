import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/customer_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/customer_orders_cubit.dart';

class CustomerOrderTrackingScreen extends StatelessWidget {
  const CustomerOrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return AppScaffold(
      appBar: const GeneralAppBar(
        title: 'Sipariş Takibi',
        showBackIcon: true,
      ),
      padding: EdgeInsets.zero,
      body: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
        builder: (context, state) {
          final order = _findOrder(state.orders, orderId);
          if (order == null) {
            return const Center(child: Text('Sipariş bulunamadı.'));
          }

          final customerPoint = _customerPoint(order);
          final courierPoint = _courierPoint(order);
          if (customerPoint == null) {
            return const Center(child: Text('Teslimat konumu henüz hazır değil.'));
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: courierPoint ?? customerPoint,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.sweet.shop.flutter_sweet_shop_app_ui',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: customerPoint,
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.home,
                          color: colors.error,
                          size: 36,
                        ),
                      ),
                      if (courierPoint != null)
                        Marker(
                          point: courierPoint,
                          width: 50,
                          height: 50,
                          child: Icon(
                            Icons.delivery_dining,
                            color: colors.primary,
                            size: 44,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusText(order.status),
                          style: context.theme.appTypography.titleSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          courierPoint == null
                              ? 'Kurye konumu bekleniyor...'
                              : 'Kurye konumu guncelleniyor.',
                          style: context.theme.appTypography.bodySmall,
                        ),
                        if (order.courierLocationUpdatedAtUtc != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Son guncelleme: ${order.courierLocationUpdatedAtUtc}',
                            style: context.theme.appTypography.bodySmall,
                          ),
                        ],
                      ],
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
    if (order.customerLat == null || order.customerLng == null) {
      return null;
    }
    return LatLng(order.customerLat!, order.customerLng!);
  }

  LatLng? _courierPoint(CustomerOrderModel order) {
    if (order.courierLat == null || order.courierLng == null) {
      return null;
    }
    return LatLng(order.courierLat!, order.courierLng!);
  }

  String _statusText(CustomerOrderStatus status) {
    switch (status) {
      case CustomerOrderStatus.pending:
        return 'Siparis bekliyor';
      case CustomerOrderStatus.preparing:
        return 'Siparis hazirlaniyor';
      case CustomerOrderStatus.assigned:
        return 'Kurye siparisi kabul etti';
      case CustomerOrderStatus.inTransit:
        return 'Siparis yolda';
      case CustomerOrderStatus.completed:
        return 'Siparis teslim edildi';
      case CustomerOrderStatus.canceled:
        return 'Siparis iptal edildi';
    }
  }
}
