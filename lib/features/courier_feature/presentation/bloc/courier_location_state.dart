part of 'courier_location_cubit.dart';

enum CourierLocationStatus {
  idle,
  loading,
  success,
  tracking,
  denied,
  error,
}

class CourierLocationState {
  const CourierLocationState({
    this.status = CourierLocationStatus.idle,
    this.latitude,
    this.longitude,
    this.message,
  });

  final CourierLocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;

  CourierLocationState copyWith({
    CourierLocationStatus? status,
    double? latitude,
    double? longitude,
    String? message,
  }) {
    return CourierLocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      message: message ?? this.message,
    );
  }
}
