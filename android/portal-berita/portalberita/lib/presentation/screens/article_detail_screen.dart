import 'package:flutter/material.dart';
import '../../data/models/article_model.dart';
import '../../data/models/user_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  final UserModel user;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Ganti dengan field gambar yang sesuai jika ada, misal: article.imageUrl atau article.mediaUrl
    String? imageUrl;
    if (article.toJson().containsKey('imageUrl')) {
      imageUrl = article.toJson()['imageUrl'];
    } else if (article.toJson().containsKey('media_url')) {
      imageUrl = article.toJson()['media_url'];
    } else {
      imageUrl = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Artikel'),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            article.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Oleh: ${user.username}',
            style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            article.content,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          // TODO: Tambahkan widget komentar, like, dsb di sini
        ],
      ),
    );
  }
}
