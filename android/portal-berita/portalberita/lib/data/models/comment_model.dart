class Comment {
  final int id;
  final int articleId;
  final int userId;
  final String comment;
  final String createdAt;
  final String? username;
  final String? profilePicture;

  Comment({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.username,
    this.profilePicture,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['id'].toString()),
      articleId: int.parse(json['article_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      comment: json['comment'],
      createdAt: json['created_at'],
      username: json['username'], // Ambil username dari json jika ada
      profilePicture:
          json['profile_picture'], // Ambil profilePicture dari json jika ada
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'user_id': userId,
      'comment': comment,
      'created_at': createdAt,
      'username': username,
      'profile_picture': profilePicture,
    };
  }
}
