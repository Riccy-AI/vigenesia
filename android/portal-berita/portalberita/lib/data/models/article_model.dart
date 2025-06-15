class Article {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final String username;
  final String? profilePicture; // Tambahkan ini

  Article({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    this.profilePicture, // opsional
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      username: json['username'] ?? '',
      profilePicture: json['profile_picture'], // ambil dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'username': username,
      'profile_picture': profilePicture, // sertakan juga di toJson
    };
  }
}
