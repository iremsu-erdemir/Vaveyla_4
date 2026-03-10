import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/services/courier_service.dart';

part 'courier_location_state.dart';

/// Kurye konumunu canlı takip için yönetir.
class CourierLocationCubit extends Cubit<CourierLocationState> {
  CourierLocationCubit({
    required CourierService courierService,
    required String courierUserId,
  }) : _courierService = courierService,
       _courierUserId = courierUserId,
       super(const CourierLocationState());

  StreamSubscription<Position>? _positionSubscription;
  final CourierService _courierService;
  final String _courierUserId;
  String? _activeOrderId;
  DateTime? _lastSyncAtUtc;

  Future<void> startTracking({String? orderId}) async {
    _activeOrderId = orderId;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(state.copyWith(
        status: CourierLocationStatus.error,
        message: 'Konum servisleri kapalı.',
      ));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      emit(state.copyWith(
        status: CourierLocationStatus.denied,
        message: 'Konum izni gerekli.',
      ));
      return;
    }

    emit(state.copyWith(status: CourierLocationStatus.tracking));

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) async {
      emit(state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        status: CourierLocationStatus.tracking,
      ));
      await _syncLocationIfNeeded(position);
    });
  }

  Future<void> getCurrentPosition() async {
    emit(state.copyWith(status: CourierLocationStatus.loading));
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      emit(state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        status: CourierLocationStatus.success,
      ));
    } catch (e) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        emit(state.copyWith(
          latitude: last.latitude,
          longitude: last.longitude,
          status: CourierLocationStatus.success,
        ));
      } else {
        emit(state.copyWith(
          status: CourierLocationStatus.error,
          message: 'Konum alınamadı.',
        ));
      }
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeOrderId = null;
    _lastSyncAtUtc = null;
    emit(state.copyWith(status: CourierLocationStatus.idle));
  }

  Future<void> _syncLocationIfNeeded(Position position) async {
    final orderId = _activeOrderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    if (_lastSyncAtUtc != null &&
        now.difference(_lastSyncAtUtc!).inSeconds < 3) {
      return;
    }

    _lastSyncAtUtc = now;
    await _courierService.updateCourierLocation(
      courierUserId: _courierUserId,
      orderId: orderId,
      lat: position.latitude,
      lng: position.longitude,
      timestampUtc: now,
    );
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
