class UserAddress {
  const UserAddress({
    required this.addressId,
    required this.label,
    required this.addressLine,
    required this.isSelected,
    required this.createdAtUtc,
    this.addressDetail,
  });

  final String addressId;
  final String label;
  final String addressLine;
  final String? addressDetail;
  final bool isSelected;
  final DateTime createdAtUtc;

  UserAddress copyWith({
    String? addressId,
    String? label,
    String? addressLine,
    String? addressDetail,
    bool? isSelected,
    DateTime? createdAtUtc,
  }) {
    return UserAddress(
      addressId: addressId ?? this.addressId,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      addressDetail: addressDetail ?? this.addressDetail,
      isSelected: isSelected ?? this.isSelected,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      addressId: json['addressId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      addressDetail: json['addressDetail']?.toString(),
      isSelected: json['isSelected'] as bool? ?? false,
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
