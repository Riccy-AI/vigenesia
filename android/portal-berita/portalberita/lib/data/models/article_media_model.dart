class ArticleMedia {
  final int id;
  final int articleId;
  final String mediaType; // 'image' atau 'video'
  final String mediaUrl;
  final String createdAt;

  ArticleMedia({
    required this.id,
    required this.articleId,
    required this.mediaType,
    required this.mediaUrl,
    required this.createdAt,
  });

  factory ArticleMedia.fromJson(Map<String, dynamic> json) {
    return ArticleMedia(
      id: int.parse(json['id'].toString()),
      articleId: int.parse(json['article_id'].toString()),
      mediaType: json['media_type'],
      mediaUrl: json['media_url'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'created_at': createdAt,
    };
  }
}
