enum CustomerOrderStatus {
  pending,
  preparing,
  assigned,
  inTransit,
  completed,
  canceled,
}

class CustomerOrderModel {
  CustomerOrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
    required this.date,
    this.restaurantId = '',
    this.imagePath = '',
    this.preparationMinutes,
    this.customerLat,
    this.customerLng,
    this.courierLat,
    this.courierLng,
    this.courierLocationUpdatedAtUtc,
  });

  final String id;
  final String items;
  final int total;
  final CustomerOrderStatus status;
  final String time;
  final String date;
  final String restaurantId;
  final String imagePath;
  final int? preparationMinutes;
  final double? customerLat;
  final double? customerLng;
  final double? courierLat;
  final double? courierLng;
  final DateTime? courierLocationUpdatedAtUtc;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: json['id']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      total: _parseInt(json['total']),
      status: _parseStatus(json['status']?.toString()),
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      preparationMinutes: _parseNullableInt(json['preparationMinutes']),
      customerLat: _parseNullableDouble(json['customerLat']),
      customerLng: _parseNullableDouble(json['customerLng']),
      courierLat: _parseNullableDouble(json['courierLat']),
      courierLng: _parseNullableDouble(json['courierLng']),
      courierLocationUpdatedAtUtc:
          _parseNullableDateTime(json['courierLocationUpdatedAtUtc']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static CustomerOrderStatus _parseStatus(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'preparing':
        return CustomerOrderStatus.preparing;
      case 'assigned':
        return CustomerOrderStatus.assigned;
      case 'intransit':
      case 'in_transit':
        return CustomerOrderStatus.inTransit;
      case 'completed':
      case 'delivered':
        return CustomerOrderStatus.completed;
      case 'canceled':
      case 'cancelled':
      case 'rejected':
        return CustomerOrderStatus.canceled;
      default:
        return CustomerOrderStatus.pending;
    }
  }
}
