class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.photoUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String? photoUrl;

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? photoUrl,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}
