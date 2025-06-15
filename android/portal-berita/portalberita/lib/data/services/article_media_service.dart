import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_media_model.dart';

class ArticleMediaService {
  static const String _baseUrl = "http://10.0.2.2:8080/api/media";

  // Ambil media by article id
  Future<List<ArticleMedia>> fetchMediaByArticle(
      int articleId, String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/$articleId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Perbaiki di sini:
      final List data = decoded is List ? decoded : (decoded['data'] ?? []);
      return data.map((json) => ArticleMedia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load article media');
    }
  }

  // Upload media (image)
  Future<bool> addMedia(Map<String, dynamic> mediaData, String token) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/create"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(mediaData),
    );
    return response.statusCode == 201;
  }
}
