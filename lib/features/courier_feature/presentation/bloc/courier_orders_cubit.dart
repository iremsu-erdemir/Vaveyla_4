import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/services/courier_service.dart';

class CourierOrdersCubit extends Cubit<List<CourierOrderModel>> {
  CourierOrdersCubit(this._service, this._courierUserId) : super(const []);

  final CourierService _service;
  final String _courierUserId;

  Future<void> loadOrders() async {
    final loaded = await _service.getOrders(courierUserId: _courierUserId);
    final merged = _mergeWithCurrentState(loaded);
    emit(merged);
  }

  /// Yerel olarak güncellenmiş durumları korur. Yenile sonrası teslim edilen
  /// siparişlerin tekrar bekleyene düşmesini önler.
  List<CourierOrderModel> _mergeWithCurrentState(
    List<CourierOrderModel> loaded,
  ) {
    if (state.isEmpty) return loaded;
    final existingById = {for (final o in state) o.id: o};
    return loaded.map((loadedOrder) {
      final existing = existingById[loadedOrder.id];
      if (existing != null &&
          _statusOrder(existing.status) > _statusOrder(loadedOrder.status)) {
        return existing;
      }
      return loadedOrder;
    }).toList();
  }

  static int _statusOrder(CourierOrderStatus s) {
    switch (s) {
      case CourierOrderStatus.assigned:
        return 0;
      case CourierOrderStatus.pickedUp:
        return 1;
      case CourierOrderStatus.inTransit:
        return 2;
      case CourierOrderStatus.delivered:
        return 3;
    }
  }

  Future<void> markPickedUp(String id) async {
    await _updateStatus(id, CourierOrderStatus.pickedUp);
  }

  Future<void> markInTransit(String id) async {
    await _updateStatus(id, CourierOrderStatus.inTransit);
  }

  Future<void> markDelivered(String id) async {
    await _updateStatus(id, CourierOrderStatus.delivered);
  }

  Future<void> _updateStatus(String id, CourierOrderStatus to) async {
    try {
      final updated = await _service.updateOrderStatus(
        courierUserId: _courierUserId,
        id: id,
        status: to,
      );
      emit(state.map((o) => o.id == id ? updated : o).toList());
    } catch (_) {
      // Mock: local update when API fails
      emit(state.map((o) {
        if (o.id == id) return o.copyWith(status: to);
        return o;
      }).toList());
    }
  }

  List<CourierOrderModel> getByStatus(CourierOrderStatus status) {
    return state.where((o) => o.status == status).toList();
  }
}
