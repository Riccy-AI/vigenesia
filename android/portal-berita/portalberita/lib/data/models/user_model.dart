class UserModel {
  final int id;
  final String username;
  final String email;
  final String? role;
  final String? profilePicture;
  final String? createdAt;
  final String? refreshToken;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.profilePicture,
    this.createdAt,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      createdAt: json['created_at'] ?? '',
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'profile_picture': profilePicture,
        'created_at': createdAt,
        'refresh_token': refreshToken,
      };
}
