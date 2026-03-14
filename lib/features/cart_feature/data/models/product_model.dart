class ProductModel {
  final String id;
  final String name;
  final double price;
  final double weight;
  final double rate;
  final int reviewCount;
  final String imageUrl;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantPhotoPath;
  final String? restaurantType;
  final String? restaurantAddress;
  final String? restaurantPhone;
  final double? restaurantLat;
  final double? restaurantLng;
  final int? estimatedDeliveryMinutes;
  final bool restaurantIsOpen;
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.weight = 1.0,
    this.rate = 0.0,
    this.reviewCount = 0,
    required this.imageUrl,
    this.restaurantId,
    this.restaurantName,
    this.restaurantPhotoPath,
    this.restaurantType,
    this.restaurantAddress,
    this.restaurantPhone,
    this.restaurantLat,
    this.restaurantLng,
    this.estimatedDeliveryMinutes,
    this.restaurantIsOpen = true,
    this.categoryName,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    double? weight,
    double? rate,
    int? reviewCount,
    String? imageUrl,
    String? restaurantId,
    String? restaurantName,
    String? restaurantPhotoPath,
    String? restaurantType,
    String? restaurantAddress,
    String? restaurantPhone,
    double? restaurantLat,
    double? restaurantLng,
    int? estimatedDeliveryMinutes,
    bool? restaurantIsOpen,
    String? categoryName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      weight: weight ?? this.weight,
      rate: rate ?? this.rate,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantPhotoPath: restaurantPhotoPath ?? this.restaurantPhotoPath,
      restaurantType: restaurantType ?? this.restaurantType,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantPhone: restaurantPhone ?? this.restaurantPhone,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      restaurantIsOpen: restaurantIsOpen ?? this.restaurantIsOpen,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  factory ProductModel.fromApiJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] is int ? (json['price'] as int).toDouble() : double.tryParse(json['price']?.toString() ?? '') ?? 0),
      rate: _parseDouble(json['rating']) ?? 0,
      reviewCount: _parseInt(json['reviewCount']),
      imageUrl: json['imagePath']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString(),
      restaurantName: json['restaurantName']?.toString(),
      restaurantPhotoPath: json['restaurantPhotoPath']?.toString(),
      restaurantType: json['restaurantType']?.toString(),
      restaurantAddress: json['restaurantAddress']?.toString(),
      restaurantPhone: json['restaurantPhone']?.toString(),
      restaurantLat: _parseDouble(json['restaurantLat']),
      restaurantLng: _parseDouble(json['restaurantLng']),
      estimatedDeliveryMinutes: _parseIntNullable(json['estimatedDeliveryMinutes']),
      restaurantIsOpen:
          json['restaurantIsOpen'] == true || json['restaurantIsOpen'] == 1,
      categoryName: json['categoryName']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
