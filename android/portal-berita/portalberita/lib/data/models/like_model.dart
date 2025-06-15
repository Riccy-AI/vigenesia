class Like {
  final int id;
  final int articleId;
  final int userId;
  final String createdAt;

  Like({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: int.parse(json['id'].toString()),
      articleId: int.parse(json['article_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'user_id': userId,
      'created_at': createdAt,
    };
  }
}
