import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

part 'courier_location_state.dart';

/// Kurye konumunu canlı takip için yönetir.
class CourierLocationCubit extends Cubit<CourierLocationState> {
  CourierLocationCubit() : super(const CourierLocationState());

  StreamSubscription<Position>? _positionSubscription;

  Future<void> startTracking() async {
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
        distanceFilter: 10,
      ),
    ).listen((position) {
      emit(state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        status: CourierLocationStatus.tracking,
      ));
    });
  }

  Future<void> getCurrentPosition() async {
    emit(state.copyWith(status: CourierLocationStatus.loading));
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
    emit(state.copyWith(status: CourierLocationStatus.idle));
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
