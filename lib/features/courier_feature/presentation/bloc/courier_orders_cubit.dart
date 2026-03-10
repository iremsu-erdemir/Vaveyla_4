import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/services/courier_service.dart';

class CourierOrdersCubit extends Cubit<List<CourierOrderModel>> {
  CourierOrdersCubit(this._service, this._courierUserId) : super(const []);

  final CourierService _service;
  final String _courierUserId;
  Timer? _pollTimer;

  Future<void> loadOrders() async {
    try {
      final loaded = await _service.getOrders(courierUserId: _courierUserId);
      final merged = _mergeWithCurrentState(loaded);
      emit(merged);
    } catch (_) {
      // Polling sırasında geçici ağ/API hatalarında UI'ı çökertmemek için
      // mevcut state korunur.
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadOrders();
    });
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
    await _acceptOrder(id);
  }

  Future<void> markInTransit(String id) async {
    await _updateStatus(id, CourierOrderStatus.inTransit);
  }

  Future<void> markDelivered(String id) async {
    await _updateStatus(id, CourierOrderStatus.delivered);
  }

  Future<void> _updateStatus(String id, CourierOrderStatus to) async {
    final updated = await _service.updateOrderStatus(
      courierUserId: _courierUserId,
      id: id,
      status: to,
    );
    emit(
      state.map((o) => o.id == id ? o.copyWith(status: updated.status) : o).toList(),
    );
  }

  Future<void> _acceptOrder(String id) async {
    try {
      await _service.acceptOrder(courierUserId: _courierUserId, id: id);
      emit(
        state
            .map((o) => o.id == id ? o.copyWith(status: CourierOrderStatus.pickedUp) : o)
            .toList(),
      );
    } catch (_) {
      rethrow;
    }
  }

  List<CourierOrderModel> getByStatus(CourierOrderStatus status) {
    return state.where((o) => o.status == status).toList();
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
