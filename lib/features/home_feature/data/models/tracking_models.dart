class CourierDetailsModel {
  const CourierDetailsModel({
    required this.courierUserId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phone,
    this.photoUrl,
  });

  final String courierUserId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final String? photoUrl;

  factory CourierDetailsModel.fromJson(Map<dynamic, dynamic> json) {
    return CourierDetailsModel(
      courierUserId: json['courierUserId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}

class LocationUpdateModel {
  const LocationUpdateModel({
    required this.orderId,
    required this.lat,
    required this.lng,
    this.bearing,
    this.timestampUtc,
    this.courier,
  });

  final String orderId;
  final double lat;
  final double lng;
  final double? bearing;
  final DateTime? timestampUtc;
  final CourierDetailsModel? courier;

  factory LocationUpdateModel.fromJson(Map<dynamic, dynamic> json) {
    return LocationUpdateModel(
      orderId: json['orderId']?.toString() ?? '',
      lat: _parseDouble(json['lat']) ?? 0,
      lng: _parseDouble(json['lng']) ?? 0,
      bearing: _parseDouble(json['bearing']),
      timestampUtc:
          DateTime.tryParse(json['timestampUtc']?.toString() ?? '')?.toLocal(),
      courier:
          json['courier'] is Map
              ? CourierDetailsModel.fromJson(json['courier'] as Map)
              : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class TrackingSnapshotModel {
  const TrackingSnapshotModel({
    required this.orderId,
    required this.items,
    required this.deliveryAddress,
    this.customerLat,
    this.customerLng,
    this.courierLat,
    this.courierLng,
    this.bearing,
    this.courierLocationUpdatedAtUtc,
    required this.isTrackingActive,
    this.courier,
  });

  final String orderId;
  final String items;
  final String deliveryAddress;
  final double? customerLat;
  final double? customerLng;
  final double? courierLat;
  final double? courierLng;
  final double? bearing;
  final DateTime? courierLocationUpdatedAtUtc;
  final bool isTrackingActive;
  final CourierDetailsModel? courier;

  factory TrackingSnapshotModel.fromJson(Map<String, dynamic> json) {
    return TrackingSnapshotModel(
      orderId: json['orderId']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      customerLat: _parseDouble(json['customerLat']),
      customerLng: _parseDouble(json['customerLng']),
      courierLat: _parseDouble(json['courierLat']),
      courierLng: _parseDouble(json['courierLng']),
      bearing: _parseDouble(json['bearing']),
      courierLocationUpdatedAtUtc:
          DateTime.tryParse(
            json['courierLocationUpdatedAtUtc']?.toString() ?? '',
          )?.toLocal(),
      isTrackingActive: json['isTrackingActive'] == true,
      courier:
          json['courier'] is Map<String, dynamic>
              ? CourierDetailsModel.fromJson(
                json['courier'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
