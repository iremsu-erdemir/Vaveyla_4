class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}
