class RestaurantChatMessageModel {
  RestaurantChatMessageModel({
    required this.id,
    required this.restaurantId,
    required this.customerUserId,
    required this.senderUserId,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.createdAtUtc,
  });

  final String id;
  final String restaurantId;
  final String customerUserId;
  final String senderUserId;
  final String senderType;
  final String senderName;
  final String message;
  final DateTime createdAtUtc;

  bool get isCustomer => senderType.toLowerCase() == 'customer';

  factory RestaurantChatMessageModel.fromJson(Map<String, dynamic> json) {
    return RestaurantChatMessageModel(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      customerUserId: json['customerUserId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? 'customer',
      senderName: json['senderName']?.toString() ?? 'Kullanıcı',
      message: json['message']?.toString() ?? '',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
