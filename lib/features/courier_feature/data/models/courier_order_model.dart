enum CourierOrderStatus {
  assigned,   // Atanmış - Teslim alınacak
  pickedUp,   // Alındı - Pastaneden alındı
  inTransit,  // Yolda - Müşteriye gidiliyor
  delivered,  // Teslim edildi
}

class CourierOrderModel {
  CourierOrderModel({
    required this.id,
    required this.time,
    required this.date,
    required this.imagePath,
    this.preparationMinutes,
    required this.items,
    required this.total,
    required this.status,
    required this.customerAddress,
    this.customerLat,
    this.customerLng,
    this.restaurantAddress,
    this.restaurantLat,
    this.restaurantLng,
    this.customerName,
    this.customerPhone,
  });

  final String id;
  final String time;
  final String date;
  final String imagePath;
  final int? preparationMinutes;
  final String items;
  final int total;
  final CourierOrderStatus status;
  final String customerAddress;
  final double? customerLat;
  final double? customerLng;
  final String? restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final String? customerName;
  final String? customerPhone;

  factory CourierOrderModel.fromJson(Map<String, dynamic> json) {
    return CourierOrderModel(
      id: json['id']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      preparationMinutes: _parseNullableInt(json['preparationMinutes']),
      items: json['items']?.toString() ?? '',
      total: _parseInt(json['total']),
      status: _parseStatus(json['status']),
      customerAddress: json['customerAddress']?.toString() ?? '',
      customerLat: _parseDouble(json['customerLat']),
      customerLng: _parseDouble(json['customerLng']),
      restaurantAddress: json['restaurantAddress']?.toString(),
      restaurantLat: _parseDouble(json['restaurantLat']),
      restaurantLng: _parseDouble(json['restaurantLng']),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
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
      'customerAddress': customerAddress,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'restaurantAddress': restaurantAddress,
      'restaurantLat': restaurantLat,
      'restaurantLng': restaurantLng,
      'customerName': customerName,
      'customerPhone': customerPhone,
    };
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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static CourierOrderStatus _parseStatus(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    switch (text) {
      case 'picked_up':
      case 'pickedup':
        return CourierOrderStatus.pickedUp;
      case 'in_transit':
      case 'intransit':
        return CourierOrderStatus.inTransit;
      case 'delivered':
        return CourierOrderStatus.delivered;
      default:
        return CourierOrderStatus.assigned;
    }
  }

  CourierOrderModel copyWith({
    String? id,
    String? time,
    String? date,
    String? imagePath,
    int? preparationMinutes,
    String? items,
    int? total,
    CourierOrderStatus? status,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    String? restaurantAddress,
    double? restaurantLat,
    double? restaurantLng,
    String? customerName,
    String? customerPhone,
  }) {
    return CourierOrderModel(
      id: id ?? this.id,
      time: time ?? this.time,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}
