enum RestaurantOrderStatus { pending, preparing, completed, rejected }

class RestaurantOrderModel {
  RestaurantOrderModel({
    required this.id,
    required this.time,
    required this.date,
    required this.imagePath,
    this.preparationMinutes,
    required this.items,
    required this.total,
    required this.status,
  });

  final String id;
  final String time;
  final String date;
  final String imagePath;
  final int? preparationMinutes;
  final String items;
  final int total;
  final RestaurantOrderStatus status;

  factory RestaurantOrderModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOrderModel(
      id: json['id']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      preparationMinutes: _parseNullableInt(json['preparationMinutes']),
      items: json['items']?.toString() ?? '',
      total: _parseInt(json['total']),
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'date': date,
      'imagePath': imagePath,
      'preparationMinutes': preparationMinutes,
      'items': items,
      'total': total,
      'status': status.name,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static RestaurantOrderStatus _parseStatus(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    switch (text) {
      case 'preparing':
        return RestaurantOrderStatus.preparing;
      case 'completed':
        return RestaurantOrderStatus.completed;
      case 'rejected':
        return RestaurantOrderStatus.rejected;
      default:
        return RestaurantOrderStatus.pending;
    }
  }

  RestaurantOrderModel copyWith({
    String? id,
    String? time,
    String? date,
    String? imagePath,
    int? preparationMinutes,
    String? items,
    int? total,
    RestaurantOrderStatus? status,
  }) {
    return RestaurantOrderModel(
      id: id ?? this.id,
      time: time ?? this.time,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }
}
